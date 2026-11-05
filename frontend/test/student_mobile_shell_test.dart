import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_nav.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {double width = 390}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 844),
          disableAnimations: true,
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  setUp(() => CScholarMotion.ambientEnabled = false);
  tearDown(() => CScholarMotion.ambientEnabled = true);
  testWidgets('narrow layout uses the mobile shell with 4 tabs',
      (tester) async {
    await tester.pumpWidget(_host(
      const StudentLayout(
        currentIndex: 0,
        child: Text('dashboard body'),
      ),
    ));
    await tester.pump();

    expect(find.byType(MobileStudentScaffold), findsOneWidget);
    expect(find.byType(MobileStudentNav), findsOneWidget);
    // The nav is absolutely positioned over the scrolling body (prototype
    // `.bottom-nav`), not laid out as a footer that shrinks the content.
    expect(
      find.ancestor(
        of: find.byType(MobileStudentNav),
        matching: find.byType(Positioned),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(MobileStudentNav)).height, 78);
    expect(find.text('dashboard body'), findsOneWidget);
    for (final tab in ['Home', 'Search', 'Saved', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('depth screens hide the bottom nav', (tester) async {
    await tester.pumpWidget(_host(
      const MobileStudentScaffold(
        currentIndex: 1,
        isDepth: true,
        depthTitle: 'Thesis details',
        child: Text('detail body'),
      ),
    ));
    await tester.pump();

    expect(find.text('detail body'), findsOneWidget);
    expect(find.text('Thesis details'), findsOneWidget);
    expect(find.byType(MobileStudentNav), findsNothing);
  });

  testWidgets('StudentLayout forwards depth to the mobile shell',
      (tester) async {
    // The detail screen marks itself depth through the layout, so the check
    // above must hold for the public layout entry point too.
    await tester.pumpWidget(_host(
      const StudentLayout(
        currentIndex: 1,
        isDepth: true,
        depthTitle: 'Thesis details',
        child: Text('detail body'),
      ),
    ));
    await tester.pump();

    expect(find.text('detail body'), findsOneWidget);
    expect(find.text('Thesis details'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byType(MobileStudentNav), findsNothing);
  });

  testWidgets('wide layout keeps the desktop shell', (tester) async {
    await tester.pumpWidget(_host(
      const StudentLayout(
        currentIndex: 0,
        child: Text('dashboard body'),
      ),
      width: 1200,
    ));
    await tester.pump();

    expect(find.byType(MobileStudentScaffold), findsNothing);
    expect(find.text('dashboard body'), findsOneWidget);
  });

  testWidgets('toggling dark rebuilds the layout body', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Replicates main.dart: the scope lives at the app root and is driven
    // by the provider. The toggle below must flow through the scope into
    // the layout body — the exact path every mobile screen reads.
    await tester.pumpWidget(ProviderScope(
      child: _ThemeRoot(
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: MaterialApp(
            home: const StudentLayout(
              currentIndex: 0,
              child: _ThemeProbe(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('mode=light'), findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(StudentLayout)));
    await container.read(mobileThemeModeProvider.notifier).toggle();
    await tester.pump();

    expect(find.text('mode=dark'), findsOneWidget);
  });
}

/// App-root replica: watches the mode and re-provides the scope, exactly
/// like `CScholarApp.build` does above every route.
class _ThemeRoot extends ConsumerWidget {
  final Widget child;

  const _ThemeRoot({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CScholarMobileThemeScope(
      isDark: ref.watch(mobileThemeModeProvider),
      child: child,
    );
  }
}

/// Reads the theme inside the layout body — the exact call every mobile
/// screen makes. If the scope sat below the body (or `of` stopped
/// subscribing), the toggle would flip the shell but leave this frozen.
class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe();

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Text('mode=${t.isDark ? 'dark' : 'light'}');
  }
}
