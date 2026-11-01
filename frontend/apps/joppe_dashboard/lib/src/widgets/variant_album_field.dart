import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'media_library_dialog.dart';

class VariantAlbumField extends StatefulWidget {
  final List<String> initialUrls;
  final List<String> initialMediaIds;
  final MediaUploadService? mediaUploadService;
  final void Function(List<String> urls, List<String> mediaIds) onChanged;

  const VariantAlbumField({
    super.key,
    this.initialUrls = const [],
    this.initialMediaIds = const [],
    this.mediaUploadService,
    required this.onChanged,
  });

  @override
  State<VariantAlbumField> createState() => _VariantAlbumFieldState();
}

class _VariantAlbumFieldState extends State<VariantAlbumField> {
  final List<String> _urls = [];
  final List<String> _mediaIds = [];

  @override
  void initState() {
    super.initState();
    _urls.addAll(widget.initialUrls);
    _mediaIds.addAll(widget.initialMediaIds);
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) return '$defaultApiUrl$url';
    return '$defaultApiUrl/$url';
  }

  Future<void> _openLibrary() async {
    if (widget.mediaUploadService == null) return;

    final selected = await MediaLibraryDialog.show(
      context,
      mediaUploadService: widget.mediaUploadService!,
      multiSelect: true,
      initialFolder: 'products',
      selectedUrls: _urls,
    );

    if (selected != null) {
      setState(() {
        _urls.clear();
        _mediaIds.clear();
        for (final m in selected) {
          if (!_urls.contains(m.fileUrl)) {
            _urls.add(m.fileUrl);
            if (m.id != null) {
              _mediaIds.add(m.id!);
            }
          }
        }
      });
      widget.onChanged(_urls, _mediaIds);
    }
  }

  void _removeAt(int index) {
    setState(() {
      _urls.removeAt(index);
      if (index < _mediaIds.length) {
        _mediaIds.removeAt(index);
      }
    });
    widget.onChanged(_urls, _mediaIds);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Variant Image Album (${_urls.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.mediaUploadService != null)
              FilledButton.tonalIcon(
                onPressed: _openLibrary,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add / Select Images'),
              ),
          ],
        ),
        const SizedBox(height: JoppeSpacing.xs),
        Text(
          'Upload new images or pick existing images uploaded across the system to attach to this variant.',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: JoppeSpacing.sm),
        if (_urls.isEmpty)
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainerLowest,
            ),
            child: Center(
              child: Text(
                'No album images attached yet',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: JoppeSpacing.sm),
              itemBuilder: (context, index) {
                final url = _urls[index];
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                        color: colorScheme.surfaceContainerLowest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _resolveUrl(url),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: colorScheme.errorContainer.withValues(alpha: 0.3),
                          child: Icon(Icons.broken_image, color: colorScheme.error),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeAt(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
