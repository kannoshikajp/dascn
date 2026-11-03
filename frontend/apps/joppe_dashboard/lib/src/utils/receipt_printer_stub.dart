import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';

/// Non-web fallback / unit test environment: triggers brief status snackbar.
void printReceipt(BuildContext context, OrderDetailModel order) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Đang xuất hóa đơn ${order.orderCode}...'),
      duration: const Duration(seconds: 2),
    ),
  );
}
