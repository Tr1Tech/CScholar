// GoRouter configuration — CScholar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/screens/landing_screen.dart';
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
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_settings_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_dashboard_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_theses_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_thesis_form_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_students_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_analytics_screen.dart';
import 'package:frontend/presentation/screens/faculty/faculty_settings_screen.dart';
import 'package:frontend/presentation/screens/design_lab_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// DEV ONLY — the design lab is compiled out of release builds.
/// `dart.vm.product` is true only in AOT/release, so this stays on under
/// `flutter run` and `flutter run --profile` (so blur cost can be measured)
/// and disappears from `flutter build --release`.
const bool kEnableDesignLab = !bool.fromEnvironment('dart.vm.product');

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Don't bounce while auth is still restoring (login/loadToken).
      if (authState.isLoading) return null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register' || loc == '/';
      final role = authState.value?.role;

      // Not signed in: only public routes allowed
      if (authState.value == null) {
        if (loc == '/login' ||
            loc == '/register' ||
            loc == '/' ||
            (kEnableDesignLab && loc == '/design-lab')) {
          return null;
        }
        return '/login';
      }

      // Signed in: don't let them sit on login/register/landing
      if (loggingIn) {
        if (role == 'admin') return '/admin/dashboard';
        if (role == 'faculty') return '/faculty/dashboard';
        return '/student/dashboard';
      }

      // Student trying to access admin/faculty routes
      if (role != 'admin' && role != 'faculty' && (loc.startsWith('/admin') || loc.startsWith('/faculty'))) {
        return '/student/dashboard';
      }

      // Faculty trying to access admin routes
      if (role == 'faculty' && loc.startsWith('/admin')) {
        return '/faculty/dashboard';
      }

      // Faculty trying to access student-only routes (/thesis/:id is shared
      // and role-aware, so it stays accessible)
      if (role == 'faculty' && (loc.startsWith('/student') || loc == '/repository' || loc == '/saved' || loc == '/profile' || loc == '/recommendations')) {
        return '/faculty/dashboard';
      }

      // Admin trying to access student/faculty routes
      if (role == 'admin' && (loc.startsWith('/student') || loc.startsWith('/faculty') || loc == '/repository' || loc == '/saved' || loc == '/profile')) {
        return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // DEV ONLY design lab (clay / glass) — stripped from
      // release builds. Open at /design-lab to review the material system.
      if (kEnableDesignLab)
        GoRoute(
          path: '/design-lab',
          builder: (context, state) => const DesignLabScreen(),
        ),

      // Student shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/student/dashboard',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/repository',
            builder: (context, state) => RepositoryScreen(
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: '/thesis/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null || id <= 0) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Invalid thesis id: ${state.pathParameters['id']}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/repository'),
                          child: const Text('Back to Repository'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ThesisDetailScreen(thesisId: id);
            },
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedThesesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/thesis/management',
        builder: (context, state) => const AdminThesisManagementScreen(),
      ),
      GoRoute(
        path: '/admin/thesis/new',
        builder: (context, state) => const AdminAddEditThesisScreen(),
      ),
      GoRoute(
        path: '/admin/thesis/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return Scaffold(
              body: Center(child: Text('Invalid thesis id: ${state.pathParameters['id']}')),
            );
          }
          return AdminAddEditThesisScreen(thesisId: id);
        },
      ),
      GoRoute(
        path: '/admin/programs',
        builder: (context, state) => const AdminProgramsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // Faculty routes
      GoRoute(
        path: '/faculty/dashboard',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty/theses',
        builder: (context, state) => const FacultyThesesScreen(),
      ),
      GoRoute(
        path: '/faculty/thesis/new',
        builder: (context, state) => const FacultyThesisFormScreen(),
      ),
      GoRoute(
        path: '/faculty/thesis/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return Scaffold(
              body: Center(child: Text('Invalid thesis id: ${state.pathParameters['id']}')),
            );
          }
          return FacultyThesisFormScreen(thesisId: id);
        },
      ),
      GoRoute(
        path: '/faculty/students',
        builder: (context, state) => const FacultyStudentsScreen(),
      ),
      GoRoute(
        path: '/faculty/analytics',
        builder: (context, state) => const FacultyAnalyticsScreen(),
      ),
      GoRoute(
        path: '/faculty/settings',
        builder: (context, state) => const FacultySettingsScreen(),
      ),

      // Fallback — must be last (matches any unmatched location)
      GoRoute(
        path: '/:unmatched',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Page not found: ${state.matchedLocation}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
});
