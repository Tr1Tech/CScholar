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

Widget _host({List<Program>? programs}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => const RepositoryScreen()),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => const RepositoryScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      if (programs != null)
        programsProvider.overrideWith((ref) async => programs),
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

  testWidgets('mobile search keeps the text the reader typed', (tester) async {
    tester.view.devicePixelRatio = 1;
    // Phone width: the mobile shell owns the screen.
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final field = find.byType(TextField).first;
    expect(field, findsOneWidget);

    // A trailing space while still composing ("machine " -> query "machine").
    // The build used to force the controller back to the trimmed query, which
    // erased the space and jumped the caret mid-type.
    await tester.enterText(field, 'machine ');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.widget<TextField>(field).controller!.text,
      'machine ',
      reason: 'the debounce rebuild must not rewrite what was typed',
    );
  });

  testWidgets('active filter chips sit inline instead of one per row', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        programs: [
          Program(
            id: 1,
            code: 'BSCS',
            name: 'Bachelor of Science in Computer Science',
            college: 'College of Engineering',
            createdAt: DateTime(2024),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Research Type -> Thesis. The type select is the only String dropdown
    // whose value is still null (the sort well shows 'Latest').
    final typeSelect = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<String> && widget.value == null,
    );
    await tester.tap(typeSelect);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thesis').last);
    await tester.pumpAndSettle();

    // Program -> the long BSCS name, the widest chip in the screenshot.
    final programSelect = find
        .byWidgetPredicate(
          (widget) => widget is DropdownButton<int> && widget.value == null,
        )
        .first;
    await tester.tap(programSelect);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bachelor of Science in Computer Science').last);
    await tester.pumpAndSettle();

    expect(find.text('2 active:'), findsOneWidget);

    final activeRow = find
        .ancestor(of: find.text('2 active:'), matching: find.byType(Wrap))
        .first;
    final chips = find.descendant(
      of: activeRow,
      matching: find.byType(InkWell),
    );
    expect(chips, findsNWidgets(2));

    // Each chip must shrink-wrap its label. An aligned Container inside the
    // Wrap expanded to the full line, so both chips took a whole row.
    final cardWidth = tester.getSize(find.byType(RepositoryScreen)).width;
    for (var i = 0; i < chips.evaluate().length; i++) {
      final size = tester.getSize(chips.at(i));
      expect(
        size.width,
        lessThan(cardWidth / 2),
        reason: 'a filter chip must not stretch to the card width',
      );

      // The pill itself is compact; only the invisible tap target keeps the
      // full 44px height.
      final pill = find
          .descendant(of: chips.at(i), matching: find.byType(Container))
          .first;
      expect(tester.getSize(pill).height, lessThan(CScholarTapTarget.minimum));
      expect(size.height, greaterThanOrEqualTo(CScholarTapTarget.minimum));
    }

    // Both chips share the label's line instead of stacking.
    final first = tester.getCenter(chips.first);
    final second = tester.getCenter(chips.last);
    expect(second.dy, closeTo(first.dy, 1));
  });
}
