package joppe.backend.domain.inventory;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.inventory.dto.SupplierRequest;
import joppe.backend.domain.inventory.dto.SupplierResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class SupplierServiceTest {

    @Mock
    private SupplierRepository supplierRepository;

    @Mock
    private GoodReceiptRepository goodReceiptRepository;

    private SupplierService supplierService;

    @BeforeEach
    void setUp() {
        supplierService = new SupplierService(supplierRepository, goodReceiptRepository);
    }

    @Test
    void createSupplier_validName_savesAndReturns() {
        SupplierRequest req = new SupplierRequest(
                "ASUS Vietnam",
                "Nguyen Van Rep",
                "0909123456",
                "contact@asus.vn",
                "HCMC",
                true
        );

        when(supplierRepository.existsBySupplierName("ASUS Vietnam")).thenReturn(false);

        Supplier saved = Supplier.builder()
                .id(UUID.randomUUID())
                .supplierName(req.supplierName())
                .contactPerson(req.contactPerson())
                .phoneNumber(req.phoneNumber())
                .email(req.email())
                .address(req.address())
                .isActive(true)
                .build();

        when(supplierRepository.save(any(Supplier.class))).thenReturn(saved);

        SupplierResponse res = supplierService.createSupplier(req);

        assertNotNull(res);
        assertEquals("ASUS Vietnam", res.supplierName());
        verify(supplierRepository).save(any(Supplier.class));
    }

    @Test
    void createSupplier_duplicateName_throwsException() {
        SupplierRequest req = new SupplierRequest("ASUS Vietnam", null, null, null, null, true);
        when(supplierRepository.existsBySupplierName("ASUS Vietnam")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> supplierService.createSupplier(req));
    }

    @Test
    void listSuppliers_withNullAndNonNullSearch_formatsPatternCorrectly() {
        when(supplierRepository.findFiltered(null, null)).thenReturn(List.of());
        var res1 = supplierService.listSuppliers(null, null);
        assertNotNull(res1);
        verify(supplierRepository).findFiltered(null, null);

        when(supplierRepository.findFiltered(true, "%intel%")).thenReturn(List.of());
        var res2 = supplierService.listSuppliers(true, " INTEL ");
        assertNotNull(res2);
        verify(supplierRepository).findFiltered(true, "%intel%");
    }
}
