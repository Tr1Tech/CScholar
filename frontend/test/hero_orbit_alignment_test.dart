// The dashboard hero's decorative orbit is pinned to the hero's trailing edge.
//
// It used to be centred inside its 4/11 flex column, which left ~140px of dead
// gutter on the right while the greeting sat 28px from the left edge — the
// banner's outer margins were visibly asymmetric. The mobile composition
// anchors the orbit to the right (`right: -3`), so the wide hero matches it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/student/student_dashboard_screen.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_widgets.dart';

User _user() => User(
  id: 1,
  username: 'radj.delarmente',
  email: 'radj@example.com',
  passwordHash: '',
  role: 'student',
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

Widget _host() {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/screen',
        builder: (_, _) => const StudentDashboardScreen(),
      ),
      // Any `context.go(...)` target still resolves to something.
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, _) => const StudentDashboardScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [currentUserProvider.overrideWithValue(_user())],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('dashboard hero orbit sits on the hero trailing edge', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 400));

    final orbitFinder = find.byType(MobileResearchOrbit);
    final orbit = tester.getRect(orbitFinder);
    final row = tester.getRect(
      find.ancestor(of: orbitFinder, matching: find.byType(Row)).first,
    );
    final hero = tester.getRect(
      find.ancestor(of: orbitFinder, matching: find.byType(ClaySurface)).first,
    );
    final greeting = tester.getRect(find.textContaining('Good ').first);

    expect(
      orbit.right,
      moreOrLessEquals(row.right, epsilon: 1),
      reason:
          'the orbit must end on the hero content trailing edge, not '
          'float in the middle of its flex column',
    );
    expect(
      greeting.left - hero.left,
      moreOrLessEquals(hero.right - orbit.right, epsilon: 1),
      reason:
          'the hero outer margins must match: the greeting starts at the '
          'left padding and the orbit ends at the right padding',
    );
  });

  // Shrinking the browser below the two-column breakpoint used to drop the
  // orbit entirely (`if (isNarrow) return left`). The hero keeps it beside the
  // greeting at every desktop width, scaling down only when space is tight.
  for (final width in const [810.0, 1000.0]) {
    testWidgets('dashboard hero keeps its orbit at ${width.toInt()}px wide', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host());
      await tester.pump(const Duration(milliseconds: 400));

      final orbitFinder = find.byType(MobileResearchOrbit);
      expect(
        orbitFinder,
        findsOneWidget,
        reason: 'the hero must never lose its illustration when narrowing',
      );

      final orbit = tester.getRect(orbitFinder);
      final row = tester.getRect(
        find.ancestor(of: orbitFinder, matching: find.byType(Row)).first,
      );
      final hero = tester.getRect(
        find
            .ancestor(of: orbitFinder, matching: find.byType(ClaySurface))
            .first,
      );
      final greeting = tester.getRect(find.textContaining('Good ').first);

      expect(orbit.width, lessThanOrEqualTo(128));
      expect(
        orbit.right,
        moreOrLessEquals(row.right, epsilon: 1),
        reason: 'the narrow orbit still ends on the hero trailing edge',
      );
      expect(
        greeting.left - hero.left,
        moreOrLessEquals(hero.right - orbit.right, epsilon: 1),
        reason: 'the hero outer margins must stay symmetric when narrow',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
