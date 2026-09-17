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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register' || loc == '/';
      final role = authState.value?.role;

      // Not signed in: only public routes allowed
      if (authState.value == null) {
        if (loc == '/login' || loc == '/register' || loc == '/') return null;
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
            builder: (context, state) => const RepositoryScreen(),
          ),
          GoRoute(
            path: '/thesis/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
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
          GoRoute(
            path: '/recommendations',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Recommendations'))),
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
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
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

      // Fallback — must be last
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

      // Faculty routes
      GoRoute(
        path: '/faculty/dashboard',
        builder: (context, state) => const FacultyDashboardScreen(),
        redirect: (context, state) {
          final role = GoRouterState.of(context).extra as String?;
          if (role == 'admin') return '/admin/dashboard';
          return null;
        },
      ),
      GoRoute(
        path: '/faculty/theses',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty/students',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty/analytics',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty/settings',
        builder: (context, state) => const FacultyDashboardScreen(),
      ),
    ],
  );
});
