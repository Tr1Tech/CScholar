// The faculty list must flag a returned draft on the row itself: the submitter
// should not have to open every card to discover it came back. The note stays
// on the detail page.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/faculty/faculty_theses_screen.dart';

Widget _host(Widget screen, {double textScale = 1}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  );
}

Thesis _returnedDraft() => Thesis(
  id: 20,
  title: 'TEST2',
  abstract: 'Abstract.',
  researchType: 'Capstone',
  status: 'draft',
  programId: 1,
  academicYearId: 1,
  creatorId: 1,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  reviewNotes: 'idk',
);

Future<void> _pumpRow(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        facultyThesesProvider.overrideWith((ref) async => [_returnedDraft()]),
      ],
      child: _host(const FacultyThesesScreen(), textScale: textScale),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('marker sits beside DRAFT on a wide row, note hidden', (
    tester,
  ) async {
    await _pumpRow(tester, size: const Size(1440, 900));

    final marker = find.text('RETURNED FOR REVISION');
    final status = find.text('DRAFT');
    expect(marker, findsOneWidget);
    expect(status, findsOneWidget);
    expect(find.textContaining('idk'), findsNothing);

    expect(
      tester.getRect(marker).right,
      lessThanOrEqualTo(tester.getRect(status).left),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('marker stacks above DRAFT on a phone without overflow', (
    tester,
  ) async {
    await _pumpRow(tester, size: const Size(400, 900), textScale: 2);

    final marker = find.text('RETURNED FOR REVISION');
    final status = find.text('DRAFT');
    expect(marker, findsOneWidget);
    expect(status, findsOneWidget);
    expect(find.textContaining('idk'), findsNothing);

    expect(
      tester.getRect(marker).bottom,
      lessThanOrEqualTo(tester.getRect(status).top),
    );
    expect(tester.takeException(), isNull);
  });
}
