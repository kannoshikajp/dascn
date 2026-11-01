import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'media_library_dialog.dart';

class ImageUploadField extends StatefulWidget {
  final TextEditingController controller;
  final MediaUploadService? mediaUploadService;
  final String label;
  final String hint;
  final String folder;
  final ValueChanged<String>? onChanged;

  const ImageUploadField({
    super.key,
    required this.controller,
    this.mediaUploadService,
    this.label = 'Image URL',
    this.hint = 'https://... or upload local image',
    this.folder = 'general',
    this.onChanged,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _isUploading = false;
  String? _uploadError;

  String get _currentUrl => widget.controller.text.trim();

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Resolve relative backend /uploads url to current API host
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) {
      return '$defaultApiUrl$url';
    }
    return '$defaultApiUrl/$url';
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.mediaUploadService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload service is not configured.')),
      );
      return;
    }

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final uploaded = await widget.mediaUploadService!.uploadImage(
        bytes: bytes,
        filename: file.name,
        folder: widget.folder,
      );

      widget.controller.text = uploaded.fileUrl;
      widget.onChanged?.call(uploaded.fileUrl);

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded: ${uploaded.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = _currentUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.link, size: 20),
                  suffixIcon: hasImage
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear image',
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged?.call('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  widget.onChanged?.call(val);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_isUploading ? 'Uploading...' : 'Upload'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(100, 48),
              ),
            ),
            if (widget.mediaUploadService != null) ...[
              const SizedBox(width: JoppeSpacing.xs),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await MediaLibraryDialog.show(
                    context,
                    mediaUploadService: widget.mediaUploadService!,
                    multiSelect: false,
                    initialFolder: widget.folder,
                    selectedUrls: widget.controller.text.isNotEmpty ? [widget.controller.text.trim()] : [],
                  );
                  if (selected != null && selected.isNotEmpty) {
                    widget.controller.text = selected.first.fileUrl;
                    widget.onChanged?.call(selected.first.fileUrl);
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Library'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                ),
              ),
            ],
          ],
        ),
        if (_uploadError != null) ...[
          const SizedBox(height: 4),
          Text(
            _uploadError!,
            style: TextStyle(fontSize: 12, color: colorScheme.error),
          ),
        ],
        if (hasImage) ...[
          const SizedBox(height: JoppeSpacing.sm),
          Container(
            height: 90,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainerLowest,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _resolveImageUrl(_currentUrl),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 80,
                      height: 80,
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: Icon(Icons.broken_image, color: colorScheme.error),
                    ),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: JoppeSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Image Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentUrl,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
