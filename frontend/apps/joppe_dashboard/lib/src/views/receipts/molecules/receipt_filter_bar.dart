import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

enum ReceiptTypeFilter {
  all,
  inbound,
  outbound;
}

enum ReceiptStatusFilter {
  all,
  completed,
  draft;
}

/// Molecule: Filter bar for stock receipts and movements with search query,
/// type pills (All, Inbound, Outbound), status pills (All, Completed, Draft),
/// clear, reset, and New Inbound Receipt trigger.
class ReceiptFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ReceiptTypeFilter selectedTypeFilter;
  final ReceiptStatusFilter selectedStatusFilter;
  final ValueChanged<ReceiptTypeFilter> onSelectType;
  final ValueChanged<ReceiptStatusFilter> onSelectStatus;
  final VoidCallback onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onNewReceipt;
  final int totalCount;
  final int inboundCount;
  final int outboundCount;
  final bool initialShowOptions;

  const ReceiptFilterBar({
    super.key,
    required this.searchController,
    required this.selectedTypeFilter,
    required this.selectedStatusFilter,
    required this.onSelectType,
    required this.onSelectStatus,
    required this.onSearchChanged,
    required this.onReset,
    required this.onNewReceipt,
    this.totalCount = 0,
    this.inboundCount = 0,
    this.outboundCount = 0,
    this.initialShowOptions = true,
  });

  @override
  State<ReceiptFilterBar> createState() => _ReceiptFilterBarState();
}

class _ReceiptFilterBarState extends State<ReceiptFilterBar> {
  late bool _showFilterOptions;

  @override
  void initState() {
    super.initState();
    _showFilterOptions = widget.initialShowOptions;
  }

  Widget _buildPill({
    required BuildContext context,
    required bool isSelected,
    required Color color,
    required String label,
    required VoidCallback onToggle,
    IconData? icon,
    int? count,
  }) {
    final cs = Theme.of(context).colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(40) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onToggle(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : cs.outlineVariant.withAlpha(80),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      backgroundColor: cs.surfaceContainerLow,
      selectedColor: color.withAlpha(35),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final activeFilterCount = (widget.selectedTypeFilter != ReceiptTypeFilter.all ? 1 : 0) +
        (widget.selectedStatusFilter != ReceiptStatusFilter.all ? 1 : 0);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JoppeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
            LayoutBuilder(
              builder: (context, constraints) {
                final searchWidth = constraints.maxWidth < 360 ? constraints.maxWidth : 300.0;

                final searchField = SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchReceiptsHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: widget.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged();
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => widget.onSearchChanged(),
                    onSubmitted: (_) => widget.onSearchChanged(),
                  ),
                );

                final actionButtons = Wrap(
                  spacing: JoppeSpacing.sm,
                  runSpacing: JoppeSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Toggle show filter options button
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _showFilterOptions = !_showFilterOptions),
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

                    // Reset button
                    IconButton.filledTonal(
                      onPressed: widget.onReset,
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: l10n.resetFiltersTooltip,
                    ),

                    // New Inbound Receipt trigger
                    FilledButton.icon(
                      onPressed: widget.onNewReceipt,
                      icon: const Icon(Icons.input_rounded, size: 18),
                      label: Text(l10n.newInboundReceipt),
                    ),
                  ],
                );

                return Wrap(
                  spacing: JoppeSpacing.md,
                  runSpacing: JoppeSpacing.sm,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    searchField,
                    actionButtons,
                  ],
                );
              },
            ),

            // Collapsible filter options section
            if (_showFilterOptions) ...[
              const SizedBox(height: JoppeSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: JoppeSpacing.sm),

              Wrap(
                spacing: JoppeSpacing.lg,
                runSpacing: JoppeSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Type filter pills
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.movementType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: JoppeSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedTypeFilter == ReceiptTypeFilter.all,
                            color: cs.primary,
                            label: l10n.allMovementTypes,
                            count: widget.totalCount,
                            onToggle: () => widget.onSelectType(ReceiptTypeFilter.all),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedTypeFilter == ReceiptTypeFilter.inbound,
                            color: Colors.teal.shade700,
                            label: l10n.inbound,
                            count: widget.inboundCount,
                            icon: Icons.input_rounded,
                            onToggle: () => widget.onSelectType(ReceiptTypeFilter.inbound),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedTypeFilter == ReceiptTypeFilter.outbound,
                            color: Colors.blue.shade700,
                            label: l10n.outbound,
                            count: widget.outboundCount,
                            icon: Icons.output_rounded,
                            onToggle: () => widget.onSelectType(ReceiptTypeFilter.outbound),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status filter pills
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.movementStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: JoppeSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedStatusFilter == ReceiptStatusFilter.all,
                            color: cs.primary,
                            label: l10n.allStatusOption,
                            onToggle: () => widget.onSelectStatus(ReceiptStatusFilter.all),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedStatusFilter == ReceiptStatusFilter.completed,
                            color: Colors.green.shade700,
                            label: 'COMPLETED',
                            icon: Icons.check_circle_outline,
                            onToggle: () => widget.onSelectStatus(ReceiptStatusFilter.completed),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedStatusFilter == ReceiptStatusFilter.draft,
                            color: Colors.orange.shade800,
                            label: 'DRAFT',
                            icon: Icons.pending_outlined,
                            onToggle: () => widget.onSelectStatus(ReceiptStatusFilter.draft),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
