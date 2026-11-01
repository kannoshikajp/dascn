import 'package:flutter/material.dart';

/// Atom: Color-coded stock level status badge with high legibility.
class StockStatusPill extends StatelessWidget {
  final int stockCount;

  const StockStatusPill({
    super.key,
    required this.stockCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOut = stockCount <= 0;
    final isLow = stockCount > 0 && stockCount <= 10;

    final Color bgColor = isOut
        ? colorScheme.errorContainer
        : isLow
            ? Colors.amber.shade100
            : colorScheme.primaryContainer;

    final Color textColor = isOut
        ? colorScheme.onErrorContainer
        : isLow
            ? Colors.amber.shade900
            : colorScheme.onPrimaryContainer;

    final String text = isOut
        ? 'Hết hàng (0)'
        : isLow
            ? 'Sắp hết ($stockCount)'
            : 'Còn hàng ($stockCount)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
