import 'package:web/web.dart' as web;

/// Web implementation: Opens payment URL in dedicated popup window or new tab using modern package:web.
void openPopupWindow(String url, {String target = '_blank', String? features}) {
  if (url.trim().isEmpty) return;

  final defaultFeatures = features ?? 'width=560,height=780,menubar=no,toolbar=no,location=no,status=no,resizable=yes';
  try {
    final win = web.window.open(url, target, defaultFeatures);
    // If popup was blocked by browser (win is null or immediately closed), fallback to anchor click
    if (win == null || win.closed) {
      _openInNewTab(url, target);
    }
  } catch (_) {
    _openInNewTab(url, target);
  }
}

void _openInNewTab(String url, String target) {
  try {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..target = target
      ..rel = 'noopener noreferrer';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    web.window.open(url, '_blank');
  }
}
