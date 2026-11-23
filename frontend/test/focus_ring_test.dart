import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// The neumorphic focus ring is the 2px gel border added by [_NeumorphBase].
bool _hasFocusRing(WidgetTester tester) {
  final ring = CScholarMaterial.gelTop.withValues(alpha: 0.6);
  return tester.widgetList<Container>(find.byType(Container)).any((box) {
    final decoration = box.decoration;
    return decoration is BoxDecoration &&
        decoration.border is Border &&
        (decoration.border! as Border).top.width == 2 &&
        (decoration.border! as Border).top.color == ring;
  });
}

void main() {
  testWidgets('focus ring follows the keyboard, not the mouse', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeumorphButton(
              label: 'Browse Repository',
              onPressed: () => tapped++,
            ),
          ),
        ),
      ),
    );

    final focus = tester
        .widget<Focus>(
          find
              .descendant(
                of: find.byType(NeumorphButton),
                matching: find.byType(Focus),
              )
              .first,
        )
        .focusNode!;

    // Keyboard navigation keeps the visible ring.
    focus.requestFocus();
    await tester.pump();
    expect(_hasFocusRing(tester), isTrue);

    // A pointer press focuses the button too, but must not leave the outline.
    await tester.tap(find.text('Browse Repository'));
    await tester.pump();
    expect(tapped, 1);
    expect(_hasFocusRing(tester), isFalse);
  });
}
