import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// The neumorphic controls paint NO focus outline — not on keyboard focus and
/// not after a pointer press. This went through two stages: first the ring was
/// hidden for pointer focus, then it leaked back whenever focus was restored
/// (a PDF opening in a new tab blurs the window and Flutter re-focuses the
/// node). The ring is now removed outright, so this probes for it being drawn
/// at all.
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
  testWidgets('no outline is drawn for keyboard or pointer focus', (
    tester,
  ) async {
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

    // Keyboard focus must not paint an outline.
    focus.requestFocus();
    await tester.pump();
    expect(_hasFocusRing(tester), isFalse);

    // Keyboard activation still works without a visible ring.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tapped, 1);

    // A pointer press focuses the button too, and must not leave an outline.
    await tester.tap(find.text('Browse Repository'));
    await tester.pump();
    expect(tapped, 2);
    expect(_hasFocusRing(tester), isFalse);
  });

  testWidgets('the ring is gone from the box, so focus cannot resize it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeumorphButton(
              label: 'View PDF',
              icon: Icons.remove_red_eye_outlined,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final node = tester
        .widget<Focus>(
          find
              .descendant(
                of: find.byType(NeumorphButton),
                matching: find.byType(Focus),
              )
              .first,
        )
        .focusNode!;

    final restSize = tester.getSize(find.byType(NeumorphButton));
    node.requestFocus();
    await tester.pump();
    final focusedSize = tester.getSize(find.byType(NeumorphButton));

    // The old ring wrapped the button in 3px of padding + a 2px border, so a
    // keyboard focus grew it by 10px and nudged the row. Removed entirely, the
    // box is identical focused and at rest.
    expect(focusedSize, restSize);
    expect(_hasFocusRing(tester), isFalse);
  });

  testWidgets('the icon button draws no ring when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeumorphIconButton(
              icon: Icons.bookmark_outline,
              tooltip: 'Save study',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final node = tester
        .widget<Focus>(
          find
              .descendant(
                of: find.byType(NeumorphIconButton),
                matching: find.byType(Focus),
              )
              .first,
        )
        .focusNode!;
    node.requestFocus();
    await tester.pump();
    expect(_hasFocusRing(tester), isFalse);
  });

  testWidgets('losing and regaining focus never draws an outline', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeumorphButton(
              label: 'View PDF',
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

    // Tap: the pointer focuses the button, no outline.
    await tester.tap(find.text('View PDF'));
    await tester.pump();
    expect(tapped, 1);
    expect(_hasFocusRing(tester), isFalse);

    // A browser opening a new tab (the PDF link) blurs the window; returning
    // re-focuses the previous node WITHOUT any new key input. Nothing may
    // appear — this was the "View PDF keeps an outline" bug.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    focus.requestFocus();
    await tester.pump();
    expect(
      _hasFocusRing(tester),
      isFalse,
      reason: 'regaining focus must not draw an outline',
    );
  });
}
