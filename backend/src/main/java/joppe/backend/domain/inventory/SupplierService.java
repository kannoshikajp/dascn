package joppe.backend.domain.inventory;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.inventory.dto.SupplierRequest;
import joppe.backend.domain.inventory.dto.SupplierResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final SupplierRepository supplierRepository;
    private final GoodReceiptRepository goodReceiptRepository;

    @Transactional(readOnly = true)
    public List<SupplierResponse> listSuppliers(Boolean isActive, String search) {
        String searchPattern = (search != null && !search.isBlank()) ? ("%" + search.trim().toLowerCase() + "%") : null;
        return supplierRepository.findFiltered(isActive, searchPattern).stream()
                .map(SupplierResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public SupplierResponse getSupplierById(UUID id) {
        return supplierRepository.findById(id)
                .map(SupplierResponse::fromEntity)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with ID: " + id));
    }

    @Transactional
    public SupplierResponse createSupplier(SupplierRequest request) {
        String name = request.supplierName().trim();
        if (supplierRepository.existsBySupplierName(name)) {
            throw new IllegalArgumentException("Supplier already exists with name: " + name);
        }

        Supplier supplier = Supplier.builder()
                .supplierName(name)
                .contactPerson(request.contactPerson() != null ? request.contactPerson().trim() : null)
                .phoneNumber(request.phoneNumber() != null ? request.phoneNumber().trim() : null)
                .email(request.email() != null ? request.email().trim() : null)
                .address(request.address() != null ? request.address().trim() : null)
                .isActive(request.isActive() != null ? request.isActive() : true)
                .build();

        return SupplierResponse.fromEntity(supplierRepository.save(supplier));
    }

    @Transactional
    public SupplierResponse updateSupplier(UUID id, SupplierRequest request) {
        Supplier supplier = supplierRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with ID: " + id));

        String name = request.supplierName().trim();
        if (supplierRepository.existsBySupplierNameAndIdNot(name, id)) {
            throw new IllegalArgumentException("Supplier name already in use by another supplier: " + name);
        }

        supplier.setSupplierName(name);
        supplier.setContactPerson(request.contactPerson() != null ? request.contactPerson().trim() : null);
        supplier.setPhoneNumber(request.phoneNumber() != null ? request.phoneNumber().trim() : null);
        supplier.setEmail(request.email() != null ? request.email().trim() : null);
        supplier.setAddress(request.address() != null ? request.address().trim() : null);
        if (request.isActive() != null) {
            supplier.setIsActive(request.isActive());
        }

        return SupplierResponse.fromEntity(supplierRepository.save(supplier));
    }

    @Transactional
    public void updateActiveStatus(UUID supplierId, boolean isActive) {
        supplierRepository.updateActiveStatus(supplierId, isActive);
    }

    @Transactional
    public void deleteSupplier(UUID supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with ID: " + supplierId));

        List<GoodReceipt> receipts = goodReceiptRepository.findBySupplierId(supplierId);
        if (!receipts.isEmpty()) {
            supplier.setIsActive(false);
            supplierRepository.save(supplier);
        } else {
            supplierRepository.delete(supplier);
        }
    }

    // Legacy method for backwards compatibility
    @Transactional
    public UUID createSupplier(
            String supplierName,
            String contactPerson,
            String phoneNumber,
            String email,
            String address) {

        SupplierRequest request = new SupplierRequest(
                supplierName,
                contactPerson,
                phoneNumber,
                email,
                address,
                true
        );
        return createSupplier(request).id();
    }

    @Transactional(readOnly = true)
    public Optional<Supplier> findById(UUID supplierId) {
        return supplierRepository.findById(supplierId);
    }

    @Transactional(readOnly = true)
    public List<Supplier> getActiveSuppliers() {
        return supplierRepository.findByIsActiveTrue();
    }
}
