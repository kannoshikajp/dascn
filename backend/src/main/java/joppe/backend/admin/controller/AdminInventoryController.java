package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.domain.inventory.GoodReceiptService;
import joppe.backend.domain.inventory.SupplierService;
import joppe.backend.domain.inventory.dto.CreateReceiptRequest;
import joppe.backend.domain.inventory.dto.InventoryStockResponse;
import joppe.backend.domain.inventory.dto.ReceiptDetailResponse;
import joppe.backend.domain.inventory.dto.ReceiptSummaryResponse;
import joppe.backend.domain.inventory.dto.SupplierRequest;
import joppe.backend.domain.inventory.dto.SupplierResponse;
import joppe.backend.domain.inventory.dto.UpdateStockRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/inventory")
@RequiredArgsConstructor
@Tag(name = "Admin - Inventory & Suppliers", description = "Endpoints for managing hardware suppliers, purchase receipts, and warehouse inventory stock levels")
@PreAuthorize("hasAnyAuthority('INVENTORY_READ', 'INVENTORY_WRITE')")
public class AdminInventoryController {

    private final SupplierService supplierService;
    private final GoodReceiptService goodReceiptService;

    private UUID getStaffId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    // -------------------------------------------------------------------------
    // Suppliers Directory
    // -------------------------------------------------------------------------

    @GetMapping("/suppliers")
    @Operation(summary = "List suppliers with optional active status and search filter")
    public List<SupplierResponse> listSuppliers(
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) String search) {
        return supplierService.listSuppliers(isActive, search);
    }

    @GetMapping("/suppliers/{id}")
    @Operation(summary = "Get supplier details by ID")
    public SupplierResponse getSupplierById(@PathVariable UUID id) {
        return supplierService.getSupplierById(id);
    }

    @PostMapping("/suppliers")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Create a new hardware distributor / supplier")
    public ResponseEntity<SupplierResponse> createSupplier(@Valid @RequestBody SupplierRequest request) {
        SupplierResponse created = supplierService.createSupplier(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/suppliers/{id}")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Update supplier details")
    public SupplierResponse updateSupplier(
            @PathVariable UUID id,
            @Valid @RequestBody SupplierRequest request) {
        return supplierService.updateSupplier(id, request);
    }

    @PatchMapping("/suppliers/{id}/status")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Toggle supplier active status")
    public ResponseEntity<Void> toggleSupplierStatus(
            @PathVariable UUID id,
            @RequestParam boolean isActive) {
        supplierService.updateActiveStatus(id, isActive);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/suppliers/{id}")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Delete or deactivate supplier")
    public ResponseEntity<Void> deleteSupplier(@PathVariable UUID id) {
        supplierService.deleteSupplier(id);
        return ResponseEntity.noContent().build();
    }

    // -------------------------------------------------------------------------
    // Goods Receipts (Inbound Inventory Batch Import)
    // -------------------------------------------------------------------------

    @GetMapping("/receipts")
    @Operation(summary = "List goods receipts with optional receiptType (INBOUND/OUTBOUND), status, supplier, and search filter")
    public List<ReceiptSummaryResponse> listReceipts(
            @RequestParam(required = false) String receiptType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) UUID supplierId,
            @RequestParam(required = false) String search) {
        return goodReceiptService.listReceipts(receiptType, status, supplierId, search);
    }

    @GetMapping("/receipts/{id}")
    @Operation(summary = "Get goods receipt detail including imported variant line items")
    public ReceiptDetailResponse getReceiptById(@PathVariable UUID id) {
        return goodReceiptService.getReceiptDetail(id);
    }

    @PostMapping("/receipts")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Create an inbound goods receipt draft or finalize batch immediately with stock increment")
    public ResponseEntity<ReceiptDetailResponse> createReceipt(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateReceiptRequest request) {
        ReceiptDetailResponse created = goodReceiptService.createAndProcessReceipt(getStaffId(jwt), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PostMapping("/receipts/{id}/complete")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Finalize DRAFT receipt and increment physical warehouse stock levels")
    public ReceiptDetailResponse completeReceipt(@PathVariable UUID id) {
        return goodReceiptService.completeReceipt(id);
    }

    // -------------------------------------------------------------------------
    // Warehouse Inventory Stock Levels & Low Stock Audits
    // -------------------------------------------------------------------------

    @GetMapping("/stock")
    @Operation(summary = "List warehouse stock across all hardware variants with low stock filter")
    public List<InventoryStockResponse> listStock(
            @RequestParam(required = false) Boolean lowStockOnly,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer brandId) {
        return goodReceiptService.listInventoryStock(lowStockOnly, search, categoryId, brandId);
    }

    @PatchMapping("/stock/{variantId}")
    @PreAuthorize("hasAuthority('INVENTORY_WRITE')")
    @Operation(summary = "Manually adjust variant quantity on hand or reorder level threshold")
    public InventoryStockResponse adjustStock(
            @PathVariable UUID variantId,
            @Valid @RequestBody UpdateStockRequest request) {
        return goodReceiptService.updateStockLevel(variantId, request.quantityOnHand(), request.reorderLevel());
    }
}
