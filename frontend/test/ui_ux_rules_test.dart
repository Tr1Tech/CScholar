// MUST-level UI/UX rules for CScholar.
//
// Each test pins one contract from UI_UX_IMPLEMENTATION_RULES.md that is easy
// to regress during a later styling pass:
//   A11Y-1  tap targets are >=44x44
//   A11Y-4  icon-only controls are named
//   A11Y-12 form fields have programmatic labels
//   A11Y-14 errors are announced politely
//   CNT-4   users never see raw exception/status text
//   DS-11   a status has one spoken label
//   FRM-17  typed work is protected by a discard guard
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/common/discard_guard.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/services/api_service.dart';

Widget _host(Widget child, {double textScale = 1.0}) {
  CScholarPalette.activate(false);
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A11Y-12 programmatic field labels', () {
    testWidgets('NeumorphField exposes its label to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          NeumorphField(
            controller: controller,
            label: 'Institutional Email',
            hintText: 'you@example.com',
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(TextField));
      expect(node.label, contains('Institutional Email'));
      handle.dispose();
    });
  });

  group('A11Y-1 tap targets', () {
    testWidgets('NeumorphIconButton is at least 44x44 even at size 36', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NeumorphIconButton(
            icon: Icons.delete_outline,
            size: 36,
            tooltip: 'Delete thesis',
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(NeumorphIconButton));
      expect(size.width, greaterThanOrEqualTo(CScholarTapTarget.minimum));
      expect(size.height, greaterThanOrEqualTo(CScholarTapTarget.minimum));
    });

    testWidgets('the icon control still has its accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          NeumorphIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete thesis',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Delete thesis'), findsOneWidget);
      handle.dispose();
    });
  });

  group('DS-11 / A11Y-3 status vocabulary', () {
    testWidgets('a status chip speaks one compound label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ThesisStatusChip('published')));
      expect(
        tester.getSemantics(find.byType(ThesisStatusChip)).label,
        'Status: Published',
      );
      handle.dispose();
    });
  });

  group('A11Y-14 error announcements', () {
    testWidgets('AuthErrorBanner is a labelled live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AuthErrorBanner(error: 'Invalid credentials.')),
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Invalid credentials')),
      );
      expect(node.label, contains('Invalid credentials.'));
      expect(
        node.getSemanticsData().flagsCollection.isLiveRegion,
        isTrue,
        reason: 'an async sign-in failure must be announced',
      );
      handle.dispose();
    });
  });

  group('CNT-4 human-readable errors', () {
    test('never exposes a status code or response body', () {
      final expired = userFacingError(
        ApiException(401, '{"detail":"Invalid or expired token"}'),
        fallback: 'Could not load.',
      );
      final server = userFacingError(
        ApiException(500, 'Traceback (most recent call last)'),
        fallback: 'Could not load.',
      );
      final missing = userFacingError(
        ApiException(404, '{"detail":"not found"}'),
        fallback: 'Could not load.',
      );

      for (final copy in [expired, server, missing]) {
        expect(copy, isNot(contains('ApiException')));
        expect(copy, isNot(contains('{')));
        expect(copy, isNot(contains('Traceback')));
        expect(copy, isNot(contains('500')));
        expect(copy, isNotEmpty);
      }
      expect(expired, contains('session'));
      expect(server, contains('server'));
    });
  });

  group('FRM-17 discard guard', () {
    testWidgets('no dialog when there is nothing to lose', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final ok = await confirmDiscardChanges(
                  context,
                  hasChanges: false,
                );
                expect(ok, isTrue);
              },
              child: const Text('Leave'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsNothing);
    });

    testWidgets('asks before discarding typed work and can keep editing', (
      tester,
    ) async {
      var left = false;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                left = await confirmDiscardChanges(
                  context,
                  hasChanges: true,
                  actionLabel: 'my theses',
                );
              },
              child: const Text('Leave'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(left, isFalse);
    });
  });
}
