// Per-screen render matrix — the states no widget test used to touch.
//
// A screen is normally only exercised when a human happens to open it at that
// window width with that text scale, which is how an overflow or a thrown
// builder ships. These are SMOKE tests: every screen is built in the eight
// combinations that break layouts (desktop/phone x high contrast x 100%/200%
// text) and must come up without an exception. They assert nothing about
// pixels — the tier suites own the look.
//
// Two deliberate choices:
//   * The screen is pumped inside a MINIMAL GoRouter, not the app router: the
//     real router redirects to /login whenever nobody is signed in, so a
//     signed-out harness would render the login screen 23 times and test
//     nothing. The minimal router exists only so `context.go(...)` inside a
//     callback has a GoRouter ancestor.
//   * Nothing is overridden in the ProviderScope. flutter_test blocks real
//     HTTP (every request comes back 400), so each screen lands in its own
//     error/empty branch — which is exactly the branch that renders least
//     often in development and most often in production.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/screens/admin/admin_add_edit_thesis_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_settings_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_thesis_management_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';
import 'package:frontend/presentation/screens/auth/register_screen.dart';
import 'package:frontend/presentation/screens/design_lab_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_analytics_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_dashboard_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_settings_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_students_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_theses_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_thesis_form_screen.dart';
import 'package:frontend/presentation/screens/repository/repository_screen.dart';
import 'package:frontend/presentation/screens/student/profile_screen.dart';
import 'package:frontend/presentation/screens/student/saved_theses_screen.dart';
import 'package:frontend/presentation/screens/student/student_dashboard_screen.dart';
import 'package:frontend/presentation/screens/thesis/thesis_detail_screen.dart';

/// Every screen, keyed by the label used in the test name. Screens that take
/// arguments get a representative one (an id that resolves to the error branch,
/// which is what a signed-out or offline client actually sees).
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'login': () => const LoginScreen(),
  'register': () => const RegisterScreen(),
  'design-lab': () => const DesignLabScreen(),
  'student dashboard': () => const StudentDashboardScreen(),
  'repository': () => const RepositoryScreen(),
  'repository with query': () => const RepositoryScreen(initialQuery: 'iot'),
  'thesis detail': () => const ThesisDetailScreen(thesisId: 1),
  'saved theses': () => const SavedThesesScreen(),
  'profile': () => const ProfileScreen(),
  'admin dashboard': () => const AdminDashboardScreen(),
  'admin thesis management': () => const AdminThesisManagementScreen(),
  'admin add thesis': () => const AdminAddEditThesisScreen(),
  'admin edit thesis': () => const AdminAddEditThesisScreen(thesisId: 1),
  'admin programs': () => const AdminProgramsScreen(),
  'admin users': () => const AdminUserManagementScreen(),
  'admin settings': () => const AdminSettingsScreen(),
  'faculty dashboard': () => const FacultyDashboardScreen(),
  'faculty theses': () => const FacultyThesesScreen(),
  'faculty thesis form': () => const FacultyThesisFormScreen(),
  'faculty students': () => const FacultyStudentsScreen(),
  'faculty analytics': () => const FacultyAnalyticsScreen(),
  'faculty settings': () => const FacultySettingsScreen(),
};

/// Hosts one screen with the a11y switches the shell reads from MediaQuery.
///
/// The entrance animation starts a controller on first build, so the pump below
/// uses a frame budget rather than `pumpAndSettle()` — a page that owns a
/// repeating loader (ClayLoader) never settles, by design.
Widget _host(
  Widget screen, {
  required bool highContrast,
  required double textScale,
}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      // Catch-all so any `context.go(...)` target still resolves to something.
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  );
}

void main() {
  // Auth restore reads prefs on first build; without this the plugin throws a
  // MissingPluginException and every screen fails for the wrong reason.
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  // The design lab now carries looping samples (PulseDot, BreathingGlow,
  // DriftingWash). The frame budget below stays, but the ambient gate makes
  // the loops opt-out here too so they cannot slow the 176-case matrix.
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  const sizes = <String, Size>{
    'desktop 1440x1000': Size(1440, 1000),
    'phone 400x860': Size(400, 860),
  };

  for (final entry in _screens.entries) {
    for (final sizeEntry in sizes.entries) {
      for (final highContrast in const [false, true]) {
        for (final textScale in const [1.0, 2.0]) {
          final label =
              '${entry.key} renders @ ${sizeEntry.key}'
              ' · high contrast $highContrast · text ${textScale}x';

          testWidgets(label, (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = sizeEntry.value;
            addTearDown(tester.view.reset);

            final screen = entry.value();
            await tester.pumpWidget(
              _host(screen, highContrast: highContrast, textScale: textScale),
            );
            await tester.pump(const Duration(milliseconds: 400));

            // The screen itself must be in the tree: a builder that throws is
            // replaced by an ErrorWidget, which would otherwise hide the
            // failure behind a clean `takeException()`.
            expect(find.byType(screen.runtimeType), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
