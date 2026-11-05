// An empty panel that already sits inside a card must not paint a card of its
// own: two rounded surfaces at different insets read as a rendering bug shot
// against the single-surface table card around them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/admin/admin_thesis_management_screen.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';

Widget _host() {
  final router = GoRouter(
    initialLocation: '/admin/thesis/management',
    routes: [
      GoRoute(
        path: '/admin/thesis/management',
        builder: (_, _) => const AdminThesisManagementScreen(),
      ),
      // Catch-all: the shell's nav targets all resolve to the table.
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, _) => const AdminThesisManagementScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      thesisListProvider.overrideWith((ref, params) async => <Thesis>[]),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  setUpAll(() => CScholarMotion.ambientEnabled = false);
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets('the thesis table wraps its empty panel in one card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No theses found'), findsOneWidget);
    expect(
      find.byType(CScholarCard),
      findsOneWidget,
      reason:
          'the empty panel must not add a second card inside the table card',
    );
    expect(tester.takeException(), isNull);
  });
}
