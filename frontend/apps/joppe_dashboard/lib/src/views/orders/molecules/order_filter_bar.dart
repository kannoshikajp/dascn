import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/order_status_badge.dart';

/// Molecule: Order search bar with a toggle button before the reset button
/// to show or hide the multi-toggle pill filter options.
class OrderFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final Set<String> selectedStatuses;
  final Set<String> selectedPaymentStatuses;
  final List<String> orderStatuses;
  final List<String> paymentStatuses;
  final ValueChanged<String> onToggleStatus;
  final ValueChanged<String> onTogglePaymentStatus;
  final VoidCallback onFilter;
  final VoidCallback onReset;
  final bool initialShowOptions;

  const OrderFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatuses,
    required this.selectedPaymentStatuses,
    required this.orderStatuses,
    required this.paymentStatuses,
    required this.onToggleStatus,
    required this.onTogglePaymentStatus,
    required this.onFilter,
    required this.onReset,
    this.initialShowOptions = true,
  });

  @override
  State<OrderFilterBar> createState() => _OrderFilterBarState();
}

class _OrderFilterBarState extends State<OrderFilterBar> {
  late bool _showFilterOptions;

  @override
  void initState() {
    super.initState();
    _showFilterOptions = widget.initialShowOptions;
  }

  Widget _buildPill({
    required BuildContext context,
    required String code,
    required bool isSelected,
    required Color color,
    required String label,
    required VoidCallback onToggle,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != 'ALL') ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onToggle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color : cs.outlineVariant.withAlpha(80),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: color.withAlpha(35),
        showCheckmark: isSelected && code != 'ALL',
        checkmarkColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final activeFilterCount = widget.selectedStatuses.length + widget.selectedPaymentStatuses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchOrdersHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.searchController.clear();
                            widget.onFilter();
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                ),
                onSubmitted: (_) => widget.onFilter(),
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            // Button before Reset: Toggles showing or hiding filter options
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() => _showFilterOptions = !_showFilterOptions);
              },
              icon: Icon(
                _showFilterOptions ? Icons.filter_list_off : Icons.filter_list,
                size: 18,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.filterButton),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              style: _showFilterOptions
                  ? FilledButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: JoppeSpacing.sm),
            // Reset filters button
            IconButton.filledTonal(
              onPressed: widget.onReset,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.resetFiltersTooltip,
            ),
          ],
        ),
        if (_showFilterOptions) ...[
          const SizedBox(height: JoppeSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  l10n.orderStatusFilterLabel,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                for (final st in widget.orderStatuses)
                  _buildPill(
                    context: context,
                    code: st,
                    isSelected: (st == 'ALL' && widget.selectedStatuses.isEmpty) || widget.selectedStatuses.contains(st),
                    color: st == 'ALL' ? cs.primary : OrderStatusBadge.getStatusColor(st, cs),
                    label: l10n.orderStatusLabel(st),
                    onToggle: () => widget.onToggleStatus(st),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  l10n.paymentStatusFilterLabel,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                for (final pst in widget.paymentStatuses)
                  _buildPill(
                    context: context,
                    code: pst,
                    isSelected: (pst == 'ALL' && widget.selectedPaymentStatuses.isEmpty) || widget.selectedPaymentStatuses.contains(pst),
                    color: pst == 'ALL' ? cs.primary : OrderStatusBadge.getPaymentColor(pst, cs),
                    label: l10n.paymentStatusLabel(pst),
                    onToggle: () => widget.onTogglePaymentStatus(pst),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
