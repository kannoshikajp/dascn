package joppe.backend.domain.inventory;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final SupplierRepository supplierRepository;

    @Transactional
    public UUID createSupplier(
            String supplierName,
            String contactPerson,
            String phoneNumber,
            String email,
            String address) {

        if (supplierRepository.existsBySupplierName(supplierName)) {
            throw new IllegalArgumentException("Supplier name already exists: " + supplierName);
        }

        Supplier supplier = Supplier.builder()
                .supplierName(supplierName)
                .contactPerson(contactPerson)
                .phoneNumber(phoneNumber)
                .email(email)
                .address(address)
                .isActive(true)
                .build();

        return supplierRepository.save(supplier).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Supplier> findById(UUID supplierId) {
        return supplierRepository.findById(supplierId);
    }

    @Transactional(readOnly = true)
    public List<Supplier> getActiveSuppliers() {
        return supplierRepository.findByIsActiveTrue();
    }

    @Transactional
    public void updateActiveStatus(UUID supplierId, boolean isActive) {
        supplierRepository.updateActiveStatus(supplierId, isActive);
    }
}
