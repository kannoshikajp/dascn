package joppe.backend.domain.catalog;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProductVariantService {

    private final ProductVariantRepository productVariantRepository;
    private final ProductRepository productRepository;

    @Transactional
    public UUID createVariant(
            UUID productId,
            String sku,
            String variantName,
            BigDecimal listPrice,
            BigDecimal salePrice,
            int quantityOnHand,
            int reorderLevel,
            BigDecimal weightGram) {

        if (!productRepository.existsById(productId)) {
            throw new IllegalArgumentException("Product not found with ID: " + productId);
        }
        if (productVariantRepository.existsBySku(sku)) {
            throw new IllegalArgumentException("SKU already exists: " + sku);
        }

        ProductVariant variant = ProductVariant.builder()
                .productId(productId)
                .sku(sku)
                .variantName(variantName)
                .listPrice(listPrice)
                .salePrice(salePrice)
                .quantityOnHand(quantityOnHand)
                .quantityReserved(0)
                .reorderLevel(reorderLevel)
                .weightGram(weightGram)
                .isActive(true)
                .build();

        return productVariantRepository.save(variant).getId();
    }

    @Transactional(readOnly = true)
    public Optional<ProductVariant> findById(UUID variantId) {
        return productVariantRepository.findById(variantId);
    }

    @Transactional(readOnly = true)
    public Optional<ProductVariant> findBySku(String sku) {
        return productVariantRepository.findBySku(sku);
    }

    @Transactional(readOnly = true)
    public List<ProductVariant> getVariantsByProductId(UUID productId) {
        return productVariantRepository.findByProductIdAndIsActiveTrue(productId);
    }

    @Transactional(readOnly = true)
    public Optional<BigDecimal> getSalePrice(UUID variantId) {
        return productVariantRepository.findSalePriceById(variantId);
    }

    @Transactional(readOnly = true)
    public int getAvailableQuantity(UUID variantId) {
        return productVariantRepository.findAvailableQuantityById(variantId).orElse(0);
    }

    @Transactional
    public boolean reserveStock(UUID variantId, int quantity) {
        int rows = productVariantRepository.reserveStock(variantId, quantity);
        return rows > 0;
    }

    @Transactional
    public void releaseStock(UUID variantId, int quantity) {
        productVariantRepository.releaseStock(variantId, quantity);
    }

    @Transactional
    public void deductStockOnFulfillment(UUID variantId, int quantity) {
        productVariantRepository.deductStockOnFulfillment(variantId, quantity);
    }

    @Transactional
    public void addStock(UUID variantId, int quantity) {
        productVariantRepository.addStock(variantId, quantity);
    }

    @Transactional
    public void updateSalePrice(UUID variantId, BigDecimal salePrice) {
        productVariantRepository.updateSalePrice(variantId, salePrice);
    }
}
