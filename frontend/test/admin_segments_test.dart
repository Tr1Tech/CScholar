// The admin list pages share one filter language: a recessed segmented track
// with a raised pill. These lock the two new ones — the thesis type segment
// must reach the query, and the programs segment must drive its pager.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_thesis_management_screen.dart';

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

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('the thesis type segment reaches the list query', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    // The list is server-filtered, so what matters is the request: "All" must
    // send no type, and each segment must send its own. The rows themselves
    // are covered by admin_rows_test.
    final queries = <String?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisListProvider.overrideWith((ref, params) async {
            queries.add(params.researchType);
            return <Thesis>[];
          }),
        ],
        child: _host(const AdminThesisManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(queries.last, isNull, reason: '"All" sends no type filter');

    await tester.tap(find.text('Capstone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(queries.last, 'Capstone');

    await tester.tap(find.text('Thesis'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(queries.last, 'Thesis');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the programs segment drives the pager', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider.overrideWith(
            (ref) async => [
              Program(
                id: 1,
                code: 'BSCS',
                name: 'Computer Science',
                college: 'College of Engineering',
                createdAt: DateTime(2024),
              ),
            ],
          ),
          academicYearsProvider.overrideWith(
            (ref) async => [
              AcademicYear(
                id: 1,
                label: 'AY 2024-2025',
                startYear: 2024,
                endYear: 2025,
                isActive: true,
                createdAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminProgramsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Computer Science'), findsOneWidget);

    await tester.tap(find.text('Academic Years'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AY 2024-2025'), findsOneWidget);
    expect(find.text('Computer Science'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
