import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/student/saved_theses_screen.dart';

Thesis _thesis(int id, String type) => Thesis(
  id: id,
  title: 'Saved $type study $id',
  abstract: 'Abstract.',
  researchType: type,
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Widget _host(List<Thesis> saved) {
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (_, _) => const SavedThesesScreen()),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => const SavedThesesScreen()),
    ],
  );
  return ProviderScope(
    overrides: [savedThesesProvider.overrideWith((ref) async => saved)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpMobile(WidgetTester tester, Widget host) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(host);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Opens the saved-page filter sheet (same pattern as the search page) and
/// commits one research-type choice through "Show saved".
Future<void> _applyFilter(WidgetTester tester, String option) async {
  await tester.tap(find.byIcon(Icons.filter_list));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('RESEARCH TYPE'), findsOneWidget);

  await tester.tap(find.text(option));
  await tester.pump();
  await tester.tap(find.text('Show saved'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CScholarMotion.ambientEnabled = false;
  });
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('mobile library uses the search-page filter pill and sheet', (
    tester,
  ) async {
    await _pumpMobile(
      tester,
      _host([_thesis(2, 'Thesis'), _thesis(3, 'Capstone')]),
    );

    // The pill replaces the old segmented control, and the mixed list is
    // what opens by default.
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('2 saved studies'), findsOneWidget);
    expect(find.text('Saved Thesis study 2'), findsOneWidget);
    expect(find.text('Saved Capstone study 3'), findsOneWidget);

    await _applyFilter(tester, 'Thesis');
    expect(find.text('Saved Thesis study 2'), findsOneWidget);
    expect(find.text('Saved Capstone study 3'), findsNothing);
    expect(find.text('Filters (1)'), findsOneWidget);

    await _applyFilter(tester, 'Capstone');
    expect(find.text('Saved Thesis study 2'), findsNothing);
    expect(find.text('Saved Capstone study 3'), findsOneWidget);
  });

  testWidgets('an empty type offers a way back to all saves', (tester) async {
    await _pumpMobile(tester, _host([_thesis(3, 'Capstone')]));

    await _applyFilter(tester, 'Thesis');

    expect(find.text('No saved theses'), findsOneWidget);
    expect(
      find.text('Your saved studies are filed under another type.'),
      findsOneWidget,
    );
    expect(find.text('No saved studies'), findsNothing);

    await tester.tap(find.text('Show all saved'));
    await tester.pump();
    expect(find.text('Saved Capstone study 3'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
  });
}
