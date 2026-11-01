package joppe.backend.domain.inventory;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.catalog.ProductVariantService;
import joppe.backend.domain.inventory.dto.CreateReceiptItemInput;
import joppe.backend.domain.inventory.dto.CreateReceiptRequest;
import joppe.backend.domain.inventory.dto.ReceiptDetailResponse;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderItem;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class GoodReceiptServiceTest {

    @Mock
    private GoodReceiptRepository goodReceiptRepository;

    @Mock
    private GoodItemRepository goodItemRepository;

    @Mock
    private SupplierRepository supplierRepository;

    @Mock
    private ProductVariantService productVariantService;

    @Mock
    private ProductVariantRepository productVariantRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private OrderRepository orderRepository;

    private GoodReceiptService goodReceiptService;

    @BeforeEach
    void setUp() {
        goodReceiptService = new GoodReceiptService(
                goodReceiptRepository,
                goodItemRepository,
                supplierRepository,
                productVariantService,
                productVariantRepository,
                productRepository,
                userRepository,
                orderRepository
        );
    }

    @Test
    void createAndProcessReceipt_completeImmediately_incrementsStock() {
        UUID staffId = UUID.randomUUID();
        UUID supplierId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();

        CreateReceiptRequest request = new CreateReceiptRequest(
                supplierId,
                "REC-TEST-001",
                true,
                List.of(new CreateReceiptItemInput(variantId, 10, BigDecimal.valueOf(15000000)))
        );

        Supplier supplier = Supplier.builder().id(supplierId).supplierName("MSI Distro").build();
        ProductVariant variant = ProductVariant.builder().id(variantId).productId(productId).sku("GPU-MSI").variantName("V1").build();
        Product product = Product.builder().id(productId).productName("MSI GPU").build();
        User staff = User.builder().id(staffId).fullName("Staff Member").build();

        when(supplierRepository.findById(supplierId)).thenReturn(Optional.of(supplier));
        when(goodReceiptRepository.existsByReceiptCode("REC-TEST-001")).thenReturn(false);
        when(productVariantRepository.findAllById(any())).thenReturn(List.of(variant));
        when(productRepository.findAllById(any())).thenReturn(List.of(product));
        when(userRepository.findById(staffId)).thenReturn(Optional.of(staff));

        GoodReceipt savedReceipt = GoodReceipt.builder()
                .id(UUID.randomUUID())
                .receiptCode("REC-TEST-001")
                .supplierId(supplierId)
                .staffId(staffId)
                .status("COMPLETED")
                .totalAmount(BigDecimal.valueOf(150000000))
                .build();

        when(goodReceiptRepository.save(any(GoodReceipt.class))).thenReturn(savedReceipt);

        GoodItem savedItem = GoodItem.builder()
                .id(UUID.randomUUID())
                .receiptId(savedReceipt.getId())
                .variantId(variantId)
                .quantity(10)
                .importPrice(BigDecimal.valueOf(15000000))
                .build();

        when(goodItemRepository.save(any(GoodItem.class))).thenReturn(savedItem);

        ReceiptDetailResponse res = goodReceiptService.createAndProcessReceipt(staffId, request);

        assertNotNull(res);
        assertEquals("COMPLETED", res.status());
        verify(productVariantService).addStock(variantId, 10);
    }

    @Test
    void listReceipts_withNullAndNonNullSearch_formatsPatternCorrectly() {
        when(goodReceiptRepository.findFiltered(null, null, null, null)).thenReturn(List.of());
        var res1 = goodReceiptService.listReceipts(null, null, null);
        assertNotNull(res1);
        verify(goodReceiptRepository).findFiltered(null, null, null, null);

        when(goodReceiptRepository.findFiltered(null, "COMPLETED", null, "%rec-123%")).thenReturn(List.of());
        var res2 = goodReceiptService.listReceipts("COMPLETED", null, " REC-123 ");
        assertNotNull(res2);
        verify(goodReceiptRepository).findFiltered(null, "COMPLETED", null, "%rec-123%");
    }

    @Test
    void createAutoOutboundForOrder_createsOutboundReceiptWithItems() {
        UUID orderId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();

        Order order = Order.builder()
                .id(orderId)
                .orderCode("ORD-20261101-ABCDE")
                .userId(staffId)
                .build();

        OrderItem item = OrderItem.builder()
                .variantId(variantId)
                .quantity(2)
                .unitPrice(BigDecimal.valueOf(10000000))
                .build();

        when(goodReceiptRepository.existsByOrderId(orderId)).thenReturn(false);
        when(goodReceiptRepository.existsByReceiptCode(any())).thenReturn(false);
        when(goodReceiptRepository.save(any(GoodReceipt.class))).thenAnswer(inv -> inv.getArgument(0));

        GoodReceipt res = goodReceiptService.createAutoOutboundForOrder(order, List.of(item), staffId);

        assertNotNull(res);
        assertEquals("OUTBOUND", res.getReceiptType());
        assertEquals("COMPLETED", res.getStatus());
        assertEquals(orderId, res.getOrderId());
        verify(goodItemRepository).save(any(GoodItem.class));
    }
}
