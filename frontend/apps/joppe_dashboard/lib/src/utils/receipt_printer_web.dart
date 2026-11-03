import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:web/web.dart' as web;

/// Web implementation: prints 80mm thermal receipt via modern package:web.
void printReceipt(BuildContext context, OrderDetailModel order) {
  try {
    final htmlContent = _buildReceiptHtml(order);
    final blob = web.Blob(
      [htmlContent.toJS].toJS,
      web.BlobPropertyBag(type: 'text/html;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final win = web.window.open(url, '_blank', 'width=420,height=650,menubar=no,toolbar=no,location=no,status=no');
    if (win == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trình duyệt đã chặn cửa sổ in. Vui lòng cho phép popup.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể in hóa đơn: $e')),
      );
    }
  }
}

String _buildReceiptHtml(OrderDetailModel order) {
  final itemsHtml = order.items.map((item) {
    final serialsHtml = item.serialNumbers.isNotEmpty
        ? '<div style="font-size: 9px; color: #555; font-family: monospace;">SN: ${item.serialNumbers.join(", ")}</div>'
        : '';
    final name = item.variantNameSnapshot.isNotEmpty
        ? '${item.productNameSnapshot} (${item.variantNameSnapshot})'
        : item.productNameSnapshot;
    return '''
      <tr>
        <td style="padding: 4px 0; vertical-align: top;">
          <div style="font-weight: 600;">$name</div>
          $serialsHtml
        </td>
        <td style="padding: 4px 0; text-align: center; vertical-align: top;">${item.quantity}</td>
        <td style="padding: 4px 0; text-align: right; vertical-align: top; white-space: nowrap;">${_formatMoney(item.subtotal)} ₫</td>
      </tr>
    ''';
  }).join('');

  final manualRef = order.manualPaymentRef != null && order.manualPaymentRef!.isNotEmpty
      ? '<div class="row"><span>Mã GD đối soát:</span><span class="bold">${order.manualPaymentRef}</span></div>'
      : '';

  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Hóa đơn ${order.orderCode}</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      width: 72mm;
      margin: 0 auto;
      padding: 2mm;
      font-size: 11px;
      color: #000;
      line-height: 1.35;
    }
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .bold { font-weight: bold; }
    .header { text-align: center; margin-bottom: 8px; }
    .title { font-size: 15px; font-weight: 900; letter-spacing: 0.5px; }
    .subtitle { font-size: 10px; color: #444; margin-top: 2px; }
    .doc-type { font-size: 13px; font-weight: bold; margin-top: 6px; text-transform: uppercase; }
    .divider { border-top: 1px dashed #444; margin: 6px 0; }
    .row { display: flex; justify-content: space-between; font-size: 10.5px; margin-bottom: 2px; }
    .table { width: 100%; border-collapse: collapse; font-size: 10.5px; margin-top: 4px; }
    .table th { border-bottom: 1px solid #000; padding: 2px 0; font-size: 10px; }
    .total-row { display: flex; justify-content: space-between; font-size: 13px; font-weight: 900; padding: 4px 0; }
    .footer { text-align: center; font-size: 9.5px; color: #444; margin-top: 10px; }
    @media print {
      .no-print { display: none !important; }
    }
    .no-print {
      text-align: center;
      margin-top: 15px;
    }
    .btn-print {
      background: #1976d2;
      color: #fff;
      border: none;
      padding: 8px 16px;
      border-radius: 4px;
      font-size: 12px;
      cursor: pointer;
    }
  </style>
  <script>
    window.addEventListener('load', function() {
      setTimeout(function() {
        window.print();
      }, 300);
    });
  </script>
</head>
<body>
  <div class="header">
    <div class="title">JOPPE GAMING GEAR & PC</div>
    <div class="subtitle">Showroom: 123 Nguyễn Trãi, Q.1, TP.HCM<br>Hotline: 1900 8888 • www.joppe.vn</div>
    <div class="doc-type">PHIẾU BÁN HÀNG TẠI QUẦY</div>
  </div>
  <div class="divider"></div>
  <div class="row"><span>Mã đơn hàng:</span><span class="bold">${order.orderCode}</span></div>
  <div class="row"><span>Thời gian:</span><span>$dateStr</span></div>
  <div class="row"><span>Khách hàng:</span><span>${order.recipientName}</span></div>
  <div class="row"><span>Điện thoại:</span><span>${order.recipientPhone}</span></div>
  <div class="row"><span>Thanh toán:</span><span class="bold">${order.paymentStatus}</span></div>
  $manualRef
  <div class="divider"></div>
  <table class="table">
    <thead>
      <tr>
        <th style="text-align: left; width: 55%;">Sản phẩm</th>
        <th style="text-align: center; width: 15%;">SL</th>
        <th style="text-align: right; width: 30%;">Tiền</th>
      </tr>
    </thead>
    <tbody>
      $itemsHtml
    </tbody>
  </table>
  <div class="divider"></div>
  <div class="row"><span>Tạm tính:</span><span>${_formatMoney(order.subtotalAmount)} ₫</span></div>
  ${order.discountAmount > 0 ? '<div class="row"><span>Giảm giá:</span><span>-${_formatMoney(order.discountAmount)} ₫</span></div>' : ''}
  ${order.shippingFee > 0 ? '<div class="row"><span>Phí giao:</span><span>${_formatMoney(order.shippingFee)} ₫</span></div>' : ''}
  <div class="total-row"><span>TỔNG CỘNG:</span><span>${_formatMoney(order.finalAmount)} ₫</span></div>
  <div class="divider"></div>
  <div class="footer">
    <div>Cảm ơn quý khách đã mua sắm tại Joppe!</div>
    <div>Bảo hành linh kiện điện tử theo số Serial Number.</div>
  </div>
  <div class="no-print">
    <button class="btn-print" onclick="window.print()">In lại hóa đơn</button>
  </div>
</body>
</html>
''';
}

String _formatMoney(double amount) {
  if (amount <= 0) return '0';
  final str = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }
  return buffer.toString().split('').reversed.join('');
}
