import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_dashboard/src/widgets/image_upload_field.dart';
import 'package:joppe_dashboard/src/widgets/markdown_editor_field.dart';

void main() {
  group('MarkdownEditorField Widget Tests', () {
    testWidgets('renders toolbar and switches between Edit and Preview modes', (WidgetTester tester) async {
      final controller = TextEditingController(text: '# Product Heading\n\n- Feature 1\n- Feature 2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownEditorField(
                controller: controller,
                label: 'Test Description',
              ),
            ),
          ),
        ),
      );

      // Verify label and buttons
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Upload Image'), findsOneWidget);

      // Verify Edit mode displays TextFormField
      expect(find.byType(TextFormField), findsOneWidget);

      // Switch to Preview mode
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Verify MarkdownBody is rendered
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('Product Heading'), findsOneWidget);
    });

    testWidgets('applies bold formatting via toolbar button', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditorField(
              controller: controller,
            ),
          ),
        ),
      );

      // Tap bold icon in toolbar
      final boldButton = find.byTooltip('Bold (**text**)');
      expect(boldButton, findsOneWidget);
      await tester.tap(boldButton);
      await tester.pumpAndSettle();

      expect(controller.text, contains('**bold text**'));
    });
  });

  group('ImageUploadField Widget Tests', () {
    testWidgets('renders input and preview thumbnail when URL is present', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ImageUploadField(
                controller: controller,
                label: 'Thumbnail URL',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Thumbnail URL'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Image Preview'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Tap clear button
      final clearButton = find.byTooltip('Clear image');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.text('Image Preview'), findsNothing);
    });
  });
}
