import 'dart:html' as html;

/// Web implementation: Opens payment URL in dedicated popup window or new tab.
void openPopupWindow(String url, {String target = '_blank', String? features}) {
  if (url.trim().isEmpty) return;

  final defaultFeatures = features ?? 'width=560,height=780,menubar=no,toolbar=no,location=no,status=no,resizable=yes';
  try {
    final win = html.window.open(url, target, defaultFeatures);
    // If popup was blocked by browser (win is null or immediately closed), fallback to anchor click
    if (win == null || (win.closed ?? false)) {
      _openInNewTab(url, target);
    }
  } catch (_) {
    _openInNewTab(url, target);
  }
}

void _openInNewTab(String url, String target) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..target = target
      ..rel = 'noopener noreferrer';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    html.window.open(url, '_blank');
  }
}
