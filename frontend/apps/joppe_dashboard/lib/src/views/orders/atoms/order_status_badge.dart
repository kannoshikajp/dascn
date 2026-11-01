import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Status badge displaying order or payment status with color coding and localization.
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isPayment;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isPayment = false,
  });

  static Color getStatusColor(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'CONFIRMED':
        return Colors.blue;
      case 'PACKAGING':
      case 'PACKING':
        return Colors.indigo;
      case 'DELIVERY':
        return Colors.purple;
      case 'SHIPPED':
      case 'DELIVERED':
        return Colors.green;
      case 'SHOWROOM_BUY':
        return Colors.teal;
      case 'REFUND':
      case 'REFUNDED':
      case 'CANCELLED':
        return Colors.deepOrange;
      case 'PENDING':
        return Colors.orange;
      default:
        return cs.outline;
    }
  }

  static Color getPaymentColor(String paymentStatus, ColorScheme cs) {
    switch (paymentStatus.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'UNPAID':
        return Colors.amber.shade800;
      case 'REFUND':
      case 'REFUNDED':
        return Colors.deepOrange;
      default:
        return cs.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = isPayment ? getPaymentColor(status, cs) : getStatusColor(status, cs);
    final label = isPayment ? l10n.paymentStatusLabel(status) : l10n.orderStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(JoppeShapes.full),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
