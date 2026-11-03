import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class MediaLibraryDialog extends StatefulWidget {
  final MediaUploadService mediaUploadService;
  final bool multiSelect;
  final String initialFolder;
  final List<String> selectedUrls;

  const MediaLibraryDialog({
    super.key,
    required this.mediaUploadService,
    this.multiSelect = false,
    this.initialFolder = 'products',
    this.selectedUrls = const [],
  });

  static Future<List<UploadedMedia>?> show(
    BuildContext context, {
    required MediaUploadService mediaUploadService,
    bool multiSelect = false,
    String initialFolder = 'products',
    List<String> selectedUrls = const [],
  }) {
    return showDialog<List<UploadedMedia>>(
      context: context,
      builder: (ctx) => MediaLibraryDialog(
        mediaUploadService: mediaUploadService,
        multiSelect: multiSelect,
        initialFolder: initialFolder,
        selectedUrls: selectedUrls,
      ),
    );
  }

  @override
  State<MediaLibraryDialog> createState() => _MediaLibraryDialogState();
}

class _MediaLibraryDialogState extends State<MediaLibraryDialog> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String _selectedFolder = 'products';
  String _searchQuery = '';
  List<UploadedMedia> _mediaList = [];
  final Set<String> _selectedUrls = {};
  final Map<String, UploadedMedia> _urlToMedia = {};

  final TextEditingController _searchController = TextEditingController();

  static const _folders = [
    'products',
    'categories',
    'descriptions',
    'avatars',
    'general',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.initialFolder;
    _selectedUrls.addAll(widget.selectedUrls);
    _loadMedia();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _resolveUrl(String url) => ApiClient.resolveUrl(url);

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.mediaUploadService.listMedia(
        folder: _selectedFolder == 'all' ? null : _selectedFolder,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _mediaList = items;
        for (final m in items) {
          _urlToMedia[m.fileUrl] = m;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() => _isUploading = true);

      final uploaded = await widget.mediaUploadService.uploadImage(
        bytes: bytes,
        filename: file.name,
        folder: _selectedFolder == 'all' ? 'products' : _selectedFolder,
      );

      _urlToMedia[uploaded.fileUrl] = uploaded;

      if (!widget.multiSelect) {
        _selectedUrls.clear();
      }
      _selectedUrls.add(uploaded.fileUrl);

      await _loadMedia();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${uploaded.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleSelection(UploadedMedia media) {
    setState(() {
      if (!widget.multiSelect) {
        _selectedUrls.clear();
        _selectedUrls.add(media.fileUrl);
        _urlToMedia[media.fileUrl] = media;
      } else {
        if (_selectedUrls.contains(media.fileUrl)) {
          _selectedUrls.remove(media.fileUrl);
        } else {
          _selectedUrls.add(media.fileUrl);
          _urlToMedia[media.fileUrl] = media;
        }
      }
    });
  }

  void _confirmSelection() {
    final result = _selectedUrls.map((url) {
      return _urlToMedia[url] ??
          UploadedMedia(
            fileUrl: url,
            fileName: url.split('/').last,
            fileSize: 0,
            contentType: 'image/jpeg',
          );
    }).toList();

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.photo_library_outlined, color: colorScheme.primary, size: 26),
                  const SizedBox(width: JoppeSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.multiSelect ? 'Select Media Album Images' : 'Select Media Image',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload New'),
                  ),
                  const SizedBox(width: JoppeSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: JoppeSpacing.lg),

              // Filter Bar
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search media files...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _loadMedia();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) {
                        _searchQuery = val.trim();
                        _loadMedia();
                      },
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.md),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedFolder == 'all',
                            onSelected: (_) {
                              setState(() => _selectedFolder = 'all');
                              _loadMedia();
                            },
                          ),
                          const SizedBox(width: 6),
                          ..._folders.map((f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: _selectedFolder == f,
                                  onSelected: (_) {
                                    setState(() => _selectedFolder = f);
                                    _loadMedia();
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: JoppeSpacing.md),

              // Media Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loadMedia,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _mediaList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_not_supported_outlined, size: 48, color: colorScheme.outline),
                                    const SizedBox(height: 8),
                                    Text('No images found in $_selectedFolder folder',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _pickAndUpload,
                                      icon: const Icon(Icons.upload),
                                      label: const Text('Upload an image now'),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: _mediaList.length,
                                itemBuilder: (context, index) {
                                  final media = _mediaList[index];
                                  final isSelected = _selectedUrls.contains(media.fileUrl);

                                  return InkWell(
                                    onTap: () => _toggleSelection(media),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                                          width: isSelected ? 3 : 1,
                                        ),
                                        color: colorScheme.surfaceContainerLowest,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            _resolveUrl(media.fileUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => Container(
                                              color: colorScheme.errorContainer.withValues(alpha: 0.3),
                                              child: Icon(Icons.broken_image, color: colorScheme.error),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              color: colorScheme.primary.withValues(alpha: 0.35),
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              color: Colors.black.withValues(alpha: 0.6),
                                              child: Text(
                                                media.fileName,
                                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),

              const Divider(height: JoppeSpacing.lg),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${_selectedUrls.length} image(s)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: JoppeSpacing.sm),
                      FilledButton(
                        onPressed: _selectedUrls.isEmpty ? null : _confirmSelection,
                        child: const Text('Choose Selected'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
