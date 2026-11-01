import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../../../widgets/image_upload_field.dart';

/// Molecule: Dialog for creating or editing a category with real-time slugify,
/// hierarchical parent selector preventing cycle dependencies, image upload,
/// and activation status toggle.
class CategoryFormDialog extends StatefulWidget {
  final CategoryItem? category;
  final int? defaultParentId;
  final List<CategoryItem> allCategories;
  final CategoryManagementService categoryService;
  final MediaUploadService? mediaUploadService;
  final VoidCallback onSuccess;

  const CategoryFormDialog({
    super.key,
    this.category,
    this.defaultParentId,
    required this.allCategories,
    required this.categoryService,
    this.mediaUploadService,
    required this.onSuccess,
  });

  bool get isEditing => category != null;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _iconCtrl;
  int? _selectedParentId;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;
  bool _userEditedSlug = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.categoryName ?? '');
    _slugCtrl = TextEditingController(text: c?.slug ?? '');
    _iconCtrl = TextEditingController(text: c?.iconUrl ?? '');
    _selectedParentId = c != null ? c.parentId : widget.defaultParentId;
    _isActive = c?.isActive ?? true;
    _userEditedSlug = c != null && c.slug.isNotEmpty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    var s = input.trim().toLowerCase();
    const Map<String, String> vietnameseMap = {
      'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ': 'a',
      'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ': 'e',
      'ì|í|ị|ỉ|ĩ': 'i',
      'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ': 'o',
      'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ': 'u',
      'ỳ|ý|ỵ|ỷ|ỹ': 'y',
      'đ': 'd',
    };
    vietnameseMap.forEach((pattern, replacement) {
      s = s.replaceAll(RegExp(pattern), replacement);
    });
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    return s;
  }

  Set<int> _findDescendantIds(int rootId) {
    final result = <int>{rootId};
    bool addedAny;
    do {
      addedAny = false;
      for (final cat in widget.allCategories) {
        if (cat.parentId != null && result.contains(cat.parentId) && !result.contains(cat.id)) {
          result.add(cat.id);
          addedAny = true;
        }
      }
    } while (addedAny);
    return result;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final name = _nameCtrl.text.trim();
      final rawSlug = _slugCtrl.text.trim();
      final slug = rawSlug.isNotEmpty ? rawSlug : _slugify(name);
      final iconUrl = _iconCtrl.text.trim().isNotEmpty ? _iconCtrl.text.trim() : null;

      if (widget.isEditing) {
        await widget.categoryService.updateCategory(
          id: widget.category!.id,
          parentId: _selectedParentId,
          categoryName: name,
          slug: slug.isEmpty ? null : slug,
          iconUrl: iconUrl,
          isActive: _isActive,
        );
      } else {
        await widget.categoryService.createCategory(
          parentId: _selectedParentId,
          categoryName: name,
          slug: slug.isEmpty ? null : slug,
          iconUrl: iconUrl,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? l10n.categoryUpdatedSuccess : l10n.categoryCreatedSuccess,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // Filter valid parent categories: exclude itself and descendants to prevent cycles
    final invalidParentIds = widget.isEditing ? _findDescendantIds(widget.category!.id) : <int>{};
    final eligibleParents = widget.allCategories.where((c) => !invalidParentIds.contains(c.id)).toList();

    return AlertDialog(
      title: Text(
        widget.isEditing
            ? '${l10n.editCategoryTitle} "${widget.category!.categoryName}"'
            : l10n.addNewCategoryTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(JoppeSpacing.sm),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(JoppeShapes.small),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
                        const SizedBox(width: JoppeSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: JoppeSpacing.md),
                ],

                // Category Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.categoryName,
                    hintText: l10n.categoryNameHint,
                    prefixIcon: const Icon(Icons.label_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.categoryNameRequired : null,
                  onChanged: (v) {
                    if (!_userEditedSlug) {
                      setState(() {
                        _slugCtrl.text = _slugify(v);
                      });
                    }
                  },
                ),
                const SizedBox(height: JoppeSpacing.md),

                // URL Slug
                TextFormField(
                  controller: _slugCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.urlSlug,
                    hintText: l10n.urlSlugHint,
                    prefixIcon: const Icon(Icons.link, size: 20),
                    helperText: l10n.urlSlugHelper,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                  ),
                  onChanged: (_) => _userEditedSlug = true,
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Parent Category Dropdown
                DropdownButtonFormField<int?>(
                  initialValue: _selectedParentId,
                  decoration: InputDecoration(
                    labelText: l10n.parentCategory,
                    prefixIcon: const Icon(Icons.account_tree_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        l10n.rootCategoryOption,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ...eligibleParents.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.parentName != null ? '${c.parentName} > ${c.categoryName}' : c.categoryName,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedParentId = val),
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Icon / Image Upload Field
                ImageUploadField(
                  controller: _iconCtrl,
                  mediaUploadService: widget.mediaUploadService,
                  label: l10n.iconOrImageUrl,
                  folder: 'categories',
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Active Switch
                Material(
                  color: cs.surfaceContainerHigh.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(JoppeShapes.small),
                    side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SwitchListTile(
                      title: Text(
                        l10n.categoryActive,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        l10n.categoryActiveDescription,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.isEditing ? l10n.saveChanges : l10n.save),
        ),
      ],
    );
  }
}
