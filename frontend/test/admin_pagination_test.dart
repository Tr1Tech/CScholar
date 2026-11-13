// Admin table pagination.
//
// Users and Theses grow without bound, so they page at ten rows
// (kAdminTablePageSize) with the shared clay pager. Programs / Academic Years /
// Categories are small curated reference lists: they scroll, and must NOT gain
// a pager.
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
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:frontend/presentation/widgets/common/clay_pagination.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

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

ProviderContainer _container(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));

User _user(int id) => User(
  id: id,
  username: 'user $id',
  email: 'user$id@csu.edu.ph',
  passwordHash: '',
  role: 'student',
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Thesis _thesis(int id) => Thesis(
  id: id,
  title: 'Study $id',
  abstract: 'Abstract.',
  researchType: 'Thesis',
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.byTooltip('Next page');
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pump();
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('the user table pages at ten rows', (tester) async {
    await _pump(
      tester,
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(
            (ref) async => [for (var i = 0; i < 23; i++) _user(i)],
          ),
        ],
        child: _host(const AdminUserManagementScreen()),
      ),
    );

    expect(find.byType(GelAvatar), findsNWidgets(10));
    expect(find.text('user 0'), findsOneWidget);
    expect(find.text('user 10'), findsNothing);
    expect(find.text('Showing 1–10 of 23'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    await _tapNext(tester);

    expect(find.byType(GelAvatar), findsNWidgets(10));
    expect(find.text('user 0'), findsNothing);
    expect(find.text('user 10'), findsOneWidget);
    expect(find.text('Showing 11–20 of 23'), findsOneWidget);
    expect(find.text('Page 2 of 3'), findsOneWidget);

    await _tapNext(tester);

    // Last page carries the remainder, not a padded-out ten.
    expect(find.byType(GelAvatar), findsNWidgets(3));
    expect(find.text('Showing 21–23 of 23'), findsOneWidget);
    expect(find.text('Page 3 of 3'), findsOneWidget);
  });

  testWidgets('a new user search starts again at page one', (tester) async {
    await _pump(
      tester,
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(
            (ref) async => [for (var i = 0; i < 23; i++) _user(i)],
          ),
        ],
        child: _host(const AdminUserManagementScreen()),
      ),
    );

    await _tapNext(tester);
    expect(find.text('Page 2 of 3'), findsOneWidget);

    // "user 1" matches user 1 and 10..19 — eleven rows, so two pages.
    _container(tester, AdminUserManagementScreen)
        .read(adminSearchProvider(AdminSearchSection.users).notifier)
        .setQuery('user 1');
    await tester.pump();

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('Showing 1–10 of 11'), findsOneWidget);
  });

  testWidgets('the thesis table pages at ten rows', (tester) async {
    await _pump(
      tester,
      ProviderScope(
        overrides: [
          thesisListProvider.overrideWith(
            (ref, params) async => [for (var i = 0; i < 23; i++) _thesis(i)],
          ),
        ],
        child: _host(const AdminThesisManagementScreen()),
      ),
    );

    expect(find.byType(ThesisCover), findsNWidgets(10));
    expect(find.text('Study 10'), findsNothing);
    expect(find.text('Showing 1–10 of 23'), findsOneWidget);

    await _tapNext(tester);

    expect(find.byType(ThesisCover), findsNWidgets(10));
    expect(find.text('Study 10'), findsOneWidget);
    expect(find.text('Showing 11–20 of 23'), findsOneWidget);
  });

  testWidgets('the curated programs tab stays unpaginated', (tester) async {
    await _pump(
      tester,
      ProviderScope(
        overrides: [
          programsProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < 12; i++)
                Program(
                  id: i,
                  code: 'P$i',
                  name: 'Program $i',
                  college: 'College of Engineering',
                  createdAt: DateTime(2024),
                ),
            ],
          ),
        ],
        child: _host(const AdminProgramsScreen()),
      ),
    );

    expect(
      find.byType(ClayPagination),
      findsNothing,
      reason: 'programs are a curated list — they scroll, they do not page',
    );
  });
}
