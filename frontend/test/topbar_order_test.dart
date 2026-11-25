// Topbar order: the mode switch sits LEFT of the identity pill.
//
// Same order as the mobile header — the control must not jump sides between a
// phone and a desktop — and the pair still owns the top-right corner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/common/theme_toggle.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';

void main() {
  testWidgets('the switch is left of the identity pill, in the top-right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Topbar(
            trailing: const TopbarUserPill(
              name: 'radj.delarmente',
              role: 'Student',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final toggle = tester.getRect(find.byType(ThemeModeButton));
    final pill = tester.getRect(find.byType(TopbarUserPill));

    expect(
      toggle.right,
      lessThanOrEqualTo(pill.left),
      reason: 'the switch must sit before the identity pill',
    );
    expect(
      pill.left - toggle.right,
      moreOrLessEquals(10, epsilon: 1),
      reason: 'the pair is one cluster with a 10px gap',
    );
    expect(
      toggle.center.dy,
      moreOrLessEquals(pill.center.dy, epsilon: 1),
      reason: 'the two are vertically centred on each other',
    );
    // The cluster still hugs the bar's right padding (28).
    expect(pill.right, moreOrLessEquals(900 - 28, epsilon: 2));

    // Names and role still render inside the pill.
    expect(find.text('radj.delarmente'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.byType(ThemeModeButton), findsOneWidget);
  });

  testWidgets('a bar without a pill keeps the switch on the right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Topbar())));
    await tester.pump();

    final toggle = tester.getRect(find.byType(ThemeModeButton));
    expect(toggle.right, moreOrLessEquals(900 - 28, epsilon: 2));
  });
}
