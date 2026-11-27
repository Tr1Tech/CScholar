// The admin lists now draw rows like Programs: an identity mark, a bold title
// with its context beneath, and the record's actions as raised round buttons.
// These lock that shape — a future edit must not quietly drop an action or
// regress to a bare table.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/admin/admin_programs_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_thesis_management_screen.dart';
import 'package:frontend/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

Widget _host(Widget screen) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('a thesis row carries its mark, context, and actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisListProvider.overrideWith(
            (ref, params) async => [
              Thesis(
                id: 1,
                title: 'A Semantic Search Model',
                abstract: 'Abstract.',
                researchType: 'Thesis',
                // Drafts are the only permanently deletable records, so this
                // row must carry the delete action.
                status: 'draft',
                programId: 1,
                academicYearId: 1,
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminThesisManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Rows are widgets, not DataRows: the mark, chips, and buttons live here.
    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(ThesisCover), findsOneWidget);
    expect(find.text('A Semantic Search Model'), findsOneWidget);
    // The status reads as a control: caret present, menu behind the same chip
    // palette as the read-only badge.
    // The caret belongs to the row's status control (the page's status filter
    // carries its own), so scope the finder to that control instead of the
    // whole screen.
    expect(
      find.descendant(
        of: find.byTooltip('Change status'),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Change status'), findsOneWidget);
    expect(find.byTooltip('View thesis'), findsOneWidget);
    expect(find.byTooltip('Edit thesis'), findsOneWidget);
    expect(find.byTooltip('Delete thesis'), findsOneWidget);
    // The subtitle explains why this row can be deleted.
    expect(find.textContaining('NEVER PUBLISHED'), findsOneWidget);
  });

  testWidgets('a published thesis is retired by archiving, not deletion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisListProvider.overrideWith(
            (ref, params) async => [
              Thesis(
                id: 2,
                title: 'A Published Study',
                abstract: 'Abstract.',
                researchType: 'Thesis',
                status: 'published',
                programId: 1,
                academicYearId: 1,
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminThesisManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The record is part of the repository: it leaves public view through the
    // status control, so the destructive action must not be offered at all.
    expect(find.byTooltip('Delete thesis'), findsNothing);
    expect(find.byTooltip('Change status'), findsOneWidget);
  });

  testWidgets('a retained draft has no delete action', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisListProvider.overrideWith(
            (ref, params) async => [
              Thesis(
                id: 3,
                title: 'A Restored Draft',
                abstract: 'Abstract.',
                researchType: 'Thesis',
                // A draft by status, but it was published before, so the
                // server refuses DELETE. The list must not offer it.
                status: 'draft',
                retained: true,
                everPublished: true,
                programId: 1,
                academicYearId: 1,
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminThesisManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Delete thesis'), findsNothing);
    expect(find.byTooltip('Edit thesis'), findsOneWidget);
    expect(find.byTooltip('Change status'), findsOneWidget);
    // And this row says why the trash icon is absent.
    expect(find.textContaining('PUBLISHED BEFORE'), findsOneWidget);
  });

  testWidgets('a user row carries its avatar, chips, and actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersProvider.overrideWith(
            (ref) async => [
              User(
                id: 1,
                username: 'radj',
                email: 'radj@csu.edu.ph',
                passwordHash: '',
                role: 'student',
                isActive: true,
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminUserManagementScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(GelAvatar), findsOneWidget);
    expect(find.text('radj'), findsOneWidget);
    expect(find.text('radj@csu.edu.ph'), findsOneWidget);
    expect(find.byType(RoleChip), findsOneWidget);
    expect(find.byType(ActiveChip), findsOneWidget);
    expect(find.byTooltip('Deactivate user'), findsOneWidget);
    expect(find.byTooltip('Edit user'), findsOneWidget);
  });

  testWidgets('a program row deletes behind a confirmation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsProvider.overrideWith(
            (ref) async => [
              Program(
                id: 1,
                code: 'BSCS',
                name: 'Computer Science',
                college: 'College of Engineering',
                createdAt: DateTime(2024),
              ),
            ],
          ),
        ],
        child: _host(const AdminProgramsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Delete program'), findsOneWidget);

    // Destructive work never fires on the first click: the row opens a
    // confirmation, and backing out leaves the record alone.
    await tester.tap(find.byTooltip('Delete program'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Delete "Computer Science"? This cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Computer Science'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
