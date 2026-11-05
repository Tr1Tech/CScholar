// Label/value rows pin their value to the trailing edge.
//
// `_academicRow` (student profile) and `_infoRow` (faculty settings) used to
// reach the right edge as a side effect of `MainAxisAlignment.spaceBetween`.
// The profile row also paired `Expanded` with `Flexible` — both default to flex
// 1 — so the value was capped at half the row. They now follow the same rule as
// `PageHeader`: an `Expanded` label owns the remaining width and the value is a
// plain trailing child, capped at two thirds so a long value ellipsizes itself
// instead of squeezing the label to nothing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/faculty/faculty_settings_screen.dart';
import 'package:frontend/presentation/screens/student/profile_screen.dart';

// Wider than either row at 1440px: long enough that an uncapped value fills its
// two-thirds allowance and a half-capped one visibly stops short.
final _longEmail = 'a.${'verylongsegment' * 6}@university.edu.ph';

User _user({String role = 'student', String? email}) => User(
  id: 7,
  username: 'Alexandra Santos',
  email: email ?? 'a.santos@university.edu.ph',
  passwordHash: '',
  role: role,
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

Widget _host(Widget screen, {User? user, double textScale = 1}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      // Any `context.go(...)` target still resolves to something.
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return ProviderScope(
    overrides: [currentUserProvider.overrideWithValue(user)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
    ),
  );
}

Finder _rowForLabel(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1440, 1000);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('profile account row pins its value to the trailing edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ProfileScreen(), user: _user(email: _longEmail)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final row = _rowForLabel('Email');
    final value = find.descendant(of: row, matching: find.text(_longEmail));
    final rowRect = tester.getRect(row);
    final valueRect = tester.getRect(value);

    expect(
      valueRect.right,
      moreOrLessEquals(rowRect.right, epsilon: 1),
      reason:
          'the value must end at the row trailing edge, not depend on '
          'spaceBetween to push it there',
    );
    expect(
      valueRect.width,
      greaterThan(rowRect.width * 0.55),
      reason:
          'Expanded + Flexible both defaulted to flex 1, so the value '
          'was capped at half the row; it must be allowed its two-thirds '
          'cap.',
    );
  });

  testWidgets('profile identity card and account rows survive 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ProfileScreen(),
        user: _user(email: _longEmail),
        textScale: 2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);

    final row = _rowForLabel('Email');
    final value = find.descendant(of: row, matching: find.text(_longEmail));
    expect(
      tester.getRect(value).right,
      lessThanOrEqualTo(tester.getRect(row).right + 0.5),
    );
  });

  testWidgets(
    'faculty settings row pins a long value and keeps the label column',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const FacultySettingsScreen(),
          user: _user(role: 'faculty', email: _longEmail),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final row = _rowForLabel('Email');
      final value = find.descendant(of: row, matching: find.text(_longEmail));
      final rowRect = tester.getRect(row);
      final valueRect = tester.getRect(value);

      expect(
        valueRect.right,
        moreOrLessEquals(rowRect.right, epsilon: 1),
        reason:
            'the value must end at the row trailing edge, not depend on '
            'spaceBetween to push it there',
      );
      expect(
        valueRect.width,
        lessThanOrEqualTo(rowRect.width * 2 / 3 + 1),
        reason:
            'the value is capped at two thirds so the label always keeps '
            'a readable column',
      );
    },
  );

  testWidgets('faculty settings row survives 200% text without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FacultySettingsScreen(),
        user: _user(role: 'faculty', email: _longEmail),
        textScale: 2,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);

    final row = _rowForLabel('Email');
    final value = find.descendant(of: row, matching: find.text(_longEmail));
    expect(
      tester.getRect(value).right,
      lessThanOrEqualTo(tester.getRect(row).right + 0.5),
    );
  });
}
