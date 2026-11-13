import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/repository/repository_screen.dart';

Thesis _thesis(int id) => Thesis(
  id: id,
  title: 'Study $id',
  abstract: 'Abstract.',
  researchType: 'Thesis',
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
      currentUserProvider.overrideWithValue(
        User(
          id: 1,
          username: 'student',
          email: 'student@example.com',
          passwordHash: '',
          role: 'student',
          isActive: true,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ),
      thesisPageProvider.overrideWith((ref, params) async {
        final page = params.page ?? 1;
        final start = (page - 1) * 10;
        final end = (start + 10).clamp(0, 25);
        return ThesisPage(
          theses: [for (var i = start; i < end; i++) _thesis(i)],
          total: 25,
          page: page,
          pages: 3,
          pageSize: 10,
        );
      }),
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

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('repository pages ten at a time', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Showing 1–10 of 25'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    final next = find.byTooltip('Next page');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Showing 11–20 of 25'), findsOneWidget);
    expect(find.text('Page 2 of 3'), findsOneWidget);
  });
}
