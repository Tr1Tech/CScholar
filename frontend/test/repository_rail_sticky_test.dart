// The AI Recommendations rail floats below the top bar while the results
// scroll on web. The results and the rail share ONE scroll view, so the rail
// keeps its layout slot and is translated down as the page scrolls past it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/repository/repository_screen.dart';
import 'package:frontend/presentation/widgets/rec_rail.dart';

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

Thesis _thesis(int id) => Thesis(
  id: id,
  title: 'A Semantic Search Model for the CEIT Thesis Repository $id',
  abstract: 'Abstract.',
  researchType: id.isEven ? 'Thesis' : 'Capstone',
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

Widget _host() {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => const RepositoryScreen()),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => const RepositoryScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_user()),
      // Thirty cards make the page tall enough to scroll past the rail.
      thesisListProvider.overrideWith(
        (ref, params) async => [for (var i = 1; i <= 30; i++) _thesis(i)],
      ),
    ],
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

  testWidgets('AI rail pins below the top bar while results scroll', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 400));

    final screen = find.byType(SingleChildScrollView).first;
    final viewportTop = tester.getRect(screen).top;
    final railFinder = find.byType(RecRail);
    expect(railFinder, findsOneWidget);

    final restingTop = tester.getRect(railFinder).top;
    expect(
      restingTop,
      greaterThan(viewportTop + 16),
      reason: 'the rail starts below its pin at rest',
    );

    // Scroll well past the header and the rail's natural position.
    await tester.dragFrom(
      tester.getRect(screen).centerLeft + const Offset(200, 0),
      const Offset(0, -1000),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final pinnedTop = tester.getRect(railFinder).top;
    expect(
      pinnedTop,
      moreOrLessEquals(viewportTop + 16, epsilon: 1),
      reason: 'the rail must stay pinned below the top bar while scrolling',
    );
    expect(pinnedTop, lessThan(restingTop));
    expect(tester.takeException(), isNull);
  });
}
