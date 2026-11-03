import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class MarkdownEditorField extends StatefulWidget {
  final TextEditingController controller;
  final MediaUploadService? mediaUploadService;
  final String label;
  final String hint;
  final double minHeight;
  final ValueChanged<String>? onChanged;

  const MarkdownEditorField({
    super.key,
    required this.controller,
    this.mediaUploadService,
    this.label = 'Full Description (Markdown)',
    this.hint = 'Write detailed product specifications, highlights, and documentation with Markdown...',
    this.minHeight = 220,
    this.onChanged,
  });

  @override
  State<MarkdownEditorField> createState() => _MarkdownEditorFieldState();
}

class _MarkdownEditorFieldState extends State<MarkdownEditorField> {
  int _activeTab = 0; // 0: Edit, 1: Preview
  bool _isUploadingImage = false;

  void _insertFormatting({
    required String prefix,
    String suffix = '',
    String defaultText = '',
  }) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final insertIndex = selection.isValid ? selection.baseOffset : text.length;
      final newText = text.substring(0, insertIndex) +
          prefix +
          defaultText +
          suffix +
          text.substring(insertIndex);

      widget.controller.text = newText;
      final cursor = insertIndex + prefix.length + defaultText.length;
      widget.controller.selection = TextSelection.collapsed(offset: cursor);
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.substring(0, selection.start) +
          prefix +
          selectedText +
          suffix +
          text.substring(selection.end);

      widget.controller.text = newText;
      final cursor = selection.start + prefix.length + selectedText.length + suffix.length;
      widget.controller.selection = TextSelection.collapsed(offset: cursor);
    }

    widget.onChanged?.call(widget.controller.text);
    setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.mediaUploadService == null) {
      _showInsertManualImageDialog();
      return;
    }

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() => _isUploadingImage = true);

      final uploaded = await widget.mediaUploadService!.uploadImage(
        bytes: bytes,
        filename: file.name,
        folder: 'descriptions',
      );

      final altText = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      _insertFormatting(
        prefix: '\n![$altText](${uploaded.fileUrl})\n',
        suffix: '',
      );

      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image inserted: ${uploaded.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showInsertManualImageDialog() {
    final urlCtrl = TextEditingController();
    final altCtrl = TextEditingController(text: 'image');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: JoppeSpacing.sm),
            TextField(
              controller: altCtrl,
              decoration: const InputDecoration(
                labelText: 'Alt / Caption Text',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                _insertFormatting(
                  prefix: '\n![${altCtrl.text.trim()}](${urlCtrl.text.trim()})\n',
                  suffix: '',
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold (**text**)',
            onPressed: () => _insertFormatting(prefix: '**', suffix: '**', defaultText: 'bold text'),
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic (*text*)',
            onPressed: () => _insertFormatting(prefix: '*', suffix: '*', defaultText: 'italic text'),
          ),
          _buildToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading 2 (## Heading)',
            onPressed: () => _insertFormatting(prefix: '\n## ', suffix: '\n', defaultText: 'Section Title'),
          ),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet list (- item)',
            onPressed: () => _insertFormatting(prefix: '\n- ', defaultText: 'Bullet item'),
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered list (1. item)',
            onPressed: () => _insertFormatting(prefix: '\n1. ', defaultText: 'Numbered item'),
          ),
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Blockquote (> quote)',
            onPressed: () => _insertFormatting(prefix: '\n> ', defaultText: 'Important note'),
          ),
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: 'Code (inline `code`)',
            onPressed: () => _insertFormatting(prefix: '`', suffix: '`', defaultText: 'code'),
          ),
          _buildToolbarButton(
            icon: Icons.data_object,
            tooltip: 'Code Block (```json ... ```)',
            onPressed: () => _insertFormatting(prefix: '\n```json\n', suffix: '\n```\n', defaultText: '{\n  "spec": "value"\n}'),
          ),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: 'Insert Link ([text](url))',
            onPressed: () => _insertFormatting(prefix: '[', suffix: '](https://example.com)', defaultText: 'link text'),
          ),
          _buildToolbarButton(
            icon: Icons.table_chart_outlined,
            tooltip: 'Insert Markdown Table',
            onPressed: () => _insertFormatting(
              prefix: '\n| Spec | Details |\n|---|---|\n| Processor | Intel Core i7 |\n| RAM | 16GB DDR5 |\n\n',
            ),
          ),
          Container(
            height: 20,
            width: 1,
            color: colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          FilledButton.tonalIcon(
            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
            icon: _isUploadingImage
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, size: 16),
            label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title and Tab Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.sm, vertical: JoppeSpacing.xs),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Edit', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.edit_note, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Preview', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.visibility_outlined, size: 16),
                    ),
                  ],
                  selected: {_activeTab},
                  onSelectionChanged: (set) => setState(() => _activeTab = set.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Action Toolbar (only visible in edit mode)
          if (_activeTab == 0) _buildToolbar(context),

          // Content Box: Edit or Preview
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight, maxHeight: 380),
            child: _activeTab == 0
                ? TextFormField(
                    controller: widget.controller,
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(JoppeSpacing.sm),
                    ),
                    onChanged: (val) {
                      widget.onChanged?.call(val);
                      setState(() {});
                    },
                  )
                : Container(
                    padding: const EdgeInsets.all(JoppeSpacing.md),
                    color: colorScheme.surface,
                    child: widget.controller.text.trim().isEmpty
                        ? Center(
                            child: Text(
                              'No markdown content yet. Switch to Edit tab to add product details and images.',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                          )
                        : SingleChildScrollView(
                            child: MarkdownBody(
                              data: widget.controller.text,
                              selectable: true,
                              imageDirectory: ApiClient.resolveUrl(''),
                              sizedImageBuilder: (config) {
                                final resolved = ApiClient.resolveUrl(config.uri.toString());
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.xs),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      resolved,
                                      width: config.width,
                                      height: config.height,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        padding: const EdgeInsets.all(JoppeSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: colorScheme.errorContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.broken_image, size: 16, color: colorScheme.error),
                                            const SizedBox(width: JoppeSpacing.xs),
                                            Text(
                                              'Failed to load: ${config.alt ?? "image"}',
                                              style: TextStyle(fontSize: 12, color: colorScheme.error),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                p: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurface),
                                h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                h2: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                h3: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                code: TextStyle(
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                blockquoteDecoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                  border: Border(
                                    left: BorderSide(color: colorScheme.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
