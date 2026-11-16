import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:espere_wallpaper/core/widgets/app_search_bar.dart';

void main() {
  testWidgets(
    'AppSearchBar renders with rounded pill container and transparent filled input',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppSearchBar(hintText: 'Search photos...')),
        ),
      );

      // Verify container has antiAlias clip and rounded border radius
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.clipBehavior, equals(Clip.antiAlias));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(28)));

      // Verify TextField has filled: false and transparent fillColor
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.filled, isFalse);
      expect(textField.decoration?.fillColor, equals(Colors.transparent));
      expect(textField.decoration?.hintText, equals('Search photos...'));
    },
  );
}
