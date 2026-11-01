import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isVi = currentLocale.languageCode == 'vi';
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<Locale>(
      tooltip: isVi ? 'Chuyển đổi ngôn ngữ' : 'Change Language',
      initialValue: currentLocale,
      offset: const Offset(0, 42),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      color: colorScheme.surface,
      itemBuilder: (context) => [
        PopupMenuItem<Locale>(
          value: const Locale('vi'),
          child: Row(
            children: [
              const Text('🇻🇳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tiếng Việt',
                  style: TextStyle(
                    fontWeight: isVi ? FontWeight.bold : FontWeight.normal,
                    color: isVi ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (isVi)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'English',
                  style: TextStyle(
                    fontWeight: !isVi ? FontWeight.bold : FontWeight.normal,
                    color: !isVi ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (!isVi)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
      ],
      onSelected: onLocaleChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(70),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isVi ? '🇻🇳' : '🇬🇧', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              isVi ? 'VI' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
