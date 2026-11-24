// App-wide light/dark mode: palette resolution, contrast, and the one
// mechanism that makes a palette flip reach a routed page.
//
// The contrast block is the guard for dark accents: a token can look fine in
// light and collapse at night (pale fill under white text, mint rim on a dark
// card). These are the pairs that break first.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/material/material_tokens.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Counts builds of the page under [CScholarPaletteRebuild].
class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.onBuild});

  final String label;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Text(label);
  }
}

Widget _host({required bool isDark, required Widget child}) {
  CScholarPalette.activate(isDark);
  return CScholarPaletteScope(
    isDark: isDark,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _routerHost({required bool isDark, required GoRouter router}) {
  CScholarPalette.activate(isDark);
  return CScholarPaletteScope(
    isDark: isDark,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  tearDown(() => CScholarPalette.activate(false));

  group('palette', () {
    test('flips every token between modes', () {
      CScholarPalette.activate(false);
      expect(CScholarMaterial.canvas, CScholarMobileColors.paper);
      expect(CScholarColors.textPrimary, CScholarMobileColors.ink);

      CScholarPalette.activate(true);
      expect(CScholarMaterial.canvas, CScholarMobileColors.paperDark);
      expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
      // A solid green fill must NOT become the mint ink: white text rides it.
      expect(CScholarColors.primaryFill, isNot(CScholarColors.primaryGreen));
      expect(
        CScholarColors.primaryFill.computeLuminance(),
        lessThan(CScholarColors.primaryGreen.computeLuminance()),
      );
    });

    test('dark body and accent inks clear AA on every surface', () {
      CScholarPalette.activate(true);
      for (final surface in <(String, Color)>[
        ('paper', CScholarMaterial.canvas),
        ('surface', CScholarMaterial.clay),
        ('well', CScholarMaterial.clayDeep),
      ]) {
        expect(
          _contrast(CScholarColors.textPrimary, surface.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'body ink on ${surface.$1}',
        );
        expect(
          _contrast(CScholarColors.textSecondary, surface.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'secondary ink on ${surface.$1}',
        );
        expect(
          _contrast(CScholarColors.primaryGreen, surface.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'accent ink on ${surface.$1}',
        );
        expect(
          _contrast(CScholarColors.error, surface.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'destructive ink on ${surface.$1}',
        );
        expect(
          _contrast(CScholarColors.violetInk, surface.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'faculty ink on ${surface.$1}',
        );
        // The hint is a placeholder only, so it owes the 3:1 object floor.
        expect(
          _contrast(CScholarColors.textHint, surface.$2),
          greaterThanOrEqualTo(3.0),
          reason: 'placeholder ink on ${surface.$1}',
        );
      }
      expect(
        _contrast(CScholarColors.textPrimary, CScholarMaterial.canvas),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('dark accent fills carry white text and keep an edge', () {
      CScholarPalette.activate(true);
      expect(_contrast(Colors.white, CScholarColors.primaryFill),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(Colors.white, CScholarMaterial.dangerFill),
          greaterThanOrEqualTo(4.5));
      // A filled control still has to separate from the page it sits on.
      expect(
        _contrast(CScholarColors.primaryFill, CScholarMaterial.canvas),
        greaterThanOrEqualTo(1.8),
      );
      expect(
        _contrast(CScholarColors.primaryFill, CScholarMaterial.clay),
        greaterThanOrEqualTo(1.6),
      );
    });

    test('dark tint/ink pairs stay readable', () {
      CScholarPalette.activate(true);
      expect(
        _contrast(CScholarColors.primaryGreen, CScholarColors.primaryGreenLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CScholarColors.violetInk, CScholarColors.violetTint),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CScholarColors.adminColor, CScholarColors.adminLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CScholarColors.tealInk, CScholarColors.tealTint),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(CScholarColors.skyInk, CScholarColors.skyTint),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark hairline stays decoration, not a boundary', () {
      CScholarPalette.activate(true);
      expect(
        _contrast(CScholarMaterial.rim, CScholarMaterial.clay),
        lessThan(2.0),
      );
      expect(
        _contrast(CScholarMaterial.clay, CScholarMaterial.canvas),
        greaterThan(1.05),
        reason: 'a card must still read as a card on the dark canvas',
      );
    });

    test('covers are mode-stable so white cover glyphs never flip', () {
      CScholarPalette.activate(false);
      final light = CScholarColors.coverGradients;
      CScholarPalette.activate(true);
      expect(identical(CScholarColors.coverGradients, light), isTrue);
    });
  });

  group('rebuild mechanism', () {
    testWidgets('a palette flip rebuilds the page under a route', (
      tester,
    ) async {
      // The Navigator keeps the page widget it was handed, so a root rebuild
      // never reaches a route (that is why every route body is wrapped). This
      // pins the wrapper's contract: it rebuilds when the scope flips.
      var builds = 0;
      await tester.pumpWidget(
        _host(
          isDark: false,
          child: CScholarPaletteRebuild(
            builder: (_) => _Counter(
              label: 'page',
              onBuild: () => builds++,
            ),
          ),
        ),
      );
      expect(find.text('page'), findsOneWidget);
      final first = builds;

      await tester.pumpWidget(
        _host(
          isDark: true,
          child: CScholarPaletteRebuild(
            builder: (_) => _Counter(
              label: 'page',
              onBuild: () => builds++,
            ),
          ),
        ),
      );
      expect(builds, greaterThan(first),
          reason: 'the wrapper must hear the scope flip');
    });

    testWidgets('the Navigator does NOT rebuild a cached route on its own', (
      tester,
    ) async {
      // Documents the reason the wrapper exists. A routed page is rebuilt only
      // when the Navigator is handed a NEW page; a root rebuild alone leaves it
      // on screen with its old colours — which is exactly the bug this whole
      // mechanism exists to prevent. If this ever starts failing, the wrapper
      // can be deleted.
      var builds = 0;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _Counter(
              label: 'routed',
              onBuild: () => builds++,
            ),
          ),
        ],
      );

      await tester.pumpWidget(_routerHost(isDark: false, router: router));
      await tester.pump();
      final first = builds;

      await tester.pumpWidget(_routerHost(isDark: true, router: router));
      await tester.pump();
      expect(builds, first, reason: 'the route kept the widget it was handed');
    });
  });
}
