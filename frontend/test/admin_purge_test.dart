// The purge danger zone is the only in-app path that destroys a published or
// accessioned study. These lock the two things that make it deliberate: it
// exists only when editing a loaded record, and it demands both a reason and a
// typed confirmation before anything is sent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/admin/admin_add_edit_thesis_screen.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';

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

Thesis _thesis({String status = 'published'}) => Thesis(
  id: 1,
  title: 'A Published Study',
  abstract: 'Abstract.',
  researchType: 'Thesis',
  status: status,
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('purge demands a reason and a typed confirmation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisDetailProvider.overrideWith((ref, id) async => _thesis()),
        ],
        child: _host(const AdminAddEditThesisScreen(thesisId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DANGER ZONE'), findsOneWidget);

    await tester.ensureVisible(find.text('Purge this record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purge this record'));
    await tester.pumpAndSettle();

    expect(find.text('Purge record permanently'), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(GlassDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));

    // Empty reason: the dialog refuses and says what is missing.
    await tester.tap(find.text('Purge permanently'));
    await tester.pump();
    expect(
      find.text('Give a reason of at least 10 characters'),
      findsOneWidget,
    );

    // Reason supplied, confirmation still missing.
    await tester.enterText(
      fields.at(0),
      'Duplicate row created by a failed import',
    );
    await tester.tap(find.text('Purge permanently'));
    await tester.pump();
    expect(find.text('Type PURGE exactly'), findsOneWidget);

    // Backing out leaves the record alone.
    await tester.tap(
      find.descendant(
        of: find.byType(GlassDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Purge record permanently'), findsNothing);
  });

  testWidgets('a never-published draft points to the list, not purge', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisDetailProvider.overrideWith(
            (ref, id) async => _thesis(status: 'draft'),
          ),
        ],
        child: _host(const AdminAddEditThesisScreen(thesisId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The list already offers delete for this record; a second, stronger
    // removal action on the form would be redundant.
    expect(find.text('DANGER ZONE'), findsNothing);
    expect(find.text('Purge this record'), findsNothing);
    expect(find.textContaining('can be deleted from Thesis Management'),
        findsOneWidget);
  });

  testWidgets('an approved record still offers purge', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thesisDetailProvider.overrideWith(
            (ref, id) async => _thesis(status: 'approved'),
          ),
        ],
        child: _host(const AdminAddEditThesisScreen(thesisId: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // No list delete for a non-draft, so purge stays as the break-glass path.
    expect(find.text('DANGER ZONE'), findsOneWidget);
    expect(find.text('Purge this record'), findsOneWidget);
  });

  testWidgets('creating a thesis has no purge danger zone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: _host(const AdminAddEditThesisScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DANGER ZONE'), findsNothing);
    expect(find.text('Purge this record'), findsNothing);
  });
}
