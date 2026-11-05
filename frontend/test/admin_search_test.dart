// The admin topbar is shell chrome, so its field can only reach the page
// through shared state. These lock that wiring for the two pages that gained a
// search: the query on screen must filter THAT list, and a query typed
// elsewhere must not leak into it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';

User _user(int id, String name, String email, String role) => User(
  id: id,
  username: name,
  email: email,
  passwordHash: '',
  role: role,
  isActive: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Program _program(int id, String code, String name) => Program(
  id: id,
  code: code,
  name: name,
  // Deliberately free of either program's name: the filter also searches the
  // college line, and a fixture that repeats the needle would match everything.
  college: 'College of Engineering',
  createdAt: DateTime(2024),
);

Widget _host(Widget screen) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      // Catch-all: the shell's nav targets all resolve to the same page.
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

/// The provider scope behind [screen], for driving the topbar's shared state
/// from the test instead of typing into a field rendered in another subtree.
ProviderContainer _container(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('the users page filters on the topbar query', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(
            (ref) async => [
              _user(1, 'radj', 'radj@csu.edu.ph', 'student'),
              _user(2, 'maria', 'maria@csu.edu.ph', 'faculty'),
            ],
          ),
        ],
        child: _host(const AdminUserManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('radj'), findsOneWidget);
    expect(find.text('maria'), findsOneWidget);

    _container(tester, AdminUserManagementScreen)
        .read(adminSearchProvider(AdminSearchSection.users).notifier)
        .setQuery('mar');
    await tester.pump();

    expect(find.text('maria'), findsOneWidget);
    expect(
      find.text('radj'),
      findsNothing,
      reason: 'the search reached the users table',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the programs page filters the tab that is showing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider.overrideWith(
            (ref) async => [
              _program(1, 'BSCS', 'Computer Science'),
              _program(2, 'BSIT', 'Information Technology'),
            ],
          ),
        ],
        child: _host(const AdminProgramsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Computer Science'), findsOneWidget);

    // Type in the bar itself, the way a user would.
    await tester.enterText(find.byType(TextField), 'information');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Information Technology'), findsOneWidget);
    expect(
      find.text('Computer Science'),
      findsNothing,
      reason: 'the search reached the programs list',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('each list keeps its own query', (tester) async {
    // A query typed on Users must not filter the thesis table, and vice versa.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(
            (ref) async => [_user(1, 'radj', 'radj@csu.edu.ph', 'student')],
          ),
        ],
        child: _host(const AdminUserManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final container = _container(tester, AdminUserManagementScreen);
    container
        .read(adminSearchProvider(AdminSearchSection.theses).notifier)
        .setQuery('anything');
    await tester.pump();

    expect(
      container.read(adminSearchProvider(AdminSearchSection.users)),
      isEmpty,
      reason: 'a thesis query leaked into the users search',
    );
    expect(find.text('radj'), findsOneWidget);
  });
}
