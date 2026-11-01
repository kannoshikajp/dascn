package joppe.backend.domain.order;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.admin.dto.CreateAdminOrderRequest;
import joppe.backend.domain.cart.CartItemRepository;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.catalog.ProductVariantService;
import joppe.backend.domain.order.dto.CheckoutItemInput;
import joppe.backend.domain.order.dto.CheckoutRequest;
import joppe.backend.domain.order.dto.OrderResponse;
import joppe.backend.domain.inventory.GoodReceiptService;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderItemRepository orderItemRepository;

    @Mock
    private ProductVariantService productVariantService;

    @Mock
    private ProductVariantRepository productVariantRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private CartItemRepository cartItemRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private GoodReceiptService goodReceiptService;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(
                orderRepository,
                orderItemRepository,
                productVariantService,
                productVariantRepository,
                productRepository,
                cartItemRepository,
                userRepository,
                roleRepository,
                passwordEncoder,
                goodReceiptService
        );
    }

    @Test
    void checkout_validStock_reservesStockAndCreatesOrder() {
        UUID userId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();

        CheckoutRequest request = new CheckoutRequest(
                "Recipient",
                "0987654321",
                "123 Delivery Way",
                "Leave at door",
                BigDecimal.valueOf(30),
                List.of(new CheckoutItemInput(variantId, 2))
        );

        ProductVariant variant = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .sku("SKU-99")
                .variantName("V99")
                .salePrice(BigDecimal.valueOf(100))
                .quantityOnHand(5)
                .quantityReserved(0)
                .isActive(true)
                .build();

        Product product = Product.builder()
                .id(productId)
                .productName("Gaming Rig")
                .slug("gaming-rig")
                .build();

        when(productVariantRepository.findAllById(any())).thenReturn(List.of(variant));
        when(productRepository.findAllById(any())).thenReturn(List.of(product));
        when(orderRepository.existsByOrderCode(any())).thenReturn(false);
        when(productVariantService.reserveStock(variantId, 2)).thenReturn(true);

        Order savedOrder = Order.builder()
                .id(UUID.randomUUID())
                .orderCode("ORD-20261022-ABCDE")
                .userId(userId)
                .orderChannel("ONLINE")
                .orderStatus("ACCEPTED")
                .paymentStatus("PAID")
                .recipientName(request.recipientName())
                .recipientPhone(request.recipientPhone())
                .shippingAddress(request.shippingAddress())
                .subtotalAmount(BigDecimal.valueOf(200))
                .shippingFee(BigDecimal.valueOf(30))
                .finalAmount(BigDecimal.valueOf(230))
                .build();

        when(orderRepository.save(any(Order.class))).thenReturn(savedOrder);

        OrderItem savedItem = OrderItem.builder()
                .id(UUID.randomUUID())
                .orderId(savedOrder.getId())
                .variantId(variantId)
                .skuSnapshot(variant.getSku())
                .productNameSnapshot(product.getProductName())
                .variantNameSnapshot(variant.getVariantName())
                .quantity(2)
                .unitPrice(BigDecimal.valueOf(100))
                .subtotal(BigDecimal.valueOf(200))
                .warrantyMonthsSnapshot(12)
                .build();

        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(savedItem);

        OrderResponse res = orderService.checkout(userId, request);

        assertNotNull(res);
        assertEquals("ACCEPTED", res.orderStatus());
        assertEquals("PAID", res.paymentStatus());
        verify(productVariantService).reserveStock(variantId, 2);
        verify(cartItemRepository).deleteByUserIdAndVariantId(userId, variantId);
    }

    @Test
    void cancelOrder_accepted_releasesStockAndRefunds() {
        UUID userId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();

        Order order = Order.builder()
                .id(orderId)
                .userId(userId)
                .orderStatus("ACCEPTED")
                .paymentStatus("PAID")
                .createdAt(java.time.OffsetDateTime.now())
                .build();

        OrderItem item = OrderItem.builder()
                .id(UUID.randomUUID())
                .orderId(orderId)
                .variantId(variantId)
                .quantity(3)
                .build();

        when(orderRepository.findByIdAndUserId(orderId, userId)).thenReturn(Optional.of(order));
        when(orderItemRepository.findByOrderId(orderId)).thenReturn(List.of(item));
        when(productVariantRepository.findAllById(any())).thenReturn(List.of());

        OrderResponse res = orderService.cancelOrder(userId, orderId);

        assertNotNull(res);
        assertEquals("REFUND", res.orderStatus());
        assertEquals("REFUND", res.paymentStatus());
        verify(productVariantService).releaseStock(variantId, 3);
        verify(orderRepository).save(order);
    }

    @Test
    void cancelOrder_shipped_throwsException() {
        UUID userId = UUID.randomUUID();
        UUID orderId = UUID.randomUUID();

        Order order = Order.builder()
                .id(orderId)
                .userId(userId)
                .orderStatus("SHIPPED")
                .build();

        when(orderRepository.findByIdAndUserId(orderId, userId)).thenReturn(Optional.of(order));

        assertThrows(IllegalStateException.class, () -> orderService.cancelOrder(userId, orderId));
    }

    @Test
    void createAdminOrder_walkInCustomer_autoCreatesGuestAndPlacesShowroomOrder() {
        UUID staffId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();

        CreateAdminOrderRequest request = new CreateAdminOrderRequest(
                null,
                "walkin@test.vn",
                "Walk-in Customer",
                "0988776655",
                "Store Counter Pickup",
                "Paid cash",
                BigDecimal.ZERO,
                "DELIVERED",
                "PAID",
                List.of(new CheckoutItemInput(variantId, 1))
        );

        ProductVariant variant = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .sku("SKU-POS")
                .variantName("POS Spec")
                .salePrice(BigDecimal.valueOf(500))
                .quantityOnHand(10)
                .quantityReserved(0)
                .isActive(true)
                .build();

        Product product = Product.builder()
                .id(productId)
                .productName("Keyboard")
                .slug("keyboard")
                .build();

        Role customerRole = Role.builder().id(3).roleName("ROLE_CUSTOMER").build();
        User guestUser = User.builder().id(UUID.randomUUID()).email("walkin@test.vn").roleId(3).build();

        when(userRepository.findByPhoneNumber("0988776655")).thenReturn(Optional.empty());
        when(userRepository.findByEmail("walkin@test.vn")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("ROLE_CUSTOMER")).thenReturn(Optional.of(customerRole));
        when(passwordEncoder.encode(any())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenReturn(guestUser);

        when(productVariantRepository.findAllById(any())).thenReturn(List.of(variant));
        when(productRepository.findAllById(any())).thenReturn(List.of(product));
        when(orderRepository.existsByOrderCode(any())).thenReturn(false);
        when(productVariantService.reserveStock(variantId, 1)).thenReturn(true);

        Order savedOrder = Order.builder()
                .id(UUID.randomUUID())
                .orderCode("ORD-20261022-POS01")
                .userId(guestUser.getId())
                .orderChannel("SHOWROOM")
                .orderStatus("SHOWROOM_BUY")
                .paymentStatus("PAID")
                .recipientName(request.recipientName())
                .recipientPhone(request.recipientPhone())
                .shippingAddress(request.shippingAddress())
                .subtotalAmount(BigDecimal.valueOf(500))
                .finalAmount(BigDecimal.valueOf(500))
                .build();

        when(orderRepository.save(any(Order.class))).thenReturn(savedOrder);

        OrderItem savedItem = OrderItem.builder()
                .id(UUID.randomUUID())
                .orderId(savedOrder.getId())
                .variantId(variantId)
                .skuSnapshot(variant.getSku())
                .productNameSnapshot(product.getProductName())
                .variantNameSnapshot(variant.getVariantName())
                .quantity(1)
                .unitPrice(BigDecimal.valueOf(500))
                .subtotal(BigDecimal.valueOf(500))
                .warrantyMonthsSnapshot(12)
                .build();

        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(savedItem);

        OrderResponse res = orderService.createAdminOrder(staffId, request);

        assertNotNull(res);
        assertEquals("SHOWROOM_BUY", res.orderStatus());
        assertEquals("PAID", res.paymentStatus());
        verify(productVariantService).reserveStock(variantId, 1);
        verify(productVariantService).deductStockOnFulfillment(variantId, 1);
        verify(userRepository).save(any(User.class));
    }

    @Test
    void updateOrderStatus_sequentialTransition_succeeds() {
        UUID orderId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("ACCEPTED")
                .paymentStatus("PAID")
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(orderItemRepository.findByOrderId(orderId)).thenReturn(List.of());
        when(productVariantRepository.findAllById(any())).thenReturn(List.of());

        // Step 1: ACCEPTED -> PACKAGING
        OrderResponse res1 = orderService.updateOrderStatusByAdmin(orderId, "PACKAGING");
        assertEquals("PACKAGING", res1.orderStatus());

        // Step 2: PACKAGING -> DELIVERY
        OrderResponse res2 = orderService.updateOrderStatusByAdmin(orderId, "DELIVERY");
        assertEquals("DELIVERY", res2.orderStatus());

        // Step 3: DELIVERY -> SHIPPED
        OrderResponse res3 = orderService.updateOrderStatusByAdmin(orderId, "SHIPPED");
        assertEquals("SHIPPED", res3.orderStatus());
    }

    @Test
    void updateOrderStatus_skippingStep_throwsException() {
        UUID orderId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("ACCEPTED")
                .paymentStatus("PAID")
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        // Cannot skip directly from ACCEPTED to DELIVERY or SHIPPED
        assertThrows(IllegalStateException.class, () -> orderService.updateOrderStatusByAdmin(orderId, "DELIVERY"));
        assertThrows(IllegalStateException.class, () -> orderService.updateOrderStatusByAdmin(orderId, "SHIPPED"));
    }

    @Test
    void updateOrderStatus_backwardStep_throwsException() {
        UUID orderId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("DELIVERY")
                .paymentStatus("PAID")
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        // Cannot go backwards from DELIVERY to PACKAGING or ACCEPTED
        assertThrows(IllegalStateException.class, () -> orderService.updateOrderStatusByAdmin(orderId, "PACKAGING"));
        assertThrows(IllegalStateException.class, () -> orderService.updateOrderStatusByAdmin(orderId, "ACCEPTED"));
    }

    @Test
    void updatePaymentStatus_paidToUnpaid_throwsException() {
        UUID orderId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("ACCEPTED")
                .paymentStatus("PAID")
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        assertThrows(IllegalStateException.class, () -> orderService.updatePaymentStatusByAdmin(orderId, "UNPAID"));
    }

    @Test
    void refund_after10Days_throwsException() {
        UUID orderId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("SHIPPED")
                .paymentStatus("PAID")
                .deliveredAt(java.time.OffsetDateTime.now().minusDays(11))
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        assertThrows(IllegalStateException.class, () -> orderService.updateOrderStatusByAdmin(orderId, "REFUND"));
    }

    @Test
    void refund_within10Days_succeedsAndRestoresStock() {
        UUID orderId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        Order order = Order.builder()
                .id(orderId)
                .orderStatus("SHIPPED")
                .paymentStatus("PAID")
                .deliveredAt(java.time.OffsetDateTime.now().minusDays(2))
                .build();

        OrderItem item = OrderItem.builder()
                .id(UUID.randomUUID())
                .orderId(orderId)
                .variantId(variantId)
                .quantity(2)
                .build();

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(orderItemRepository.findByOrderId(orderId)).thenReturn(List.of(item));
        when(productVariantRepository.findAllById(any())).thenReturn(List.of());

        OrderResponse res = orderService.updateOrderStatusByAdmin(orderId, "REFUND");
        assertEquals("REFUND", res.orderStatus());
        assertEquals("REFUND", res.paymentStatus());
        verify(productVariantService).addStock(variantId, 2);
    }

    @Test
    void listAdminOrders_withNullSearch_passesNullPatternToRepository() {
        when(orderRepository.findFilteredOrders(null, null, null)).thenReturn(List.of());

        var result = orderService.listAdminOrders(null, null, null);

        assertNotNull(result);
        verify(orderRepository).findFilteredOrders(null, null, null);
    }

    @Test
    void listAdminOrders_withSearch_formatsSearchPatternForLikeQuery() {
        when(orderRepository.findFilteredOrders("PENDING", "UNPAID", "%ord-123%")).thenReturn(List.of());

        var result = orderService.listAdminOrders("PENDING", "UNPAID", " ORD-123 ");

        assertNotNull(result);
        verify(orderRepository).findFilteredOrders("PENDING", "UNPAID", "%ord-123%");
    }
}
