import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Three-dot dropdown menu providing row-level actions for warehouse stock.
class WarehouseActionMenu extends StatelessWidget {
  final InventoryStockItem item;
  final VoidCallback onAdjustStock;

  const WarehouseActionMenu({
    super.key,
    required this.item,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      tooltip: l10n.actionCol,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (action) {
        switch (action) {
          case 'adjust':
            onAdjustStock();
            break;
          case 'copy_sku':
            Clipboard.setData(ClipboardData(text: item.sku));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.skuCopied),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'adjust',
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.adjustStock),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_sku',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(l10n.copySku),
            ],
          ),
        ),
      ],
    );
  }
}
