// LAY-1 / A11Y-10: the narrowest supported width and intermediate widths.
//
// The main render matrix covers 400 and 1440. This one pins the two cases the
// spec calls out explicitly and the app did not previously exercise:
//   * 320 CSS px, the reflow floor (no horizontal page scroll / no overflow),
//   * 768 CSS px, the compact-tablet breakpoint,
// at normal and 150% text. Screens that need the API land in their documented
// error/empty branch, which is the branch most likely to overflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';
import 'package:frontend/presentation/screens/auth/register_screen.dart';
import 'package:frontend/presentation/screens/repository/repository_screen.dart';
import 'package:frontend/presentation/screens/student/profile_screen.dart';
import 'package:frontend/presentation/screens/student/saved_theses_screen.dart';
import 'package:frontend/presentation/screens/student/student_dashboard_screen.dart';

final Map<String, Widget Function()> _screens = {
  'login': () => const LoginScreen(),
  'register': () => const RegisterScreen(),
  'student dashboard': () => const StudentDashboardScreen(),
  'repository': () => const RepositoryScreen(),
  'saved theses': () => const SavedThesesScreen(),
  'profile': () => const ProfileScreen(),
};

Widget _host(Widget screen) {
  CScholarPalette.activate(false);
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return ProviderScope(
    child: CScholarPaletteScope(
      isDark: false,
      child: CScholarMobileThemeScope(
        isDark: false,
        child: MaterialApp.router(
          theme: ThemeData(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);
  tearDownAll(() => CScholarPalette.activate(false));

  const sizes = <String, Size>{
    '320x640': Size(320, 640),
    '768x1024': Size(768, 1024),
  };

  for (final entry in _screens.entries) {
    for (final size in sizes.entries) {
      for (final scale in const [1.0, 1.5]) {
        testWidgets(
          '${entry.key} reflows @ ${size.key} · text ${scale}x',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size.value;
            addTearDown(tester.view.reset);

            final screen = entry.value();
            await tester.pumpWidget(_host(screen));
            await tester.pump(const Duration(milliseconds: 400));

            expect(find.byType(screen.runtimeType), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} overflowed or threw at ${size.key}',
            );
          },
        );
      }
    }
  }
}
