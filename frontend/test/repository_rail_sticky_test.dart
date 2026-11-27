// The AI Recommendations rail floats below the top bar while the results
// scroll on web. The results and the rail share ONE scroll view, so the rail
// keeps its layout slot and is translated down as the page scrolls past it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/main.dart';
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
      thesisPageProvider.overrideWith(
        (ref, params) async => ThesisPage(
          theses: [for (var i = 1; i <= 30; i++) _thesis(i)],
          total: 30,
          page: 1,
          pages: 1,
          pageSize: 30,
        ),
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

/// Host that can flip the app palette exactly like the shipped theme switch:
/// the MaterialApp theme changes too, which is what replaces the scroll
/// position (the framework re-resolves scroll physics through `Theme.of`).
class _ThemeHost extends StatefulWidget {
  const _ThemeHost();

  @override
  State<_ThemeHost> createState() => ThemeHostState();
}

class ThemeHostState extends State<_ThemeHost> {
  bool _dark = false;

  late final GoRouter _router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(
        path: '/screen',
        builder: (_, _) => CScholarPaletteRebuild(
          builder: (context) => const RepositoryScreen(),
        ),
      ),
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, _) => CScholarPaletteRebuild(
          builder: (context) => const RepositoryScreen(),
        ),
      ),
    ],
  );

  void toggle() => setState(() => _dark = !_dark);

  @override
  Widget build(BuildContext context) {
    CScholarPalette.activate(_dark);
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_user()),
        thesisPageProvider.overrideWith(
          (ref, params) async => ThesisPage(
            theses: [for (var i = 1; i <= 30; i++) _thesis(i)],
            total: 30,
            page: 1,
            pages: 1,
            pageSize: 30,
          ),
        ),
      ],
      child: CScholarPaletteScope(
        isDark: _dark,
        onToggle: (_) => toggle(),
        child: CScholarMobileThemeScope(
          isDark: _dark,
          child: RepaintBoundary(
            child: MaterialApp.router(
              theme: cscholarThemeData(isDark: false),
              darkTheme: cscholarThemeData(isDark: true),
              themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: Duration.zero,
              routerConfig: _router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    // First load may reveal the skeleton; wait out its minimum display so the
    // measurements below describe the loaded page, not the placeholder.
    await tester.pump(const Duration(milliseconds: 800));

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

  testWidgets('the rail keeps floating after a theme flip', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);
    addTearDown(() => CScholarPalette.activate(false));

    await tester.pumpWidget(const _ThemeHost());
    // Same budget as the first test: the skeleton must have handed over before
    // the rail is measured.
    await tester.pump(const Duration(milliseconds: 800));

    final screen = find.byType(SingleChildScrollView).first;
    final viewportTop = tester.getRect(screen).top;
    final railFinder = find.byType(RecRail);

    await tester.dragFrom(
      tester.getRect(screen).centerLeft + const Offset(200, 0),
      const Offset(0, -800),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getRect(railFinder).top,
      moreOrLessEquals(viewportTop + 16, epsilon: 1),
      reason: 'setup: the rail must be pinned before the flip',
    );

    // A theme flip swaps ThemeData, which makes the framework replace the
    // ScrollPosition under the same ScrollableState. The rail must follow the
    // new position, not keep listening to the retired one.
    tester.state<ThemeHostState>(find.byType(_ThemeHost)).toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.dragFrom(
      tester.getRect(screen).centerLeft + const Offset(200, 0),
      const Offset(0, -200),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.getRect(railFinder).top,
      moreOrLessEquals(viewportTop + 16, epsilon: 1),
      reason: 'the rail froze after the theme flip',
    );
    expect(tester.takeException(), isNull);
  });
}
