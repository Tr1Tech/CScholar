import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/common/duplicate_dialog.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';

const _dupes = [
  DuplicateCandidate(
    id: 1,
    title: 'Student Academic Performance Risk Prediction Using Machine Learning',
    status: 'published',
    matchType: 'exact_title_and_abstract',
  ),
];

Future<bool?> _open(WidgetTester tester) {
  return showDuplicateConfirmDialog(
    tester.element(find.byKey(const Key('opener'))),
    _dupes,
  );
}

Widget _harness() => const MaterialApp(
      home: Scaffold(body: SizedBox(key: Key('opener'), width: 10, height: 10)),
    );

void main() {
  testWidgets('dialog caps at 480 wide on desktop, buttons fit', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_harness());
    final future = _open(tester);
    await tester.pumpAndSettle();

    expect(find.text('Possible duplicate found'), findsOneWidget);
    expect(find.textContaining('Student Academic Performance'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Submit anyway'), findsOneWidget);

    // The shell must hug the content instead of stretching full-width.
    final dialogWidth = tester.getSize(find.byType(Dialog)).width;
    expect(dialogWidth, lessThanOrEqualTo(500));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
  });

  testWidgets('dialog fits a 400px phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_harness());
    final future = _open(tester);
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialog), findsOneWidget);
    final dialogWidth = tester.getSize(find.byType(Dialog)).width;
    expect(dialogWidth, lessThanOrEqualTo(400));

    await tester.tap(find.text('Submit anyway'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });
}
