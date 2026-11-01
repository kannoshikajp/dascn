import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Molecule: Dialog for adjusting physical inventory on hand and reorder threshold.
class WarehouseAdjustDialog extends StatefulWidget {
  final InventoryStockItem item;
  final InventoryService inventoryService;
  final VoidCallback onSuccess;

  const WarehouseAdjustDialog({
    super.key,
    required this.item,
    required this.inventoryService,
    required this.onSuccess,
  });

  @override
  State<WarehouseAdjustDialog> createState() => _WarehouseAdjustDialogState();
}

class _WarehouseAdjustDialogState extends State<WarehouseAdjustDialog> {
  late final TextEditingController _onHandController;
  late final TextEditingController _reorderController;
  bool _isSubmitting = false;
  String? _error;
  late int _previewAvailable;

  @override
  void initState() {
    super.initState();
    _onHandController = TextEditingController(text: '${widget.item.quantityOnHand}');
    _reorderController = TextEditingController(text: '${widget.item.reorderLevel}');
    _previewAvailable = widget.item.stockAvailable;
    _onHandController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _onHandController.removeListener(_updatePreview);
    _onHandController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final onHand = int.tryParse(_onHandController.text.trim()) ?? 0;
    setState(() {
      _previewAvailable = (onHand - widget.item.quantityReserved).clamp(0, 9999999);
    });
  }

  Future<void> _submit() async {
    final onHand = int.tryParse(_onHandController.text.trim());
    final reorder = int.tryParse(_reorderController.text.trim());

    if (onHand == null || onHand < 0 || reorder == null || reorder < 0) {
      setState(() => _error = 'Please enter valid non-negative numbers');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.inventoryService.adjustStock(
        widget.item.variantId,
        quantityOnHand: onHand,
        reorderLevel: reorder,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.adjustStockSuccess),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceFirst('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final item = widget.item;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: cs.primary, size: 22),
          const SizedBox(width: JoppeSpacing.sm),
          Expanded(
            child: Text(
              l10n.adjustStockTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info banner
            Container(
              padding: const EdgeInsets.all(JoppeSpacing.sm),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(JoppeShapes.small),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.variantName,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(width: JoppeSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.sku,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: JoppeSpacing.md),

            // Live status metrics preview
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: l10n.reserved,
                    value: '${item.quantityReserved}',
                    color: cs.onSurfaceVariant,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: _buildMetricTile(
                    label: l10n.available,
                    value: '$_previewAvailable',
                    color: _previewAvailable > 0 ? Colors.green.shade700 : cs.error,
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.md),

            // On Hand field
            TextField(
              controller: _onHandController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '${l10n.physicalStockOnHand} *',
                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(JoppeShapes.small),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: JoppeSpacing.sm),

            // Reorder level field
            TextField(
              controller: _reorderController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '${l10n.reorderWarningLevel} *',
                prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(JoppeShapes.small),
                ),
                isDense: true,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required ColorScheme cs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}
