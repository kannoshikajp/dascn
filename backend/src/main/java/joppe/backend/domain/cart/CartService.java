package joppe.backend.domain.cart;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartItemRepository cartItemRepository;

    @Transactional
    public UUID addItem(UUID userId, UUID variantId, int quantity) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Quantity must be greater than zero");
        }

        Optional<CartItem> existing = cartItemRepository.findByUserIdAndVariantId(userId, variantId);
        if (existing.isPresent()) {
            cartItemRepository.addQuantity(userId, variantId, quantity);
            return existing.get().getId();
        }

        CartItem item = CartItem.builder()
                .userId(userId)
                .variantId(variantId)
                .quantity(quantity)
                .build();

        return cartItemRepository.save(item).getId();
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
