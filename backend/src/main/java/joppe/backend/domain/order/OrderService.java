package joppe.backend.domain.order;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import joppe.backend.admin.dto.CreateAdminOrderRequest;
import joppe.backend.admin.dto.ManualPaymentConfirmRequest;
import joppe.backend.domain.cart.CartItem;
import joppe.backend.domain.cart.CartItemRepository;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductSerial;
import joppe.backend.domain.catalog.ProductSerialRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.catalog.ProductVariantService;
import joppe.backend.domain.inventory.GoodReceiptService;
import joppe.backend.domain.order.dto.CheckoutItemInput;
import joppe.backend.domain.order.dto.CheckoutRequest;
import joppe.backend.domain.order.dto.OrderItemResponse;
import joppe.backend.domain.order.dto.OrderResponse;
import joppe.backend.domain.order.dto.OrderSummaryResponse;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final ProductVariantService productVariantService;
    private final ProductVariantRepository productVariantRepository;
    private final ProductRepository productRepository;
    private final CartItemRepository cartItemRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final GoodReceiptService goodReceiptService;
    private final ProductSerialRepository productSerialRepository;

    private static final DateTimeFormatter CODE_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    private String generateUniqueOrderCode() {
        String datePart = LocalDate.now().format(CODE_DATE_FORMAT);
        String code;
        do {
            String randomPart = UUID.randomUUID().toString().replace("-", "").substring(0, 5).toUpperCase();
            code = "ORD-" + datePart + "-" + randomPart;
        } while (orderRepository.existsByOrderCode(code));
        return code;
    }

    @Transactional
    public OrderResponse checkout(UUID userId, CheckoutRequest request) {
        List<CheckoutItemInput> checkoutItems = new ArrayList<>();

        if (request.items() != null && !request.items().isEmpty()) {
            checkoutItems.addAll(request.items());
        } else {
            List<CartItem> cartItems = cartItemRepository.findByUserId(userId);
            if (cartItems.isEmpty()) {
                throw new IllegalArgumentException("Cart is empty. Please add items before checking out.");
            }
            for (CartItem ci : cartItems) {
                checkoutItems.add(new CheckoutItemInput(ci.getVariantId(), ci.getQuantity()));
            }
        }

        List<UUID> variantIds = checkoutItems.stream().map(CheckoutItemInput::variantId).distinct().toList();
        Map<UUID, ProductVariant> variantMap = productVariantRepository.findAllById(variantIds).stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        List<UUID> productIds = variantMap.values().stream().map(ProductVariant::getProductId).distinct().toList();
        Map<UUID, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));

        BigDecimal subtotal = BigDecimal.ZERO;
        List<OrderItem> savedItems = new ArrayList<>();

        String orderCode = generateUniqueOrderCode();
        BigDecimal shippingFee = request.shippingFee() != null ? request.shippingFee() : BigDecimal.ZERO;
        BigDecimal discountAmount = BigDecimal.ZERO;

        OffsetDateTime now = OffsetDateTime.now();
        boolean isOnlinePayment = request.paymentMethod() != null &&
                ("VNPAY".equalsIgnoreCase(request.paymentMethod()) ||
                 "VIETQR".equalsIgnoreCase(request.paymentMethod()));

        String initialPaymentStatus = request.paymentStatus() != null
                ? request.paymentStatus()
                : (isOnlinePayment ? "UNPAID" : "PAID");

        OffsetDateTime paidAt = "PAID".equalsIgnoreCase(initialPaymentStatus) ? now : null;
        OffsetDateTime paymentExpiresAt = ("UNPAID".equalsIgnoreCase(initialPaymentStatus) && isOnlinePayment)
                ? now.plusMinutes(10)
                : null;

        Order order = Order.builder()
                .orderCode(orderCode)
                .userId(userId)
                .orderChannel("ONLINE")
                .orderStatus("ACCEPTED")
                .paymentStatus(initialPaymentStatus)
                .paidAt(paidAt)
                .paymentExpiresAt(paymentExpiresAt)
                .recipientName(request.recipientName().trim())
                .recipientPhone(request.recipientPhone().trim())
                .shippingAddress(request.shippingAddress().trim())
                .subtotalAmount(BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .shippingFee(shippingFee)
                .finalAmount(BigDecimal.ZERO)
                .customerNote(request.customerNote() != null ? request.customerNote().trim() : null)
                .build();

        Order savedOrder = orderRepository.save(order);

        for (CheckoutItemInput input : checkoutItems) {
            ProductVariant variant = variantMap.get(input.variantId());
            if (variant == null) {
                throw new IllegalArgumentException("Product variant not found: " + input.variantId());
            }
            if (Boolean.FALSE.equals(variant.getIsActive())) {
                throw new IllegalArgumentException("Variant is not active: " + variant.getVariantName());
            }

            boolean reserved = productVariantService.reserveStock(variant.getId(), input.quantity());
            if (!reserved) {
                throw new IllegalStateException("Insufficient stock to reserve for item: " + variant.getVariantName());
            }

            Product product = productMap.get(variant.getProductId());
            String productName = (product != null) ? product.getProductName() : "Product";

            BigDecimal unitPrice = (variant.getSalePrice() != null && variant.getSalePrice().compareTo(BigDecimal.ZERO) > 0)
                    ? variant.getSalePrice()
                    : (variant.getListPrice() != null ? variant.getListPrice() : BigDecimal.ZERO);

            BigDecimal lineSubtotal = unitPrice.multiply(BigDecimal.valueOf(input.quantity()));
            subtotal = subtotal.add(lineSubtotal);

            OrderItem item = OrderItem.builder()
                    .orderId(savedOrder.getId())
                    .variantId(variant.getId())
                    .skuSnapshot(variant.getSku())
                    .productNameSnapshot(productName)
                    .variantNameSnapshot(variant.getVariantName())
                    .quantity(input.quantity())
                    .unitPrice(unitPrice)
                    .subtotal(lineSubtotal)
                    .warrantyMonthsSnapshot(12)
                    .build();

            savedItems.add(orderItemRepository.save(item));

            // Clean up from user cart if existed
            cartItemRepository.deleteByUserIdAndVariantId(userId, variant.getId());
        }

        BigDecimal finalAmount = subtotal.subtract(discountAmount).add(shippingFee);
        if (finalAmount.compareTo(BigDecimal.ZERO) < 0) {
            finalAmount = BigDecimal.ZERO;
        }

        savedOrder.setSubtotalAmount(subtotal);
        savedOrder.setFinalAmount(finalAmount);
        orderRepository.save(savedOrder);

        // Auto outbound goods receipt when online order is placed and accepted
        goodReceiptService.createAutoOutboundForOrder(savedOrder, savedItems, userId);

        return mapToOrderResponse(savedOrder, savedItems, variantMap);
    }

    @Transactional(readOnly = true)
    public List<OrderSummaryResponse> getMyOrders(UUID userId) {
        List<Order> orders = orderRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return mapToSummaryList(orders);
    }

    @Transactional(readOnly = true)
    public OrderResponse getCustomerOrder(UUID userId, UUID orderId) {
        Order order = orderRepository.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found or unauthorized"));
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        return mapToOrderResponse(order, items, null);
    }

    @Transactional
    public OrderResponse cancelOrder(UUID userId, UUID orderId) {
        Order order = orderRepository.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found or unauthorized"));

        String currentStatus = order.getOrderStatus() != null ? order.getOrderStatus().toUpperCase() : "ACCEPTED";
        if (!"ACCEPTED".equals(currentStatus) && !"PACKAGING".equals(currentStatus) && !"PENDING".equals(currentStatus)) {
            throw new IllegalStateException("Only orders before delivery can be cancelled by customer. Current status: " + order.getOrderStatus());
        }

        validateRefundEligibility(order);

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        for (OrderItem item : items) {
            if (item.getVariantId() != null) {
                productVariantService.releaseStock(item.getVariantId(), item.getQuantity());
            }
        }
        releaseSerialNumbersForOrder(items);

        order.setOrderStatus("REFUND");
        order.setPaymentStatus("REFUND");
        orderRepository.save(order);

        return mapToOrderResponse(order, items, null);
    }

    // -------------------------------------------------------------------------
    // Administrative Operations
    // -------------------------------------------------------------------------

    @Transactional
    public OrderResponse createAdminOrder(UUID staffUserId, CreateAdminOrderRequest request) {
        if (request.items() == null || request.items().isEmpty()) {
            throw new IllegalArgumentException("Order must contain at least one line item");
        }

        UUID customerId = resolveOrCreateCustomer(request);

        String rawStatus = (request.orderStatus() != null && !request.orderStatus().isBlank())
                ? request.orderStatus().trim().toUpperCase()
                : null;

        boolean isCounterPickup = "DELIVERED".equalsIgnoreCase(rawStatus)
                || "SHOWROOM_BUY".equalsIgnoreCase(rawStatus)
                || "PURCHASED".equalsIgnoreCase(rawStatus)
                || (request.shippingAddress() != null && request.shippingAddress().toLowerCase().contains("quầy"));

        String orderStatus;
        if (isCounterPickup) {
            orderStatus = "SHOWROOM_BUY";
        } else if (rawStatus == null || "CONFIRMED".equalsIgnoreCase(rawStatus) || "PENDING".equalsIgnoreCase(rawStatus)) {
            orderStatus = "ACCEPTED";
        } else {
            orderStatus = rawStatus;
        }

        String paymentStatus = (request.paymentStatus() != null && !request.paymentStatus().isBlank())
                ? request.paymentStatus().trim().toUpperCase()
                : "PAID";
        if ("REFUNDED".equalsIgnoreCase(paymentStatus)) {
            paymentStatus = "REFUND";
        }

        OffsetDateTime now = OffsetDateTime.now();
        OffsetDateTime paidAt = "PAID".equalsIgnoreCase(paymentStatus) ? now : null;
        OffsetDateTime deliveredAt = ("SHOWROOM_BUY".equalsIgnoreCase(orderStatus) || "SHIPPED".equalsIgnoreCase(orderStatus)) ? now : null;
        OffsetDateTime paymentExpiresAt = "UNPAID".equalsIgnoreCase(paymentStatus) ? now.plusMinutes(10) : null;

        List<UUID> variantIds = request.items().stream().map(CheckoutItemInput::variantId).distinct().toList();
        Map<UUID, ProductVariant> variantMap = productVariantRepository.findAllById(variantIds).stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        List<UUID> productIds = variantMap.values().stream().map(ProductVariant::getProductId).distinct().toList();
        Map<UUID, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));

        BigDecimal subtotal = BigDecimal.ZERO;
        List<OrderItem> savedItems = new ArrayList<>();

        String orderCode = generateUniqueOrderCode();
        BigDecimal shippingFee = request.shippingFee() != null ? request.shippingFee() : BigDecimal.ZERO;
        BigDecimal discountAmount = BigDecimal.ZERO;

        Order order = Order.builder()
                .orderCode(orderCode)
                .userId(customerId)
                .orderChannel(isCounterPickup ? "SHOWROOM" : "ONLINE")
                .orderStatus(orderStatus)
                .paymentStatus(paymentStatus)
                .paidAt(paidAt)
                .deliveredAt(deliveredAt)
                .paymentExpiresAt(paymentExpiresAt)
                .recipientName(request.recipientName().trim())
                .recipientPhone(request.recipientPhone().trim())
                .shippingAddress(request.shippingAddress().trim())
                .subtotalAmount(BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .shippingFee(shippingFee)
                .finalAmount(BigDecimal.ZERO)
                .customerNote(request.customerNote() != null ? request.customerNote().trim() : null)
                .build();

        Order savedOrder = orderRepository.save(order);

        boolean immediateDeduct = "SHOWROOM_BUY".equalsIgnoreCase(orderStatus)
                || "DELIVERY".equalsIgnoreCase(orderStatus)
                || "SHIPPED".equalsIgnoreCase(orderStatus);

        for (CheckoutItemInput input : request.items()) {
            ProductVariant variant = variantMap.get(input.variantId());
            if (variant == null) {
                throw new IllegalArgumentException("Product variant not found: " + input.variantId());
            }
            if (Boolean.FALSE.equals(variant.getIsActive())) {
                throw new IllegalArgumentException("Variant is not active: " + variant.getVariantName());
            }

            boolean reserved = productVariantService.reserveStock(variant.getId(), input.quantity());
            if (!reserved) {
                throw new IllegalStateException("Insufficient stock to reserve for item: " + variant.getVariantName());
            }

            if (immediateDeduct) {
                productVariantService.deductStockOnFulfillment(variant.getId(), input.quantity());
            }

            Product product = productMap.get(variant.getProductId());
            String productName = (product != null) ? product.getProductName() : "Product";

            BigDecimal unitPrice = (variant.getSalePrice() != null && variant.getSalePrice().compareTo(BigDecimal.ZERO) > 0)
                    ? variant.getSalePrice()
                    : (variant.getListPrice() != null ? variant.getListPrice() : BigDecimal.ZERO);

            BigDecimal lineSubtotal = unitPrice.multiply(BigDecimal.valueOf(input.quantity()));
            subtotal = subtotal.add(lineSubtotal);

            OrderItem item = OrderItem.builder()
                    .orderId(savedOrder.getId())
                    .variantId(variant.getId())
                    .skuSnapshot(variant.getSku())
                    .productNameSnapshot(productName)
                    .variantNameSnapshot(variant.getVariantName())
                    .quantity(input.quantity())
                    .unitPrice(unitPrice)
                    .subtotal(lineSubtotal)
                    .warrantyMonthsSnapshot(12)
                    .build();

            OrderItem savedItem = orderItemRepository.save(item);
            savedItems.add(savedItem);

            if (input.serialNumbers() != null && !input.serialNumbers().isEmpty()) {
                assignSerialNumbersToOrderItem(savedItem, input.serialNumbers(), variant.getId());
            }
        }

        BigDecimal finalAmount = subtotal.subtract(discountAmount).add(shippingFee);
        if (finalAmount.compareTo(BigDecimal.ZERO) < 0) {
            finalAmount = BigDecimal.ZERO;
        }

        savedOrder.setSubtotalAmount(subtotal);
        savedOrder.setFinalAmount(finalAmount);
        orderRepository.save(savedOrder);

        // Auto outbound goods receipt when showroom/counter order is placed
        goodReceiptService.createAutoOutboundForOrder(savedOrder, savedItems, staffUserId);

        return mapToOrderResponse(savedOrder, savedItems, variantMap);
    }

    private UUID resolveOrCreateCustomer(CreateAdminOrderRequest request) {
        if (request.userId() != null && userRepository.existsById(request.userId())) {
            return request.userId();
        }

        String phone = request.recipientPhone() != null ? request.recipientPhone().trim() : "";
        if (!phone.isBlank()) {
            Optional<User> byPhone = userRepository.findByPhoneNumber(phone);
            if (byPhone.isPresent()) {
                return byPhone.get().getId();
            }
        }

        String email = request.customerEmail() != null ? request.customerEmail().trim() : "";
        if (!email.isBlank()) {
            Optional<User> byEmail = userRepository.findByEmail(email);
            if (byEmail.isPresent()) {
                return byEmail.get().getId();
            }
        }

        Integer customerRoleId = roleRepository.findByRoleName("ROLE_CUSTOMER")
                .map(Role::getId)
                .orElse(3);

        String cleanDigits = phone.replaceAll("\\D", "");
        String guestEmail = !email.isBlank()
                ? email
                : ("pos_" + (cleanDigits.isBlank() ? UUID.randomUUID().toString().substring(0, 8) : cleanDigits) + "@guest.joppe.vn");

        User guestUser = User.builder()
                .email(guestEmail)
                .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                .fullName(request.recipientName().trim())
                .phoneNumber(!phone.isBlank() ? phone : null)
                .roleId(customerRoleId)
                .isActive(true)
                .build();

        return userRepository.save(guestUser).getId();
    }

    @Transactional(readOnly = true)
    public List<OrderSummaryResponse> listAdminOrders(String status, String paymentStatus, String search) {
        String cleanStatus = (status != null && !status.isBlank() && !status.equalsIgnoreCase("ALL")) ? status.trim().toUpperCase() : null;
        String cleanPayment = (paymentStatus != null && !paymentStatus.isBlank() && !paymentStatus.equalsIgnoreCase("ALL")) ? paymentStatus.trim().toUpperCase() : null;
        String searchPattern = (search != null && !search.isBlank()) ? ("%" + search.trim().toLowerCase() + "%") : null;

        List<Order> orders = orderRepository.findFilteredOrders(cleanStatus, cleanPayment, searchPattern);
        return mapToSummaryList(orders);
    }

    @Transactional(readOnly = true)
    public OrderResponse getAdminOrder(UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId));
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        return mapToOrderResponse(order, items, null);
    }

    @Transactional
    public OrderResponse updateOrderStatusByAdmin(UUID orderId, String newStatus) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId));

        String upperStatus = newStatus.trim().toUpperCase();
        if ("CONFIRMED".equals(upperStatus) || "PENDING".equals(upperStatus)) {
            upperStatus = "ACCEPTED";
        } else if ("PACKING".equals(upperStatus)) {
            upperStatus = "PACKAGING";
        } else if ("DELIVERED".equals(upperStatus)) {
            upperStatus = "SHIPPED";
        } else if ("CANCELLED".equals(upperStatus) || "REFUNDED".equals(upperStatus)) {
            upperStatus = "REFUND";
        }

        String currentStatus = order.getOrderStatus() != null ? order.getOrderStatus().toUpperCase() : "ACCEPTED";

        if (currentStatus.equalsIgnoreCase(upperStatus)) {
            List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
            return mapToOrderResponse(order, items, null);
        }

        validateOrderStatusTransition(order, upperStatus);

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);

        if ("DELIVERY".equalsIgnoreCase(upperStatus) || "SHIPPED".equalsIgnoreCase(upperStatus)) {
            if (!"DELIVERY".equalsIgnoreCase(currentStatus) && !"SHIPPED".equalsIgnoreCase(currentStatus) && !"SHOWROOM_BUY".equalsIgnoreCase(currentStatus)) {
                for (OrderItem item : items) {
                    if (item.getVariantId() != null) {
                        productVariantService.deductStockOnFulfillment(item.getVariantId(), item.getQuantity());
                    }
                }
            }
            if ("SHIPPED".equalsIgnoreCase(upperStatus) && order.getDeliveredAt() == null) {
                order.setDeliveredAt(OffsetDateTime.now());
            }
        } else if ("REFUND".equalsIgnoreCase(upperStatus)) {
            boolean wasAlreadyDeducted = "DELIVERY".equalsIgnoreCase(currentStatus)
                    || "SHIPPED".equalsIgnoreCase(currentStatus)
                    || "SHOWROOM_BUY".equalsIgnoreCase(currentStatus);

            for (OrderItem item : items) {
                if (item.getVariantId() != null) {
                    if (wasAlreadyDeducted) {
                        productVariantService.addStock(item.getVariantId(), item.getQuantity());
                    } else {
                        productVariantService.releaseStock(item.getVariantId(), item.getQuantity());
                    }
                }
            }
            releaseSerialNumbersForOrder(items);
            if ("PAID".equalsIgnoreCase(order.getPaymentStatus())) {
                order.setPaymentStatus("REFUND");
            }
        }

        order.setOrderStatus(upperStatus);
        orderRepository.save(order);

        if ("ACCEPTED".equalsIgnoreCase(upperStatus) || "SHOWROOM_BUY".equalsIgnoreCase(upperStatus)) {
            goodReceiptService.createAutoOutboundForOrder(order, items, null);
        }

        return mapToOrderResponse(order, items, null);
    }

    @Transactional
    public OrderResponse updatePaymentStatusByAdmin(UUID orderId, String paymentStatus) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId));

        String upperPayment = paymentStatus.trim().toUpperCase();
        if ("REFUNDED".equals(upperPayment)) {
            upperPayment = "REFUND";
        }

        validatePaymentStatusTransition(order, upperPayment);

        order.setPaymentStatus(upperPayment);
        if ("PAID".equalsIgnoreCase(upperPayment) && order.getPaidAt() == null) {
            order.setPaidAt(OffsetDateTime.now());
        }

        orderRepository.save(order);

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        return mapToOrderResponse(order, items, null);
    }

    @Transactional
    public OrderResponse manualPaymentConfirm(UUID staffUserId, UUID orderId, ManualPaymentConfirmRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found with ID: " + orderId));

        if ("PAID".equalsIgnoreCase(order.getPaymentStatus())) {
            throw new IllegalStateException("Order is already marked as PAID.");
        }
        if ("REFUND".equalsIgnoreCase(order.getPaymentStatus())) {
            throw new IllegalStateException("Cannot confirm payment for refunded order.");
        }

        OffsetDateTime now = OffsetDateTime.now();
        order.setPaymentStatus("PAID");
        order.setPaidAt(now);
        order.setPaymentExpiresAt(null);
        order.setManualPaymentRef(request.referenceCode().trim());
        order.setPaymentConfirmedBy(staffUserId);
        order.setPaymentConfirmNote(request.note() != null && !request.note().isBlank() ? request.note().trim() : null);
        orderRepository.save(order);

        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
        return mapToOrderResponse(order, items, null);
    }

    private void assignSerialNumbersToOrderItem(OrderItem orderItem, List<String> serialNumbers, UUID variantId) {
        OffsetDateTime now = OffsetDateTime.now();
        for (String sn : serialNumbers) {
            String trimmed = (sn != null) ? sn.trim() : "";
            if (trimmed.isEmpty()) continue;
            Optional<ProductSerial> existing = productSerialRepository.findBySerialNumber(trimmed);
            if (existing.isPresent()) {
                ProductSerial serial = existing.get();
                if (!serial.getVariantId().equals(variantId)) {
                    throw new IllegalArgumentException("Serial number " + trimmed + " belongs to a different product variant.");
                }
                if ("SOLD".equalsIgnoreCase(serial.getStatus())) {
                    throw new IllegalStateException("Serial number " + trimmed + " is already marked as SOLD.");
                }
                serial.setStatus("SOLD");
                serial.setOrderItemId(orderItem.getId());
                serial.setSoldAt(now);
                productSerialRepository.save(serial);
            } else {
                ProductSerial newSerial = ProductSerial.builder()
                        .variantId(variantId)
                        .serialNumber(trimmed)
                        .status("SOLD")
                        .orderItemId(orderItem.getId())
                        .soldAt(now)
                        .build();
                productSerialRepository.save(newSerial);
            }
        }
    }

    private void releaseSerialNumbersForOrder(List<OrderItem> items) {
        for (OrderItem item : items) {
            List<ProductSerial> serials = productSerialRepository.findByOrderItemId(item.getId());
            for (ProductSerial s : serials) {
                s.setStatus("AVAILABLE");
                s.setOrderItemId(null);
                s.setSoldAt(null);
                productSerialRepository.save(s);
            }
        }
    }

    public void validateOrderStatusTransition(Order order, String targetStatus) {
        String current = order.getOrderStatus() != null ? order.getOrderStatus().toUpperCase() : "ACCEPTED";
        String target = targetStatus.toUpperCase();

        if (current.equals(target)) {
            return;
        }

        if ("REFUND".equals(current)) {
            throw new IllegalStateException("Order is in terminal REFUND state and cannot transition to " + target);
        }

        if ("REFUND".equals(target)) {
            validateRefundEligibility(order);
            return;
        }

        switch (current) {
            case "ACCEPTED" -> {
                if (!"PACKAGING".equals(target)) {
                    throw new IllegalStateException("Invalid order transition: ACCEPTED must transition step-by-step to PACKAGING (cannot skip to " + target + " or move backward)");
                }
            }
            case "PACKAGING" -> {
                if (!"DELIVERY".equals(target)) {
                    throw new IllegalStateException("Invalid order transition: PACKAGING must transition step-by-step to DELIVERY (cannot skip to " + target + " or move backward)");
                }
            }
            case "DELIVERY" -> {
                if (!"SHIPPED".equals(target)) {
                    throw new IllegalStateException("Invalid order transition: DELIVERY must transition step-by-step to SHIPPED (cannot move backward to " + target + ")");
                }
            }
            case "SHIPPED" -> {
                throw new IllegalStateException("Invalid order transition: SHIPPED order has already been received. Only REFUND is permitted within 10 days.");
            }
            case "SHOWROOM_BUY" -> {
                throw new IllegalStateException("Invalid order transition: SHOWROOM_BUY purchase is already completed. Only REFUND is permitted within 10 days.");
            }
            default -> throw new IllegalStateException("Unrecognized current order status: " + current);
        }
    }

    public void validateRefundEligibility(Order order) {
        OffsetDateTime referenceTime = order.getDeliveredAt() != null
                ? order.getDeliveredAt()
                : (order.getPaidAt() != null ? order.getPaidAt() : order.getCreatedAt());

        if (referenceTime == null) {
            return;
        }

        OffsetDateTime cutoff = referenceTime.plusDays(10);
        if (OffsetDateTime.now().isAfter(cutoff)) {
            throw new IllegalStateException("Cannot refund: Order exceeds the 10-day refund window from payment or receive date.");
        }
    }

    public void validatePaymentStatusTransition(Order order, String targetPaymentStatus) {
        String current = order.getPaymentStatus() != null ? order.getPaymentStatus().toUpperCase() : "PAID";
        String target = targetPaymentStatus.toUpperCase();

        if (current.equals(target)) {
            return;
        }

        if ("REFUND".equals(current)) {
            throw new IllegalStateException("Payment is in terminal REFUND state and cannot be modified.");
        }

        if ("PAID".equals(current)) {
            if ("UNPAID".equals(target)) {
                throw new IllegalStateException("Invalid payment transition: PAID orders cannot return to UNPAID. Only REFUND is allowed.");
            }
            if ("REFUND".equals(target)) {
                validateRefundEligibility(order);
                return;
            }
            throw new IllegalStateException("Invalid payment transition: from PAID to " + target);
        }

        if ("UNPAID".equals(current)) {
            if ("PAID".equals(target) || "REFUND".equals(target)) {
                return;
            }
            throw new IllegalStateException("Invalid payment transition: from UNPAID to " + target);
        }
    }

    // -------------------------------------------------------------------------
    // Response Mappers
    // -------------------------------------------------------------------------

    private List<OrderSummaryResponse> mapToSummaryList(List<Order> orders) {
        List<OrderSummaryResponse> list = new ArrayList<>();
        for (Order order : orders) {
            List<OrderItem> items = orderItemRepository.findByOrderId(order.getId());
            int totalItems = items.stream().mapToInt(OrderItem::getQuantity).sum();
            list.add(new OrderSummaryResponse(
                    order.getId(),
                    order.getOrderCode(),
                    order.getUserId(),
                    order.getOrderStatus(),
                    order.getPaymentStatus(),
                    order.getRecipientName(),
                    order.getRecipientPhone(),
                    order.getFinalAmount(),
                    totalItems,
                    order.getCreatedAt(),
                    order.getUpdatedAt(),
                    order.getOrderChannel(),
                    order.getPaidAt(),
                    order.getDeliveredAt()
            ));
        }
        return list;
    }

    private OrderResponse mapToOrderResponse(Order order, List<OrderItem> items, Map<UUID, ProductVariant> optionalVariantMap) {
        Map<UUID, ProductVariant> variantMap;
        if (optionalVariantMap != null) {
            variantMap = optionalVariantMap;
        } else {
            List<UUID> variantIds = items.stream().map(OrderItem::getVariantId).filter(id -> id != null).distinct().toList();
            variantMap = productVariantRepository.findAllById(variantIds).stream()
                    .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));
        }

        List<OrderItemResponse> itemResponses = items.stream().map(item -> {
            ProductVariant pv = item.getVariantId() != null ? variantMap.get(item.getVariantId()) : null;
            String thumb = (pv != null) ? pv.getThumbnailUrl() : null;
            List<ProductSerial> serials = productSerialRepository.findByOrderItemId(item.getId());
            List<String> snList = (serials != null) ? serials.stream().map(ProductSerial::getSerialNumber).toList() : List.of();
            return new OrderItemResponse(
                    item.getId(),
                    item.getVariantId(),
                    item.getSkuSnapshot(),
                    item.getProductNameSnapshot(),
                    item.getVariantNameSnapshot(),
                    item.getQuantity(),
                    item.getUnitPrice(),
                    item.getSubtotal(),
                    item.getWarrantyMonthsSnapshot(),
                    thumb,
                    snList
            );
        }).toList();

        return new OrderResponse(
                order.getId(),
                order.getOrderCode(),
                order.getUserId(),
                order.getOrderStatus(),
                order.getPaymentStatus(),
                order.getRecipientName(),
                order.getRecipientPhone(),
                order.getShippingAddress(),
                order.getSubtotalAmount(),
                order.getDiscountAmount(),
                order.getShippingFee(),
                order.getFinalAmount(),
                order.getCustomerNote(),
                order.getCreatedAt(),
                order.getUpdatedAt(),
                itemResponses,
                order.getOrderChannel(),
                order.getPaidAt(),
                order.getDeliveredAt(),
                order.getPaymentExpiresAt(),
                order.getManualPaymentRef(),
                order.getPaymentConfirmedBy(),
                order.getPaymentConfirmNote()
        );
    }

    // -------------------------------------------------------------------------
    // Legacy primitive methods
    // -------------------------------------------------------------------------

    @Transactional
    public UUID createOrder(
            String orderCode,
            UUID userId,
            UUID promotionId,
            String recipientName,
            String recipientPhone,
            String shippingAddress,
            BigDecimal subtotalAmount,
            BigDecimal discountAmount,
            BigDecimal shippingFee,
            BigDecimal finalAmount,
            String customerNote) {

        if (orderRepository.existsByOrderCode(orderCode)) {
            throw new IllegalArgumentException("Order code already exists: " + orderCode);
        }

        Order order = Order.builder()
                .orderCode(orderCode)
                .userId(userId)
                .promotionId(promotionId)
                .orderStatus("PENDING")
                .paymentStatus("UNPAID")
                .recipientName(recipientName)
                .recipientPhone(recipientPhone)
                .shippingAddress(shippingAddress)
                .subtotalAmount(subtotalAmount)
                .discountAmount(discountAmount)
                .shippingFee(shippingFee)
                .finalAmount(finalAmount)
                .customerNote(customerNote)
                .build();

        return orderRepository.save(order).getId();
    }

    @Transactional
    public UUID addOrderItem(
            UUID orderId,
            UUID variantId,
            String skuSnapshot,
            String productNameSnapshot,
            String variantNameSnapshot,
            int quantity,
            BigDecimal unitPrice,
            BigDecimal subtotal,
            int warrantyMonths) {

        if (variantId != null) {
            boolean reserved = productVariantService.reserveStock(variantId, quantity);
            if (!reserved) {
                throw new IllegalStateException("Insufficient stock for variant: " + variantId);
            }
        }

        OrderItem item = OrderItem.builder()
                .orderId(orderId)
                .variantId(variantId)
                .skuSnapshot(skuSnapshot)
                .productNameSnapshot(productNameSnapshot)
                .variantNameSnapshot(variantNameSnapshot)
                .quantity(quantity)
                .unitPrice(unitPrice)
                .subtotal(subtotal)
                .warrantyMonthsSnapshot(warrantyMonths)
                .build();

        return orderItemRepository.save(item).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Order> findById(UUID orderId) {
        return orderRepository.findById(orderId);
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByUser(UUID userId) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<OrderItem> getOrderItems(UUID orderId) {
        return orderItemRepository.findByOrderId(orderId);
    }

    @Transactional
    public void updateOrderStatus(UUID orderId, String newStatus) {
        updateOrderStatusByAdmin(orderId, newStatus);
    }

    @Transactional
    public void updatePaymentStatus(UUID orderId, String paymentStatus) {
        updatePaymentStatusByAdmin(orderId, paymentStatus);
    }
}
