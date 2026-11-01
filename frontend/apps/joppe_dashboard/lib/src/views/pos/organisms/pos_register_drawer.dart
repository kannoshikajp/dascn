import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../atoms/pos_cart_item_row.dart';
import '../models/pos_cart_item.dart';
import '../molecules/pos_checkout_panel.dart';
import '../molecules/pos_customer_bar.dart';

/// Organism: POS Cashier register cart displaying live line items, customer info, and total payable panel.
class PosRegisterDrawer extends StatelessWidget {
  final List<PosCartItem> cartItems;
  final ValueChanged<PosCartItem> onItemQuantityChanged;
  final ValueChanged<PosCartItem> onItemRemoved;
  final VoidCallback onClearCart;

  final bool isWalkIn;
  final ValueChanged<bool> onWalkInChanged;
  final List<UserSummary> customers;
  final UserSummary? selectedCustomer;
  final ValueChanged<UserSummary?> onCustomerSelected;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  final double subtotal;
  final double shippingFee;
  final PosPaymentMethod paymentMethod;
  final ValueChanged<PosPaymentMethod> onPaymentMethodChanged;
  final bool isCounterPickup;
  final ValueChanged<bool> onDeliveryPresetChanged;
  final VoidCallback onCheckout;
  final bool isSubmitting;

  const PosRegisterDrawer({
    super.key,
    required this.cartItems,
    required this.onItemQuantityChanged,
    required this.onItemRemoved,
    required this.onClearCart,
    required this.isWalkIn,
    required this.onWalkInChanged,
    required this.customers,
    required this.selectedCustomer,
    required this.onCustomerSelected,
    required this.nameController,
    required this.phoneController,
    required this.subtotal,
    required this.shippingFee,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.isCounterPickup,
    required this.onDeliveryPresetChanged,
    required this.onCheckout,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalUnits = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JoppeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Register Cart Header
            Row(
              children: [
                Icon(Icons.shopping_cart_checkout_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hóa đơn thu ngân',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: JoppeSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalUnits món',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClearCart,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Xóa giỏ', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.sm),

            // Customer Selector Molecule
            PosCustomerBar(
              isWalkIn: isWalkIn,
              onWalkInChanged: onWalkInChanged,
              customers: customers,
              selectedCustomer: selectedCustomer,
              onCustomerSelected: onCustomerSelected,
              nameController: nameController,
              phoneController: phoneController,
            ),
            const SizedBox(height: JoppeSpacing.sm),

            // Cart Items List
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 44, color: colorScheme.outline.withAlpha(120)),
                          const SizedBox(height: JoppeSpacing.xs),
                          Text(
                            'Giỏ hàng trống',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chọn sản phẩm từ danh mục bên trái để tính tiền',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, idx) {
                        final item = cartItems[idx];
                        return PosCartItemRow(
                          item: item,
                          onQuantityChanged: (qty) => onItemQuantityChanged(item..quantity = qty),
                          onRemove: () => onItemRemoved(item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: JoppeSpacing.sm),

            // Checkout Summary Molecule with prominent "Total Money to Pay" display
            PosCheckoutPanel(
              subtotal: subtotal,
              shippingFee: shippingFee,
              paymentMethod: paymentMethod,
              onPaymentMethodChanged: onPaymentMethodChanged,
              isCounterPickup: isCounterPickup,
              onDeliveryPresetChanged: onDeliveryPresetChanged,
              onCheckout: onCheckout,
              isSubmitting: isSubmitting,
              totalItems: totalUnits,
            ),
          ],
        ),
      ),
    );
  }
}
