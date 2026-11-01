package joppe.backend.domain.inventory;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.catalog.ProductVariantService;
import joppe.backend.domain.inventory.dto.CreateReceiptItemInput;
import joppe.backend.domain.inventory.dto.CreateReceiptRequest;
import joppe.backend.domain.inventory.dto.InventoryStockResponse;
import joppe.backend.domain.inventory.dto.ReceiptDetailResponse;
import joppe.backend.domain.inventory.dto.ReceiptItemResponse;
import joppe.backend.domain.inventory.dto.ReceiptSummaryResponse;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderItem;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GoodReceiptService {

    private final GoodReceiptRepository goodReceiptRepository;
    private final GoodItemRepository goodItemRepository;
    private final SupplierRepository supplierRepository;
    private final ProductVariantService productVariantService;
    private final ProductVariantRepository productVariantRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;

    private static final DateTimeFormatter CODE_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    private String generateUniqueReceiptCode() {
        String datePart = LocalDate.now().format(CODE_DATE_FORMAT);
        String code;
        do {
            String randomPart = UUID.randomUUID().toString().replace("-", "").substring(0, 5).toUpperCase();
            code = "REC-" + datePart + "-" + randomPart;
        } while (goodReceiptRepository.existsByReceiptCode(code));
        return code;
    }

    private String generateUniqueOutboundCode() {
        String datePart = LocalDate.now().format(CODE_DATE_FORMAT);
        String code;
        do {
            String randomPart = UUID.randomUUID().toString().replace("-", "").substring(0, 5).toUpperCase();
            code = "OUT-" + datePart + "-" + randomPart;
        } while (goodReceiptRepository.existsByReceiptCode(code));
        return code;
    }

    @Transactional
    public GoodReceipt createAutoOutboundForOrder(Order order, List<OrderItem> items, UUID staffId) {
        if (order == null || order.getId() == null) {
            return null;
        }
        if (goodReceiptRepository.existsByOrderId(order.getId())) {
            return goodReceiptRepository.findByOrderId(order.getId()).orElse(null);
        }
        if (items == null || items.isEmpty()) {
            return null;
        }

        UUID effectiveStaff = staffId != null ? staffId : (order.getUserId() != null ? order.getUserId() : UUID.randomUUID());
        String code = generateUniqueOutboundCode();

        BigDecimal calculatedTotal = items.stream()
                .map(i -> (i.getUnitPrice() != null ? i.getUnitPrice() : BigDecimal.ZERO)
                        .multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        GoodReceipt receipt = GoodReceipt.builder()
                .receiptCode(code)
                .receiptType("OUTBOUND")
                .orderId(order.getId())
                .supplierId(null)
                .staffId(effectiveStaff)
                .totalAmount(calculatedTotal)
                .status("COMPLETED")
                .note("Auto outbound for order " + order.getOrderCode())
                .build();

        GoodReceipt savedReceipt = goodReceiptRepository.save(receipt);

        for (OrderItem item : items) {
            if (item.getVariantId() != null) {
                GoodItem goodItem = GoodItem.builder()
                        .receiptId(savedReceipt.getId())
                        .variantId(item.getVariantId())
                        .quantity(item.getQuantity())
                        .importPrice(item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO)
                        .build();
                goodItemRepository.save(goodItem);
            }
        }

        return savedReceipt;
    }

    @Transactional
    public ReceiptDetailResponse createAndProcessReceipt(UUID staffId, CreateReceiptRequest request) {
        Supplier supplier = supplierRepository.findById(request.supplierId())
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with ID: " + request.supplierId()));

        String code = (request.receiptCode() != null && !request.receiptCode().isBlank())
                ? request.receiptCode().trim()
                : generateUniqueReceiptCode();

        if (goodReceiptRepository.existsByReceiptCode(code)) {
            throw new IllegalArgumentException("Receipt code already exists: " + code);
        }

        boolean completeImmediately = Boolean.TRUE.equals(request.completeImmediately());
        String initialStatus = completeImmediately ? "COMPLETED" : "DRAFT";

        List<UUID> variantIds = request.items().stream().map(CreateReceiptItemInput::variantId).distinct().toList();
        Map<UUID, ProductVariant> variantMap = productVariantRepository.findAllById(variantIds).stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        GoodReceipt receipt = GoodReceipt.builder()
                .receiptCode(code)
                .receiptType("INBOUND")
                .supplierId(supplier.getId())
                .staffId(staffId)
                .totalAmount(BigDecimal.ZERO)
                .status(initialStatus)
                .build();

        GoodReceipt savedReceipt = goodReceiptRepository.save(receipt);

        BigDecimal calculatedTotal = BigDecimal.ZERO;
        List<GoodItem> savedItems = new ArrayList<>();

        for (CreateReceiptItemInput itemInput : request.items()) {
            ProductVariant variant = variantMap.get(itemInput.variantId());
            if (variant == null) {
                throw new IllegalArgumentException("Product variant not found: " + itemInput.variantId());
            }

            BigDecimal lineSubtotal = itemInput.importPrice().multiply(BigDecimal.valueOf(itemInput.quantity()));
            calculatedTotal = calculatedTotal.add(lineSubtotal);

            GoodItem item = GoodItem.builder()
                    .receiptId(savedReceipt.getId())
                    .variantId(variant.getId())
                    .quantity(itemInput.quantity())
                    .importPrice(itemInput.importPrice())
                    .build();

            savedItems.add(goodItemRepository.save(item));

            if (completeImmediately) {
                productVariantService.addStock(variant.getId(), itemInput.quantity());
            }
        }

        savedReceipt.setTotalAmount(calculatedTotal);
        goodReceiptRepository.save(savedReceipt);

        return mapToDetailResponse(savedReceipt, savedItems, supplier.getSupplierName());
    }

    @Transactional
    public ReceiptDetailResponse completeReceipt(UUID receiptId) {
        GoodReceipt receipt = goodReceiptRepository.findById(receiptId)
                .orElseThrow(() -> new IllegalArgumentException("Receipt not found: " + receiptId));

        if (!"DRAFT".equalsIgnoreCase(receipt.getStatus())) {
            throw new IllegalStateException("Receipt is already processed: " + receipt.getStatus());
        }

        List<GoodItem> items = goodItemRepository.findByReceiptId(receiptId);
        for (GoodItem item : items) {
            productVariantService.addStock(item.getVariantId(), item.getQuantity());
        }

        receipt.setStatus("COMPLETED");
        goodReceiptRepository.save(receipt);

        return getReceiptDetail(receiptId);
    }

    @Transactional(readOnly = true)
    public List<ReceiptSummaryResponse> listReceipts(String status, UUID supplierId, String search) {
        return listReceipts(null, status, supplierId, search);
    }

    @Transactional(readOnly = true)
    public List<ReceiptSummaryResponse> listReceipts(String receiptType, String status, UUID supplierId, String search) {
        String cleanType = (receiptType != null && !receiptType.isBlank() && !receiptType.equalsIgnoreCase("ALL"))
                ? receiptType.trim().toUpperCase()
                : null;
        String cleanStatus = (status != null && !status.isBlank() && !status.equalsIgnoreCase("ALL"))
                ? status.trim().toUpperCase()
                : null;
        String searchPattern = (search != null && !search.isBlank()) ? ("%" + search.trim().toLowerCase() + "%") : null;

        List<GoodReceipt> receipts = goodReceiptRepository.findFiltered(cleanType, cleanStatus, supplierId, searchPattern);
        Map<UUID, String> supplierNameMap = supplierRepository.findAll().stream()
                .collect(Collectors.toMap(Supplier::getId, Supplier::getSupplierName, (a, b) -> a));
        Map<UUID, String> staffNameMap = userRepository.findAll().stream()
                .collect(Collectors.toMap(User::getId, User::getFullName, (a, b) -> a));

        List<UUID> orderIds = receipts.stream()
                .map(GoodReceipt::getOrderId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        Map<UUID, String> orderCodeMap = orderIds.isEmpty() ? Map.of() : orderRepository.findAllById(orderIds).stream()
                .collect(Collectors.toMap(Order::getId, Order::getOrderCode, (a, b) -> a));

        List<ReceiptSummaryResponse> result = new ArrayList<>();
        for (GoodReceipt r : receipts) {
            List<GoodItem> items = goodItemRepository.findByReceiptId(r.getId());
            int totalItems = items.stream().mapToInt(GoodItem::getQuantity).sum();
            String supName = r.getSupplierId() != null ? supplierNameMap.getOrDefault(r.getSupplierId(), "Unknown Supplier") : null;
            String staffName = staffNameMap.getOrDefault(r.getStaffId(), "Staff");
            String orderCode = r.getOrderId() != null ? orderCodeMap.get(r.getOrderId()) : null;

            result.add(new ReceiptSummaryResponse(
                    r.getId(),
                    r.getReceiptCode(),
                    r.getReceiptType() != null ? r.getReceiptType() : "INBOUND",
                    r.getSupplierId(),
                    supName,
                    r.getOrderId(),
                    orderCode,
                    r.getStaffId(),
                    staffName,
                    r.getTotalAmount(),
                    totalItems,
                    r.getStatus(),
                    r.getCreatedAt(),
                    r.getNote()
            ));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public ReceiptDetailResponse getReceiptDetail(UUID receiptId) {
        GoodReceipt receipt = goodReceiptRepository.findById(receiptId)
                .orElseThrow(() -> new IllegalArgumentException("Receipt not found: " + receiptId));

        List<GoodItem> items = goodItemRepository.findByReceiptId(receiptId);
        String supplierName = receipt.getSupplierId() != null
                ? supplierRepository.findById(receipt.getSupplierId()).map(Supplier::getSupplierName).orElse("Unknown Supplier")
                : null;
        String orderCode = receipt.getOrderId() != null
                ? orderRepository.findById(receipt.getOrderId()).map(Order::getOrderCode).orElse(null)
                : null;

        return mapToDetailResponse(receipt, items, supplierName, orderCode);
    }

    @Transactional(readOnly = true)
    public List<InventoryStockResponse> listInventoryStock(Boolean lowStockOnly, String search, Integer categoryId, Integer brandId) {
        List<ProductVariant> variants = productVariantRepository.findAll();
        List<UUID> productIds = variants.stream().map(ProductVariant::getProductId).distinct().toList();
        Map<UUID, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));

        String cleanSearch = (search != null && !search.isBlank()) ? search.trim().toLowerCase() : null;

        List<InventoryStockResponse> result = new ArrayList<>();

        for (ProductVariant v : variants) {
            Product p = productMap.get(v.getProductId());
            if (p == null) continue;

            if (categoryId != null && !p.getCategoryId().equals(categoryId)) {
                continue;
            }
            if (brandId != null && !p.getBrandId().equals(brandId)) {
                continue;
            }

            int onHand = v.getQuantityOnHand() != null ? v.getQuantityOnHand() : 0;
            int reserved = v.getQuantityReserved() != null ? v.getQuantityReserved() : 0;
            int available = Math.max(0, onHand - reserved);
            int reorder = v.getReorderLevel() != null ? v.getReorderLevel() : 10;

            boolean isOutOfStock = available <= 0;
            boolean isLowStock = available > 0 && available <= reorder;

            if (Boolean.TRUE.equals(lowStockOnly) && !isOutOfStock && !isLowStock) {
                continue;
            }

            if (cleanSearch != null) {
                boolean matchName = p.getProductName().toLowerCase().contains(cleanSearch);
                boolean matchVar = v.getVariantName().toLowerCase().contains(cleanSearch);
                boolean matchSku = v.getSku().toLowerCase().contains(cleanSearch);
                if (!matchName && !matchVar && !matchSku) {
                    continue;
                }
            }

            result.add(new InventoryStockResponse(
                    v.getId(),
                    p.getId(),
                    p.getProductName(),
                    v.getVariantName(),
                    v.getSku(),
                    v.getSku(),
                    v.getThumbnailUrl(),
                    v.getSalePrice(),
                    v.getListPrice(),
                    onHand,
                    reserved,
                    available,
                    reorder,
                    isLowStock,
                    isOutOfStock
            ));
        }

        return result;
    }

    @Transactional
    public InventoryStockResponse updateStockLevel(UUID variantId, int newOnHand, int newReorderLevel) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Product variant not found: " + variantId));

        variant.setQuantityOnHand(Math.max(0, newOnHand));
        variant.setReorderLevel(Math.max(0, newReorderLevel));
        ProductVariant saved = productVariantRepository.save(variant);

        Product product = productRepository.findById(saved.getProductId()).orElse(null);
        String prodName = (product != null) ? product.getProductName() : "Unknown Product";

        int onHand = saved.getQuantityOnHand();
        int reserved = saved.getQuantityReserved() != null ? saved.getQuantityReserved() : 0;
        int available = Math.max(0, onHand - reserved);
        int reorder = saved.getReorderLevel();

        return new InventoryStockResponse(
                saved.getId(),
                saved.getProductId(),
                prodName,
                saved.getVariantName(),
                saved.getSku(),
                saved.getSku(),
                saved.getThumbnailUrl(),
                saved.getSalePrice(),
                saved.getListPrice(),
                onHand,
                reserved,
                available,
                reorder,
                available > 0 && available <= reorder,
                available <= 0
        );
    }

    private ReceiptDetailResponse mapToDetailResponse(GoodReceipt receipt, List<GoodItem> items, String supplierName) {
        return mapToDetailResponse(receipt, items, supplierName, null);
    }

    private ReceiptDetailResponse mapToDetailResponse(GoodReceipt receipt, List<GoodItem> items, String supplierName, String orderCode) {
        String staffName = userRepository.findById(receipt.getStaffId())
                .map(User::getFullName)
                .orElse("Staff");

        List<UUID> variantIds = items.stream().map(GoodItem::getVariantId).distinct().toList();
        Map<UUID, ProductVariant> variantMap = productVariantRepository.findAllById(variantIds).stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        List<UUID> productIds = variantMap.values().stream().map(ProductVariant::getProductId).distinct().toList();
        Map<UUID, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));

        List<ReceiptItemResponse> itemResponses = items.stream().map(i -> {
            ProductVariant v = variantMap.get(i.getVariantId());
            Product p = (v != null) ? productMap.get(v.getProductId()) : null;

            String pName = (p != null) ? p.getProductName() : "Product";
            String vName = (v != null) ? v.getVariantName() : "Variant";
            String sku = (v != null) ? v.getSku() : "";
            String thumb = (v != null) ? v.getThumbnailUrl() : null;
            BigDecimal subtotal = i.getImportPrice().multiply(BigDecimal.valueOf(i.getQuantity()));

            return new ReceiptItemResponse(
                    i.getId(),
                    i.getVariantId(),
                    pName,
                    vName,
                    sku,
                    thumb,
                    i.getQuantity(),
                    i.getImportPrice(),
                    subtotal
            );
        }).toList();

        return new ReceiptDetailResponse(
                receipt.getId(),
                receipt.getReceiptCode(),
                receipt.getReceiptType() != null ? receipt.getReceiptType() : "INBOUND",
                receipt.getSupplierId(),
                supplierName,
                receipt.getOrderId(),
                orderCode,
                receipt.getStaffId(),
                staffName,
                receipt.getTotalAmount(),
                receipt.getStatus(),
                receipt.getCreatedAt(),
                receipt.getNote(),
                itemResponses
        );
    }

    // -------------------------------------------------------------------------
    // Legacy primitive methods
    // -------------------------------------------------------------------------

    @Transactional
    public UUID createReceipt(String receiptCode, UUID supplierId, UUID staffId) {
        if (goodReceiptRepository.existsByReceiptCode(receiptCode)) {
            throw new IllegalArgumentException("Receipt code already exists: " + receiptCode);
        }
        if (!supplierRepository.existsById(supplierId)) {
            throw new IllegalArgumentException("Supplier not found with ID: " + supplierId);
        }

        GoodReceipt receipt = GoodReceipt.builder()
                .receiptCode(receiptCode)
                .supplierId(supplierId)
                .staffId(staffId)
                .totalAmount(BigDecimal.ZERO)
                .status("DRAFT")
                .build();

        return goodReceiptRepository.save(receipt).getId();
    }

    @Transactional
    public UUID addReceiptItem(UUID receiptId, UUID variantId, int quantity, BigDecimal importPrice) {
        GoodReceipt receipt = goodReceiptRepository.findById(receiptId)
                .orElseThrow(() -> new IllegalArgumentException("Receipt not found: " + receiptId));

        if (!"DRAFT".equalsIgnoreCase(receipt.getStatus())) {
            throw new IllegalStateException("Cannot add items to non-DRAFT receipt");
        }

        GoodItem item = GoodItem.builder()
                .receiptId(receiptId)
                .variantId(variantId)
                .quantity(quantity)
                .importPrice(importPrice)
                .build();

        GoodItem saved = goodItemRepository.save(item);

        BigDecimal newTotal = goodItemRepository.calculateReceiptTotal(receiptId);
        goodReceiptRepository.updateTotalAmount(receiptId, newTotal);

        return saved.getId();
    }
}
