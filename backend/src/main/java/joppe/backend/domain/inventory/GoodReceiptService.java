package joppe.backend.domain.inventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import joppe.backend.domain.catalog.ProductVariantService;
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

    @Transactional
    public void completeReceipt(UUID receiptId) {
        GoodReceipt receipt = goodReceiptRepository.findById(receiptId)
                .orElseThrow(() -> new IllegalArgumentException("Receipt not found: " + receiptId));

        if (!"DRAFT".equalsIgnoreCase(receipt.getStatus())) {
            throw new IllegalStateException("Receipt already processed: " + receipt.getStatus());
        }

        List<GoodItem> items = goodItemRepository.findByReceiptId(receiptId);
        for (GoodItem item : items) {
            productVariantService.addStock(item.getVariantId(), item.getQuantity());
        }

        goodReceiptRepository.updateStatus(receiptId, "COMPLETED");
    }
}
