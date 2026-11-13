import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/student/profile_screen.dart';

/// The mobile profile header (avatar, name, email, role chip) must sit on the
/// page's centre axis, matching the full-width stats and menu rows below it.
/// It used to shrink-wrap to the widest line and hug the left edge.
void main() {
  setUp(() => CScholarMotion.ambientEnabled = false);
  tearDown(() => CScholarMotion.ambientEnabled = true);

  testWidgets('mobile profile identity block is centred', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final user = User(
      id: 1,
      username: 'radj.delarmante',
      email: 'radj.delarmante@gmail.com',
      passwordHash: '',
      role: 'student',
      isActive: true,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          savedThesesProvider.overrideWith((ref) async => <Thesis>[]),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: const ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 390-wide page with 20px horizontal padding: the axis is at 195.
    const pageCenter = 195.0;
    for (final target in [
      // The profile's hero avatar, not the shell topbar's identity pill.
      find.descendant(of: find.byType(Hero), matching: find.text('RA')),
      find.text('radj.delarmante'),
      find.text('radj.delarmante@gmail.com'),
      find.text('Student'),
    ]) {
      expect(target, findsOneWidget);
      expect(tester.getCenter(target).dx, closeTo(pageCenter, 1));
    }
  });
}
