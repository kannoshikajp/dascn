package joppe.backend.domain.cart;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.cart.dto.AddToCartRequest;
import joppe.backend.domain.cart.dto.CartResponse;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CartServiceTest {

    @Mock
    private CartItemRepository cartItemRepository;

    @Mock
    private ProductVariantRepository productVariantRepository;

    @Mock
    private ProductRepository productRepository;

    private CartService cartService;

    @BeforeEach
    void setUp() {
        cartService = new CartService(cartItemRepository, productVariantRepository, productRepository);
    }

    @Test
    void addItemToCart_outOfStock_throwsException() {
        UUID userId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        AddToCartRequest req = new AddToCartRequest(variantId, 2);

        ProductVariant variant = ProductVariant.builder()
                .id(variantId)
                .quantityOnHand(1)
                .quantityReserved(1) // available 0
                .isActive(true)
                .build();

        when(productVariantRepository.findById(variantId)).thenReturn(Optional.of(variant));

        assertThrows(IllegalArgumentException.class, () -> cartService.addItemToCart(userId, req));
    }

    @Test
    void addItemToCart_validStock_savesCartItem() {
        UUID userId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();
        AddToCartRequest req = new AddToCartRequest(variantId, 2);

        ProductVariant variant = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .sku("SKU-100")
                .variantName("Variant A")
                .quantityOnHand(10)
                .quantityReserved(0)
                .salePrice(BigDecimal.valueOf(100))
                .listPrice(BigDecimal.valueOf(120))
                .isActive(true)
                .build();

        Product product = Product.builder()
                .id(productId)
                .productName("Sample PC")
                .slug("sample-pc")
                .isActive(true)
                .build();

        when(productVariantRepository.findById(variantId)).thenReturn(Optional.of(variant));
        when(cartItemRepository.findByUserIdAndVariantId(userId, variantId)).thenReturn(Optional.empty());

        CartItem savedItem = CartItem.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .variantId(variantId)
                .quantity(2)
                .build();

        when(cartItemRepository.findByUserId(userId)).thenReturn(List.of(savedItem));
        when(productVariantRepository.findAllById(any())).thenReturn(List.of(variant));
        when(productRepository.findAllById(any())).thenReturn(List.of(product));

        CartResponse res = cartService.addItemToCart(userId, req);

        assertNotNull(res);
        assertEquals(1, res.items().size());
        assertEquals(2, res.totalItems());
        assertEquals(BigDecimal.valueOf(200), res.subtotalAmount());
        verify(cartItemRepository).save(any(CartItem.class));
    }
}
