import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../models/pos_cart_item.dart';

/// Atom: Single line item in the POS Cashier Register Cart with quantity increment/decrement.
class PosCartItemRow extends StatelessWidget {
  final PosCartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onSerialNumbersChanged;

  const PosCartItemRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onSerialNumbersChanged,
  });

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} ₫';
  }

  void _openSerialDialog(BuildContext context) {
    final textController = TextEditingController();
    final serials = List<String>.from(item.serialNumbers);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void addSerial(String val) {
            final trimmed = val.trim();
            if (trimmed.isEmpty) return;
            if (serials.contains(trimmed)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mã $trimmed đã được quét.')),
              );
              return;
            }
            if (serials.length >= item.quantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã đủ ${item.quantity} mã cho số lượng sản phẩm.')),
              );
              return;
            }
            setDialogState(() {
              serials.add(trimmed);
              textController.clear();
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Serial Numbers: ${item.productName}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cần ${item.quantity} mã • Đã quét: ${serials.length}/${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: serials.length == item.quantity ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Quét barcode / Nhập SN (Enter)',
                              prefixIcon: Icon(Icons.barcode_reader, size: 18),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onSubmitted: addSerial,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'Thêm mã',
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => addSerial(textController.text),
                        ),
                        const SizedBox(width: 4),
                        IconButton.outlined(
                          tooltip: 'Mock Scan (Thử nghiệm không cần máy quét)',
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          onPressed: () {
                            final mockSn = 'SN-${item.sku}-${DateTime.now().millisecondsSinceEpoch % 10000}';
                            addSerial(mockSn);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (serials.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Chưa có mã SN nào. Dùng máy quét hoặc gõ SN rồi nhấn Enter.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: serials.map((sn) {
                          return Chip(
                            label: Text(sn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setDialogState(() => serials.remove(sn));
                            },
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  item.serialNumbers = serials;
                  onSerialNumbersChanged?.call();
                  Navigator.pop(ctx);
                },
                child: const Text('Lưu danh sách SN'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(JoppeSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.variantName} • ${_formatPrice(item.unitPrice)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Serial Number button & status
                      InkWell(
                        onTap: () => _openSerialDialog(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.serialNumbers.length == item.quantity
                                ? Colors.green.withAlpha(25)
                                : (item.serialNumbers.isNotEmpty ? Colors.orange.withAlpha(25) : colorScheme.surface),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.serialNumbers.length == item.quantity
                                  ? Colors.green.withAlpha(120)
                                  : (item.serialNumbers.isNotEmpty ? Colors.orange.withAlpha(120) : colorScheme.outlineVariant),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 13,
                                color: item.serialNumbers.length == item.quantity
                                    ? Colors.green
                                    : (item.serialNumbers.isNotEmpty ? Colors.orange : colorScheme.primary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.serialNumbers.isEmpty
                                    ? 'Quét / Nhập SN'
                                    : 'SN: ${item.serialNumbers.length}/${item.quantity}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.serialNumbers.length == item.quantity
                                      ? Colors.green
                                      : (item.serialNumbers.isNotEmpty ? Colors.orange : colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  color: colorScheme.error,
                  tooltip: 'Xóa khỏi đơn',
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qty Controller (- / qty / +)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1) {
                            onQuantityChanged(item.quantity - 1);
                          } else {
                            onRemove();
                          }
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      InkWell(
                        onTap: item.quantity < item.stockAvailable
                            ? () => onQuantityChanged(item.quantity + 1)
                            : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: item.quantity < item.stockAvailable
                                ? colorScheme.onSurface
                                : colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Line total
                Text(
                  _formatPrice(item.lineTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
