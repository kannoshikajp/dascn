package joppe.backend.domain.order.vnpay;

import jakarta.servlet.http.HttpServletRequest;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.UUID;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.order.Payment;
import joppe.backend.domain.order.PaymentRepository;
import joppe.backend.domain.order.vnpay.dto.CreateVnPayPaymentRequest;
import joppe.backend.domain.order.vnpay.dto.VnPayIpnResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayPaymentResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayReturnResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class VnPayService {

    private final VnPayProperties properties;
    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;

    @Transactional
    public VnPayPaymentResponse createPaymentUrl(CreateVnPayPaymentRequest request, HttpServletRequest httpRequest) {
        Order order = orderRepository.findById(request.orderId())
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + request.orderId()));

        if ("PAID".equalsIgnoreCase(order.getPaymentStatus())) {
            throw new IllegalStateException("Order is already paid: " + order.getOrderCode());
        }
        if ("CANCELLED".equalsIgnoreCase(order.getOrderStatus())) {
            throw new IllegalStateException("Order is cancelled: " + order.getOrderCode());
        }

        long amountInCents = order.getFinalAmount().multiply(BigDecimal.valueOf(100)).longValue();
        String txnRef = order.getOrderCode() + "_" + (System.currentTimeMillis() % 1000000);

        // Record a PENDING payment record
        Payment payment = Payment.builder()
                .orderId(order.getId())
                .paymentMethod("VNPAY")
                .paymentGateway("VNPAY")
                .transactionCode(txnRef)
                .amount(order.getFinalAmount())
                .status("PENDING")
                .build();
        payment = paymentRepository.save(payment);

        // Timezone GMT+7
        Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        formatter.setTimeZone(TimeZone.getTimeZone("Asia/Ho_Chi_Minh"));
        String createDate = formatter.format(cld.getTime());
        cld.add(Calendar.MINUTE, 15);
        String expireDate = formatter.format(cld.getTime());

        String clientIp = VnPayUtil.getClientIp(httpRequest);
        String returnUrl = (request.returnUrl() != null && !request.returnUrl().isBlank())
                ? request.returnUrl().trim()
                : properties.getReturnUrl();

        Map<String, String> vnpParams = new HashMap<>();
        vnpParams.put("vnp_Version", properties.getVersion());
        vnpParams.put("vnp_Command", properties.getCommand());
        vnpParams.put("vnp_TmnCode", properties.getTmnCode());
        vnpParams.put("vnp_Amount", String.valueOf(amountInCents));
        vnpParams.put("vnp_CurrCode", properties.getCurrCode());
        vnpParams.put("vnp_TxnRef", txnRef);
        vnpParams.put("vnp_OrderInfo", "Thanh_toan_don_hang_" + order.getOrderCode());
        vnpParams.put("vnp_OrderType", "other");
        vnpParams.put("vnp_Locale", "vn");
        vnpParams.put("vnp_ReturnUrl", returnUrl);
        vnpParams.put("vnp_IpAddr", clientIp);
        vnpParams.put("vnp_CreateDate", createDate);
        vnpParams.put("vnp_ExpireDate", expireDate);

        if (request.bankCode() != null && !request.bankCode().isBlank()) {
            vnpParams.put("vnp_BankCode", request.bankCode().trim());
        }

        // Sort keys and construct query & hash data
        List<String> fieldNames = new ArrayList<>(vnpParams.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();

        for (String fieldName : fieldNames) {
            String fieldValue = vnpParams.get(fieldName);
            if (fieldValue != null && !fieldValue.isEmpty()) {
                if (!hashData.isEmpty()) {
                    hashData.append('&');
                    query.append('&');
                }
                hashData.append(fieldName).append('=').append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII));
                query.append(URLEncoder.encode(fieldName, StandardCharsets.US_ASCII))
                        .append('=').append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII));
            }
        }

        String secureHash = VnPayUtil.hmacSHA512(properties.getHashSecret(), hashData.toString());
        String paymentUrl = properties.getPayUrl() + "?" + query + "&vnp_SecureHash=" + secureHash;

        log.info("Generated VNPay payment URL for order {} (txnRef: {}): {}", order.getOrderCode(), txnRef, paymentUrl);

        String qrCodeBase64 = QrCodeGenerator.generateQrCodeDataUri(paymentUrl, 320, 320);
        String qrCodeUrl = "/api/v1/payment/vnpay/qr?paymentUrl=" + URLEncoder.encode(paymentUrl, StandardCharsets.UTF_8);

        return new VnPayPaymentResponse(
                payment.getId(),
                paymentUrl,
                order.getOrderCode(),
                txnRef,
                order.getFinalAmount(),
                qrCodeUrl,
                qrCodeBase64
        );
    }

    /**
     * Generates raw PNG bytes of the QR code for a given payment URL or payment record.
     */
    public byte[] generateQrCodeImage(String paymentUrl, UUID paymentId, int size) {
        String targetText = paymentUrl;
        if ((targetText == null || targetText.isBlank()) && paymentId != null) {
            Payment payment = paymentRepository.findById(paymentId)
                    .orElseThrow(() -> new IllegalArgumentException("Payment record not found with ID: " + paymentId));
            targetText = properties.getPayUrl() + "?vnp_TxnRef=" + payment.getTransactionCode();
        }
        if (targetText == null || targetText.isBlank()) {
            throw new IllegalArgumentException("Either paymentUrl or valid paymentId must be provided");
        }
        int dimension = size > 0 && size <= 1000 ? size : 300;
        return QrCodeGenerator.generateQrCodePng(targetText, dimension, dimension);
    }

    /**
     * IPN Webhook from VNPay server to record background confirmation.
     */
    @Transactional
    public VnPayIpnResponse processIpn(Map<String, String> queryParams) {
        log.info("Received VNPay IPN request: {}", queryParams);

        // 1. Verify Checksum
        String secureHash = queryParams.get("vnp_SecureHash");
        if (secureHash == null || secureHash.isBlank()) {
            log.warn("VNPay IPN missing secure hash");
            return VnPayIpnResponse.invalidChecksum();
        }

        Map<String, String> fields = new HashMap<>(queryParams);
        fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        String calculatedHash = VnPayUtil.hashAllFields(fields, properties.getHashSecret());
        if (!calculatedHash.equalsIgnoreCase(secureHash)) {
            log.warn("VNPay IPN checksum failed. Expected: {}, got: {}", calculatedHash, secureHash);
            return VnPayIpnResponse.invalidChecksum();
        }

        // 2. Find Order & Payment
        String txnRef = queryParams.get("vnp_TxnRef");
        if (txnRef == null || txnRef.isBlank()) {
            return VnPayIpnResponse.orderNotFound();
        }

        Payment payment = paymentRepository.findByTransactionCode(txnRef).orElse(null);
        Order order = null;
        if (payment != null) {
            order = orderRepository.findById(payment.getOrderId()).orElse(null);
        } else {
            // Fallback: check by order code directly or stripped txnRef
            order = orderRepository.findByOrderCode(txnRef).orElse(null);
            if (order == null && txnRef.contains("_")) {
                String baseCode = txnRef.substring(0, txnRef.lastIndexOf('_'));
                order = orderRepository.findByOrderCode(baseCode).orElse(null);
            }
        }

        if (order == null) {
            log.warn("Order not found for VNPay IPN txnRef: {}", txnRef);
            return VnPayIpnResponse.orderNotFound();
        }

        // 3. Check Amount
        String amountStr = queryParams.get("vnp_Amount");
        if (amountStr == null) {
            return VnPayIpnResponse.invalidAmount();
        }
        try {
            long vnpAmount = Long.parseLong(amountStr);
            long expectedAmount = order.getFinalAmount().multiply(BigDecimal.valueOf(100)).longValue();
            if (vnpAmount != expectedAmount) {
                log.warn("VNPay IPN invalid amount for order {}. Expected: {}, received: {}", order.getOrderCode(), expectedAmount, vnpAmount);
                return VnPayIpnResponse.invalidAmount();
            }
        } catch (NumberFormatException e) {
            return VnPayIpnResponse.invalidAmount();
        }

        // 4. Check Order status
        if ("PAID".equalsIgnoreCase(order.getPaymentStatus())) {
            log.info("Order {} already confirmed paid", order.getOrderCode());
            return VnPayIpnResponse.orderAlreadyConfirmed();
        }

        // 5. Update Status
        String responseCode = queryParams.get("vnp_ResponseCode");
        String transactionStatus = queryParams.get("vnp_TransactionStatus");
        boolean isSuccess = "00".equals(responseCode) && ("00".equals(transactionStatus) || transactionStatus == null);

        if (isSuccess) {
            log.info("VNPay payment successful for order {}. Updating status to PAID.", order.getOrderCode());
            orderRepository.updatePaymentStatus(order.getId(), "PAID");
            if ("PENDING".equalsIgnoreCase(order.getOrderStatus())) {
                orderRepository.updateOrderStatus(order.getId(), "ACCEPTED");
            }
            if (payment != null) {
                paymentRepository.updatePaymentResult(payment.getId(), "COMPLETED", queryParams.toString(), OffsetDateTime.now());
            }
        } else {
            log.warn("VNPay payment failed for order {} with code: {}", order.getOrderCode(), responseCode);
            if (payment != null) {
                paymentRepository.updatePaymentResult(payment.getId(), "FAILED", queryParams.toString(), null);
            }
        }

        return VnPayIpnResponse.success();
    }

    /**
     * Process browser return redirect from VNPay.
     */
    @Transactional
    public VnPayReturnResult processReturn(Map<String, String> queryParams) {
        log.info("Processing VNPay browser return: {}", queryParams);

        String secureHash = queryParams.get("vnp_SecureHash");
        Map<String, String> fields = new HashMap<>(queryParams);
        fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        String calculatedHash = VnPayUtil.hashAllFields(fields, properties.getHashSecret());
        boolean validSignature = calculatedHash.equalsIgnoreCase(secureHash);

        String responseCode = queryParams.get("vnp_ResponseCode");
        String txnRef = queryParams.get("vnp_TxnRef");
        String transactionNo = queryParams.get("vnp_TransactionNo");
        String bankCode = queryParams.get("vnp_BankCode");
        String amountStr = queryParams.get("vnp_Amount");

        BigDecimal amount = BigDecimal.ZERO;
        if (amountStr != null) {
            try {
                amount = new BigDecimal(amountStr).divide(BigDecimal.valueOf(100));
            } catch (Exception ignored) {}
        }

        boolean isSuccess = validSignature && "00".equals(responseCode);
        String message = validSignature ? getResponseMessage(responseCode) : "Chữ ký không hợp lệ (Invalid Checksum)";

        // Double check order update if return reached before IPN
        if (isSuccess && txnRef != null) {
            Payment payment = paymentRepository.findByTransactionCode(txnRef).orElse(null);
            Order order = null;
            if (payment != null) {
                order = orderRepository.findById(payment.getOrderId()).orElse(null);
            } else {
                order = orderRepository.findByOrderCode(txnRef).orElse(null);
                if (order == null && txnRef.contains("_")) {
                    String baseCode = txnRef.substring(0, txnRef.lastIndexOf('_'));
                    order = orderRepository.findByOrderCode(baseCode).orElse(null);
                }
            }

            if (order != null && !"PAID".equalsIgnoreCase(order.getPaymentStatus())) {
                orderRepository.updatePaymentStatus(order.getId(), "PAID");
                if ("PENDING".equalsIgnoreCase(order.getOrderStatus())) {
                    orderRepository.updateOrderStatus(order.getId(), "ACCEPTED");
                }
                if (payment != null) {
                    paymentRepository.updatePaymentResult(payment.getId(), "COMPLETED", queryParams.toString(), OffsetDateTime.now());
                }
            }
        }

        return new VnPayReturnResult(
                isSuccess,
                txnRef,
                transactionNo,
                bankCode,
                amount,
                responseCode,
                message
        );
    }

    public static String getResponseMessage(String responseCode) {
        if (responseCode == null) return "Không xác định";
        return switch (responseCode) {
            case "00" -> "Giao dịch thành công";
            case "07" -> "Trừ tiền thành công. Giao dịch bị nghi ngờ gian lận";
            case "09" -> "Thẻ/Tài khoản chưa đăng ký dịch vụ Internet Banking";
            case "10" -> "Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần";
            case "11" -> "Đã hết hạn chờ thanh toán";
            case "12" -> "Thẻ/Tài khoản bị khóa";
            case "13" -> "Nhập sai mật khẩu xác thực OTP";
            case "24" -> "Khách hàng hủy giao dịch";
            case "51" -> "Tài khoản không đủ số dư";
            case "65" -> "Tài khoản vượt quá hạn mức giao dịch trong ngày";
            case "75" -> "Ngân hàng thanh toán đang bảo trì";
            case "79" -> "Nhập sai mật khẩu thanh toán quá số lần quy định";
            default -> "Giao dịch thất bại (Mã lỗi: " + responseCode + ")";
        };
    }
}
