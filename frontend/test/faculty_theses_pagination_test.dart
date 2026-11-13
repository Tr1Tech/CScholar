// My Theses pages at ten rows, exactly like the admin tables — same constant,
// same clay pager — and a status filter starts a new result set on page one.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/faculty/faculty_theses_screen.dart';

Widget _host(Widget screen) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Thesis _thesis(int id) => Thesis(
  id: id,
  title: 'Study $id',
  abstract: 'Abstract.',
  researchType: 'Thesis',
  status: 'draft',
  programId: 1,
  academicYearId: 1,
  creatorId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        facultyThesesProvider.overrideWith(
          (ref) async => [for (var i = 0; i < 23; i++) _thesis(i)],
        ),
      ],
      child: _host(const FacultyThesesScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.byTooltip('Next page');
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('My Theses pages at ten rows', (tester) async {
    await _pump(tester);

    expect(find.text('Study 0'), findsOneWidget);
    expect(find.text('Study 10'), findsNothing);
    expect(find.text('Showing 1–10 of 23'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    await _tapNext(tester);

    expect(find.text('Study 0'), findsNothing);
    expect(find.text('Study 10'), findsOneWidget);
    expect(find.text('Showing 11–20 of 23'), findsOneWidget);
    expect(find.text('Page 2 of 3'), findsOneWidget);
  });

  testWidgets('a status filter starts the list again at page one', (
    tester,
  ) async {
    await _pump(tester);

    await _tapNext(tester);
    expect(find.text('Page 2 of 3'), findsOneWidget);

    // Every fixture is a draft, so the filter keeps the count and only the
    // page should move. The chips scrolled off-screen with the pager, so bring
    // them back before tapping.
    final draftChip = find.text('Draft');
    await tester.ensureVisible(draftChip);
    await tester.pump();
    await tester.tap(draftChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Page 1 of 3'), findsOneWidget);
    expect(find.text('Showing 1–10 of 23'), findsOneWidget);
  });
}
