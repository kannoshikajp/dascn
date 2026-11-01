import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Atom: Status badge displaying receipt processing state (COMPLETED vs DRAFT).
class ReceiptStatusBadge extends StatelessWidget {
  final String status;

  const ReceiptStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = status.toUpperCase() == 'COMPLETED';

    final color = isCompleted ? Colors.green.shade700 : Colors.orange.shade800;
    final label = isCompleted ? 'COMPLETED' : 'DRAFT';
    final icon = isCompleted ? Icons.check_circle_outline : Icons.pending_outlined;

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
