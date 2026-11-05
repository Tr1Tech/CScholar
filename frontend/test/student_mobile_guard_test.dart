import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';

/// A notifier pre-seeded with a signed-in user, avoiding the real
/// [AuthNotifier.build] HTTP path. Seeding goes through the constructor
/// (not a cascade on `state`, which Riverpod rejects pre-mount).
class _SeededAuth extends AuthNotifier {
  final AsyncValue<User?> _seed;
  _SeededAuth(this._seed);

  @override
  AsyncValue<User?> build() => _seed;
}

Widget _host(Widget child, AuthNotifier auth) {
  return ProviderScope(
    overrides: [authProvider.overrideWith(() => auth)],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUp(() => CScholarMotion.ambientEnabled = false);
  tearDown(() => CScholarMotion.ambientEnabled = true);
  group('mobileRouteGuard', () {
    test('mobile faculty on a dashboard is bounced to login', () {
      expect(
        mobileRouteGuard(
          isMobileApp: true,
          role: 'faculty',
          location: '/faculty/dashboard',
          reason: null,
        ),
        '/login?reason=use-web',
      );
    });

    test('mobile admin on a student route is bounced to login', () {
      expect(
        mobileRouteGuard(
          isMobileApp: true,
          role: 'admin',
          location: '/repository',
          reason: null,
        ),
        '/login?reason=use-web',
      );
    });

    test('mobile admin at plain login gains the reason', () {
      expect(
        mobileRouteGuard(
          isMobileApp: true,
          role: 'admin',
          location: '/login',
          reason: null,
        ),
        '/login?reason=use-web',
      );
    });

    test('already at login with the reason settles', () {
      expect(
        mobileRouteGuard(
          isMobileApp: true,
          role: 'faculty',
          location: '/login',
          reason: 'use-web',
        ),
        isNull,
      );
    });

    test('mobile students pass through everywhere', () {
      for (final loc in [
        '/student/dashboard',
        '/repository',
        '/thesis/1',
        '/saved',
        '/profile',
        '/login',
      ]) {
        expect(
          mobileRouteGuard(
            isMobileApp: true,
            role: 'student',
            location: loc,
            reason: null,
          ),
          isNull,
          reason: loc,
        );
      }
    });

    test('web keeps its existing guards (never bounces here)', () {
      expect(
        mobileRouteGuard(
          isMobileApp: false,
          role: 'faculty',
          location: '/faculty/dashboard',
          reason: null,
        ),
        isNull,
      );
      expect(
        mobileRouteGuard(
          isMobileApp: false,
          role: 'admin',
          location: '/admin/dashboard',
          reason: null,
        ),
        isNull,
      );
    });

    test('signed-out sessions pass through to the router null check', () {
      expect(
        mobileRouteGuard(
          isMobileApp: true,
          role: null,
          location: '/repository',
          reason: null,
        ),
        isNull,
      );
    });
  });

  group('login use-web notice', () {
    testWidgets('signs out a restored faculty session and shows the notice',
        (tester) async {
      final faculty = User(
        id: 1,
        username: 'Dr. Santos',
        email: 'santos@example.com',
        passwordHash: '',
        role: 'faculty',
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(_host(
        const LoginScreen(reason: 'use-web'),
        _SeededAuth(AsyncValue.data(faculty)),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(LoginScreen)));

      expect(find.text(mobileOnlyNotice), findsOneWidget);
      expect(container.read(authProvider).value, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no notice without the reason', (tester) async {
      await tester.pumpWidget(_host(
        const LoginScreen(),
        _SeededAuth(const AsyncValue.data(null)),
      ));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(mobileOnlyNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
