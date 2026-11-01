package joppe.backend.domain.cart;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import joppe.backend.domain.cart.dto.AddToCartRequest;
import joppe.backend.domain.cart.dto.CartItemResponse;
import joppe.backend.domain.cart.dto.CartResponse;
import joppe.backend.domain.cart.dto.MergeCartItemInput;
import joppe.backend.domain.cart.dto.MergeCartRequest;
import joppe.backend.domain.cart.dto.UpdateCartQuantityRequest;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final ProductVariantRepository productVariantRepository;
    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public CartResponse getCart(UUID userId) {
        List<CartItem> items = cartItemRepository.findByUserId(userId);
        if (items.isEmpty()) {
            return CartResponse.empty();
        }

        List<UUID> variantIds = items.stream().map(CartItem::getVariantId).distinct().toList();
        Map<UUID, ProductVariant> variantMap = productVariantRepository.findAllById(variantIds).stream()
                .collect(Collectors.toMap(ProductVariant::getId, Function.identity()));

        List<UUID> productIds = variantMap.values().stream().map(ProductVariant::getProductId).distinct().toList();
        Map<UUID, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));

        List<CartItemResponse> responseItems = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;
        int totalItemsCount = 0;

        for (CartItem item : items) {
            ProductVariant variant = variantMap.get(item.getVariantId());
            if (variant == null) {
                continue;
            }
            Product product = productMap.get(variant.getProductId());
            String productName = (product != null) ? product.getProductName() : "Unknown Product";
            String productSlug = (product != null) ? product.getSlug() : "";

            int onHand = variant.getQuantityOnHand() != null ? variant.getQuantityOnHand() : 0;
            int reserved = variant.getQuantityReserved() != null ? variant.getQuantityReserved() : 0;
            int stockAvailable = Math.max(0, onHand - reserved);

            BigDecimal unitPrice = (variant.getSalePrice() != null && variant.getSalePrice().compareTo(BigDecimal.ZERO) > 0)
                    ? variant.getSalePrice()
                    : (variant.getListPrice() != null ? variant.getListPrice() : BigDecimal.ZERO);

            BigDecimal itemTotal = unitPrice.multiply(BigDecimal.valueOf(item.getQuantity()));
            subtotal = subtotal.add(itemTotal);
            totalItemsCount += item.getQuantity();

            String vCode = variant.getSku();
            String compositeSlug = (productSlug.isBlank() || vCode == null || vCode.isBlank())
                    ? productSlug
                    : productSlug + "-" + vCode;

            responseItems.add(new CartItemResponse(
                    item.getId(),
                    variant.getId(),
                    variant.getProductId(),
                    productName,
                    variant.getVariantName(),
                    variant.getSku(),
                    variant.getSku(),
                    compositeSlug,
                    variant.getThumbnailUrl(),
                    unitPrice,
                    variant.getListPrice(),
                    item.getQuantity(),
                    stockAvailable,
                    itemTotal
            ));
        }

        return new CartResponse(responseItems, totalItemsCount, subtotal);
    }

    @Transactional
    public CartResponse addItemToCart(UUID userId, AddToCartRequest request) {
        ProductVariant variant = productVariantRepository.findById(request.variantId())
                .orElseThrow(() -> new IllegalArgumentException("Product variant not found: " + request.variantId()));

        if (Boolean.FALSE.equals(variant.getIsActive())) {
            throw new IllegalArgumentException("This product variant is currently not available for purchase");
        }

        int onHand = variant.getQuantityOnHand() != null ? variant.getQuantityOnHand() : 0;
        int reserved = variant.getQuantityReserved() != null ? variant.getQuantityReserved() : 0;
        int available = Math.max(0, onHand - reserved);

        if (available <= 0) {
            throw new IllegalArgumentException("This item is currently out of stock");
        }

        Optional<CartItem> existing = cartItemRepository.findByUserIdAndVariantId(userId, request.variantId());
        if (existing.isPresent()) {
            int newQuantity = existing.get().getQuantity() + request.quantity();
            if (newQuantity > available) {
                throw new IllegalArgumentException("Requested total (" + newQuantity + ") exceeds available stock (" + available + ")");
            }
            cartItemRepository.updateQuantity(existing.get().getId(), newQuantity);
        } else {
            if (request.quantity() > available) {
                throw new IllegalArgumentException("Requested quantity (" + request.quantity() + ") exceeds available stock (" + available + ")");
            }
            CartItem item = CartItem.builder()
                    .userId(userId)
                    .variantId(request.variantId())
                    .quantity(request.quantity())
                    .build();
            cartItemRepository.save(item);
        }

        return getCart(userId);
    }

    @Transactional
    public CartResponse updateItemQuantity(UUID userId, UUID cartItemId, UpdateCartQuantityRequest request) {
        CartItem item = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new IllegalArgumentException("Cart item not found: " + cartItemId));

        if (!item.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized to modify this cart item");
        }

        if (request.quantity() <= 0) {
            cartItemRepository.deleteById(cartItemId);
        } else {
            ProductVariant variant = productVariantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new IllegalArgumentException("Product variant not found"));

            int onHand = variant.getQuantityOnHand() != null ? variant.getQuantityOnHand() : 0;
            int reserved = variant.getQuantityReserved() != null ? variant.getQuantityReserved() : 0;
            int available = Math.max(0, onHand - reserved);

            if (request.quantity() > available) {
                throw new IllegalArgumentException("Requested quantity (" + request.quantity() + ") exceeds available stock (" + available + ")");
            }

            cartItemRepository.updateQuantity(cartItemId, request.quantity());
        }

        return getCart(userId);
    }

    @Transactional
    public CartResponse removeItemFromCart(UUID userId, UUID cartItemId) {
        CartItem item = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new IllegalArgumentException("Cart item not found: " + cartItemId));

        if (!item.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized to modify this cart item");
        }

        cartItemRepository.deleteById(cartItemId);
        return getCart(userId);
    }

    @Transactional
    public CartResponse clearUserCart(UUID userId) {
        cartItemRepository.deleteByUserId(userId);
        return CartResponse.empty();
    }

    @Transactional
    public CartResponse mergeCart(UUID userId, MergeCartRequest request) {
        if (request.items() == null || request.items().isEmpty()) {
            return getCart(userId);
        }

        for (MergeCartItemInput input : request.items()) {
            Optional<ProductVariant> variantOpt = productVariantRepository.findById(input.variantId());
            if (variantOpt.isEmpty() || Boolean.FALSE.equals(variantOpt.get().getIsActive())) {
                continue;
            }
            ProductVariant variant = variantOpt.get();
            int onHand = variant.getQuantityOnHand() != null ? variant.getQuantityOnHand() : 0;
            int reserved = variant.getQuantityReserved() != null ? variant.getQuantityReserved() : 0;
            int available = Math.max(0, onHand - reserved);
            if (available <= 0) {
                continue;
            }

            Optional<CartItem> existing = cartItemRepository.findByUserIdAndVariantId(userId, input.variantId());
            if (existing.isPresent()) {
                int combined = existing.get().getQuantity() + input.quantity();
                int finalQty = Math.min(combined, available);
                cartItemRepository.updateQuantity(existing.get().getId(), finalQty);
            } else {
                int finalQty = Math.min(input.quantity(), available);
                CartItem item = CartItem.builder()
                        .userId(userId)
                        .variantId(input.variantId())
                        .quantity(finalQty)
                        .build();
                cartItemRepository.save(item);
            }
        }

        return getCart(userId);
    }

    // -------------------------------------------------------------------------
    // Legacy helper methods
    // -------------------------------------------------------------------------

    @Transactional
    public UUID addItem(UUID userId, UUID variantId, int quantity) {
        AddToCartRequest request = new AddToCartRequest(variantId, quantity);
        addItemToCart(userId, request);
        return cartItemRepository.findByUserIdAndVariantId(userId, variantId)
                .map(CartItem::getId)
                .orElse(null);
    }

    @Transactional
    public void updateQuantity(UUID cartItemId, int quantity) {
        if (quantity <= 0) {
            cartItemRepository.deleteById(cartItemId);
        } else {
            cartItemRepository.updateQuantity(cartItemId, quantity);
        }
    }

    @Transactional
    public void removeItem(UUID cartItemId) {
        cartItemRepository.deleteById(cartItemId);
    }

    @Transactional
    public void removeVariant(UUID userId, UUID variantId) {
        cartItemRepository.deleteByUserIdAndVariantId(userId, variantId);
    }

    @Transactional
    public void clearCart(UUID userId) {
        cartItemRepository.deleteByUserId(userId);
    }

    @Transactional(readOnly = true)
    public List<CartItem> getCartItems(UUID userId) {
        return cartItemRepository.findByUserId(userId);
    }
}
