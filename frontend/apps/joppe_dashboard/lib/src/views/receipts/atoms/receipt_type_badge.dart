import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Badge displaying receipt type (INBOUND vs OUTBOUND).
class ReceiptTypeBadge extends StatelessWidget {
  final String receiptType;

  const ReceiptTypeBadge({
    super.key,
    required this.receiptType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isOutbound = receiptType.toUpperCase() == 'OUTBOUND';

    final color = isOutbound ? Colors.blue.shade700 : Colors.teal.shade700;
    final icon = isOutbound ? Icons.output_rounded : Icons.input_rounded;
    final label = isOutbound ? l10n.outbound : l10n.inbound;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(JoppeShapes.full),
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
