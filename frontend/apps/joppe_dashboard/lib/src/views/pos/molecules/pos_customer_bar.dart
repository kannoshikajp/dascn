import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Molecule: POS Cashier customer selector (Walk-in guest vs Registered member).
class PosCustomerBar extends StatelessWidget {
  final bool isWalkIn;
  final ValueChanged<bool> onWalkInChanged;
  final List<UserSummary> customers;
  final UserSummary? selectedCustomer;
  final ValueChanged<UserSummary?> onCustomerSelected;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const PosCustomerBar({
    super.key,
    required this.isWalkIn,
    required this.onWalkInChanged,
    required this.customers,
    required this.selectedCustomer,
    required this.onCustomerSelected,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(JoppeSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: JoppeSpacing.xs),
              Expanded(
                child: Text(
                  'Thông tin khách mua',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: JoppeSpacing.xs),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                segments: const [
                  ButtonSegment(value: true, label: Text('Khách lẻ', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: false, label: Text('Thành viên', style: TextStyle(fontSize: 11))),
                ],
                selected: {isWalkIn},
                onSelectionChanged: (s) => onWalkInChanged(s.first),
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.xs),
          if (isWalkIn)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên khách mua',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            )
          else
            DropdownButtonFormField<UserSummary>(
              initialValue: selectedCustomer,
              decoration: const InputDecoration(
                labelText: 'Chọn tài khoản thành viên',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
              items: customers.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.fullName} (${c.phoneNumber ?? c.email})',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                  ),
                );
              }).toList(),
              onChanged: onCustomerSelected,
            ),
        ],
      ),
    );
  }
}
