// GoRouter configuration — CScholar

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';
import 'package:frontend/presentation/screens/auth/register_screen.dart';
import 'package:frontend/presentation/screens/student/student_dashboard_screen.dart';
import 'package:frontend/presentation/screens/repository/repository_screen.dart';
import 'package:frontend/presentation/screens/thesis/thesis_detail_screen.dart';
import 'package:frontend/presentation/screens/student/saved_theses_screen.dart';
import 'package:frontend/presentation/screens/student/profile_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_thesis_management_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_add_edit_thesis_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_bulk_import_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_settings_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_dashboard_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_theses_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_thesis_form_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_students_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_analytics_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_settings_screen.dart';
import 'package:frontend/presentation/screens/design_lab_screen.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// True on native mobile builds (Android/iOS). Web — even a narrow
/// browser window — keeps the full role-separated router; the
/// width-based student reskin lives in the widget shell, not here.
bool get isMobileApp => !kIsWeb;

/// Student-only gate for native mobile builds.
///
/// Returns `/login?reason=use-web` when a signed-in faculty/admin hits
/// any route on a native build, null otherwise. The login screen signs
/// the session out and shows the banner; the backend 403s + draft-hidden
/// 404s remain the safety net. Pure so it unit-tests without a router.
String? mobileRouteGuard({
  required bool isMobileApp,
  required String? role,
  required String location,
  required String? reason,
}) {
  if (!isMobileApp) return null;
  if (role != 'faculty' && role != 'admin') return null;
  if (location == '/login' && reason == 'use-web') return null;
  return '/login?reason=use-web';
}

/// Banner copy shared by the login screen's init (restored session) and
/// post-login (fresh sign-in) paths.
const String mobileOnlyNotice =
    'This app is student-only. Faculty and admin accounts — please use the web version.';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Wraps a route body so an app-wide palette swap reaches it.
///
/// The Navigator keeps the page widget it was handed, so rebuilding
/// `MaterialApp` with a new theme never rebuilds a route — measured, see
/// `test/theme_mode_test.dart`. [CScholarPaletteRebuild] is mounted INSIDE the
/// route and depends on the palette scope, so it is the one thing that hears
/// the flip and rebuilds the page once, while the transition curtain covers it.
Widget page(WidgetBuilder builder) => CScholarPaletteRebuild(builder: builder);

/// DEV ONLY — the design lab is compiled out of release builds.
/// `dart.vm.product` is true only in AOT/release, so this stays on under
/// `flutter run` and `flutter run --profile` (so blur cost can be measured)
/// and disappears from `flutter build --release`.
const bool kEnableDesignLab = !bool.fromEnvironment('dart.vm.product');

final appRouter = Provider<GoRouter>((ref) {
  // The router outlives auth changes: a provider that `ref.watch`es the auth
  // state rebuilds the whole GoRouter on every login/register/logout, and a
  // fresh router snaps back to `initialLocation` — which dumped a user on
  // /login mid-flow (registering an account lost its success state entirely).
  // Auth changes now just re-run the redirect through refreshListenable.
  final authTick = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => authTick.value++);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authTick,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      // Don't bounce while auth is still restoring (login/loadToken).
      if (authState.isLoading) return null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register';
      final role = authState.value?.role;

      // Native mobile is student-only: bounce faculty/admin to login with
      // a reason. The login screen signs them out and shows the banner.
      final mobileRedirect = mobileRouteGuard(
        isMobileApp: isMobileApp,
        role: role,
        location: loc,
        reason: state.uri.queryParameters['reason'],
      );
      if (mobileRedirect != null) return mobileRedirect;

      // Not signed in: only public routes allowed
      if (authState.value == null) {
        if (loc == '/login' ||
            loc == '/register' ||
            (kEnableDesignLab && loc == '/design-lab')) {
          return null;
        }
        return '/login';
      }

      // Signed in: don't let them sit on login/register. On mobile the
      // guard above already let non-students through to /login so the
      // screen can sign them out — don't bounce them back to a dashboard.
      if (loggingIn) {
        if (isMobileApp && (role == 'admin' || role == 'faculty')) {
          return null;
        }
        if (role == 'admin') return '/admin/dashboard';
        if (role == 'faculty') return '/faculty/dashboard';
        return '/student/dashboard';
      }

      // Student trying to access admin/faculty routes
      if (role != 'admin' &&
          role != 'faculty' &&
          (loc.startsWith('/admin') || loc.startsWith('/faculty'))) {
        return '/student/dashboard';
      }

      // Faculty trying to access admin routes
      if (role == 'faculty' && loc.startsWith('/admin')) {
        return '/faculty/dashboard';
      }

      // Faculty trying to access student-only routes (/thesis/:id is shared
      // and role-aware, so it stays accessible)
      if (role == 'faculty' &&
          (loc.startsWith('/student') ||
              loc == '/repository' ||
              loc == '/saved' ||
              loc == '/profile' ||
              loc == '/recommendations')) {
        return '/faculty/dashboard';
      }

      // Admin trying to access student/faculty routes
      if (role == 'admin' &&
          (loc.startsWith('/student') ||
              loc.startsWith('/faculty') ||
              loc == '/repository' ||
              loc == '/saved' ||
              loc == '/profile')) {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: '/login',
        builder: (context, state) => page(
          (_) => LoginScreen(
            reason: state.uri.queryParameters['reason'],
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => page((_) => const RegisterScreen()),
      ),

      // DEV ONLY design lab (clay / glass) — stripped from
      // release builds. Open at /design-lab to review the material system.
      if (kEnableDesignLab)
        GoRoute(
          path: '/design-lab',
          builder: (context, state) => page((_) => const DesignLabScreen()),
        ),

      // Student shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) =>
                page((_) => const StudentDashboardScreen()),
          ),
          GoRoute(
            path: '/repository',
            builder: (context, state) => page(
              (_) => RepositoryScreen(
                initialQuery: state.uri.queryParameters['q'],
                initialSemantic:
                    state.uri.queryParameters['mode'] == 'semantic',
              ),
            ),
          ),
          GoRoute(
            path: '/thesis/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null || id <= 0) {
                return page(
                  (_) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: CScholarColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Invalid thesis id: ${state.pathParameters['id']}',
                            style: TextStyle(
                              color: CScholarColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          NeumorphButton(
                            onPressed: () => context.go('/repository'),
                            label: 'Back to Repository',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // Semantic entry points (result cards, rails) hand their match
              // score through `extra` so the detail screen can meter it.
              // Direct loads and keyword entries carry no score — the meter
              // simply stays off rather than guessing one.
              return page(
                (_) => ThesisDetailScreen(
                  thesisId: id,
                  similarity: state.extra as double?,
                ),
              );
            },
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) =>
                page((_) => const SavedThesesScreen()),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => page((_) => const ProfileScreen()),
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) =>
            page((_) => const AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/thesis/management',
        builder: (context, state) =>
            page((_) => const AdminThesisManagementScreen()),
      ),
      GoRoute(
        path: '/admin/thesis/new',
        builder: (context, state) =>
            page((_) => const AdminAddEditThesisScreen()),
      ),
      GoRoute(
        path: '/admin/import',
        builder: (context, state) =>
            page((_) => const AdminBulkImportScreen()),
      ),
      GoRoute(
        path: '/admin/thesis/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return page(
              (_) => Scaffold(
                body: Center(
                  child: Text(
                    'Invalid thesis id: ${state.pathParameters['id']}',
                    style: TextStyle(color: CScholarColors.textPrimary),
                  ),
                ),
              ),
            );
          }
          return page((_) => AdminAddEditThesisScreen(thesisId: id));
        },
      ),
      GoRoute(
        path: '/admin/programs',
        builder: (context, state) =>
            page((_) => const AdminProgramsScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) =>
            page((_) => const AdminUserManagementScreen()),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) =>
            page((_) => const AdminSettingsScreen()),
      ),

      // Faculty routes
      GoRoute(
        path: '/faculty/dashboard',
        builder: (context, state) =>
            page((_) => const FacultyDashboardScreen()),
      ),
      GoRoute(
        path: '/faculty/theses',
        builder: (context, state) =>
            page((_) => const FacultyThesesScreen()),
      ),
      GoRoute(
        path: '/faculty/thesis/new',
        builder: (context, state) =>
            page((_) => const FacultyThesisFormScreen()),
      ),
      GoRoute(
        path: '/faculty/thesis/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return page(
              (_) => Scaffold(
                body: Center(
                  child: Text(
                    'Invalid thesis id: ${state.pathParameters['id']}',
                    style: TextStyle(color: CScholarColors.textPrimary),
                  ),
                ),
              ),
            );
          }
          return page((_) => FacultyThesisFormScreen(thesisId: id));
        },
      ),
      GoRoute(
        path: '/faculty/students',
        builder: (context, state) =>
            page((_) => const FacultyStudentsScreen()),
      ),
      GoRoute(
        path: '/faculty/analytics',
        builder: (context, state) =>
            page((_) => const FacultyAnalyticsScreen()),
      ),
      GoRoute(
        path: '/faculty/settings',
        builder: (context, state) =>
            page((_) => const FacultySettingsScreen()),
      ),

      // Fallback — must be last (matches any unmatched location)
      GoRoute(
        path: '/:unmatched',
        builder: (context, state) => page(
          (_) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: CScholarColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found: ${state.matchedLocation}',
                    style: TextStyle(color: CScholarColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  NeumorphButton(
                    onPressed: () => context.go('/login'),
                    label: 'Back to Sign In',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authTick.dispose();
  });
  return router;
});
