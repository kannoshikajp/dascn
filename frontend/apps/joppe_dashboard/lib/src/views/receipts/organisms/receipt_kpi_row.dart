import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/receipt_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing stock movement metrics.
class ReceiptKpiRow extends StatelessWidget {
  final List<GoodReceiptSummary> receipts;
  final String Function(double) formatCurrency;

  const ReceiptKpiRow({
    super.key,
    required this.receipts,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final totalReceipts = receipts.length;
    final totalInboundValue = receipts
        .where((r) => r.isInbound)
        .fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalOutboundValue = receipts
        .where((r) => r.isOutbound)
        .fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalUnitsMoved = receipts.fold(0, (sum, r) => sum + r.totalItems);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final cardWidth = isCompact
            ? (constraints.maxWidth - JoppeSpacing.md) / 2
            : (constraints.maxWidth - (JoppeSpacing.md * 3)) / 4;

        return Wrap(
          spacing: JoppeSpacing.md,
          runSpacing: JoppeSpacing.md,
          children: [
            ReceiptKpiCard(
              title: l10n.totalReceiptsKpi,
              value: '$totalReceipts',
              icon: Icons.receipt_long_outlined,
              color: cs.primary,
              width: cardWidth,
            ),
            ReceiptKpiCard(
              title: l10n.totalInboundValueKpi,
              value: formatCurrency(totalInboundValue),
              icon: Icons.input_rounded,
              color: Colors.teal.shade700,
              width: cardWidth,
            ),
            ReceiptKpiCard(
              title: l10n.totalOutboundValueKpi,
              value: formatCurrency(totalOutboundValue),
              icon: Icons.output_rounded,
              color: Colors.blue.shade700,
              width: cardWidth,
            ),
            ReceiptKpiCard(
              title: l10n.totalItemsMovedKpi,
              value: '$totalUnitsMoved',
              icon: Icons.all_inbox_outlined,
              color: Colors.amber.shade800,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}
