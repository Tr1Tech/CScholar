// Mobile thesis card — the save toggle must be tappable at its centre.
//
// The toggle used to be a `Positioned` child of the eyebrow row's Stack. A
// Stack only hit-tests inside its own bounds, so the bottom two thirds of the
// 44px target fell through to the card's GestureDetector and opening a study
// was the only thing the bookmark could do on a phone. The mark is painted
// exactly where it was; only the hit-test relationship changed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';

Thesis _thesis() => Thesis(
  id: 7,
  title: 'Library Monitoring and Borrowing Information System',
  abstract: 'Abstract.',
  researchType: 'Capstone',
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  program: Program(
    id: 1,
    code: 'BSIT',
    name: 'Bachelor of Science in Information Technology',
    createdAt: DateTime(2024),
  ),
  authors: [
    Author(
      id: 1,
      firstName: 'Lilibeth L.',
      lastName: 'De Lima',
      createdAt: DateTime(2024),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onOpen,
  required VoidCallback onSave,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: MobileThesisCard(
                thesis: _thesis(),
                saved: false,
                onOpen: onOpen,
                onSave: onSave,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the bookmark mark saves instead of opening the study', (
    tester,
  ) async {
    var opens = 0;
    var saves = 0;
    await _pump(tester, onOpen: () => opens++, onSave: () => saves++);

    // Tapping the glyph itself lands in the middle of the 44px target — the
    // exact spot that used to be outside the eyebrow row's hit box.
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();

    expect(saves, 1);
    expect(opens, 0);
  });

  testWidgets('the rest of the card still opens the study', (tester) async {
    var opens = 0;
    var saves = 0;
    await _pump(tester, onOpen: () => opens++, onSave: () => saves++);

    await tester.tap(find.byType(MobileThesisCard));
    await tester.pump();

    expect(opens, 1);
    expect(saves, 0);
  });
}
