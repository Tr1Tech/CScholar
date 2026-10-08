// Tier 2 verification — screen-level material migration.
//
// Tier 1 fixed the primitives; tier 2 moves the SCREENS onto them. These tests
// lock in the four migrations and, most importantly, the palette law that the
// migration exists to enforce:
//   1. topbar chrome is one shared clay kit (admin + faculty can't drift)
//   2. content cards are clay: a tonal fill + ONE soft shadow, no white box
//   3. banner/tint pairs that carry text stay at WCAG AA
//   4. no black-alpha shadows and no off-palette cool greys anywhere in lib/
//
// Test 4 is a source scan, not a widget test: the failure mode is a literal
// creeping back into a file that no widget test happens to render.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/result_card.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

/// WCAG 2.1 relative luminance contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The 10-13px labels these surfaces carry are NOT WCAG "large text", so the
/// 4.5:1 body floor applies.
const double _aaBody = 4.5;

Thesis _thesis({int id = 7, String type = 'Thesis'}) => Thesis(
      id: id,
      title: 'A Semantic Search Model for the CEIT Thesis Repository',
      abstract: 'Abstract.',
      researchType: type,
      status: 'published',
      programId: 1,
      academicYearId: 1,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Widget _host(Widget child, {bool highContrast = false, double width = 1200}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: CScholarMaterial.canvas,
          body: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _decorationOf(WidgetTester tester, Finder finder) {
  return tester
      .widgetList<DecoratedBox>(
        find.ancestor(of: finder, matching: find.byType(DecoratedBox)),
      )
      .first
      .decoration as BoxDecoration;
}

void main() {
  group('tier 2 — shared topbar chrome', () {
    testWidgets('search is a tonal clay well, not a white box',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(Topbar(leading: TopbarSearchField(controller: controller))),
      );

      final well = _decorationOf(tester, find.byType(TextField));
      expect(well.color, CScholarMaterial.clayDeep,
          reason: 'the search well lost its tonal clay fill');
      expect(well.border, isNull,
          reason: 'the search well grew an outline back — clay draws none at '
              'rest');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the clear affordance is opt-in and reports taps',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var clears = 0;

      await tester.pumpWidget(
        _host(Topbar(leading: TopbarSearchField(controller: controller))),
      );
      expect(find.byTooltip('Clear search'), findsNothing);

      await tester.pumpWidget(
        _host(Topbar(
          leading: TopbarSearchField(
            controller: controller,
            onClear: () => clears++,
          ),
        )),
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(clears, 1);
    });

    testWidgets('the search well draws a border only under high contrast',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          Topbar(leading: TopbarSearchField(controller: controller)),
          highContrast: true,
        ),
      );
      final well = _decorationOf(tester, find.byType(TextField));
      expect((well.border as Border).top.color, CScholarMaterial.rimStrong);
      expect((well.border as Border).top.width, 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the identity pill is a gel avatar on a raised clay pill',
        (tester) async {
      await tester.pumpWidget(
        _host(const Topbar(
          trailing: TopbarUserPill(name: 'Juan Dela Cruz', role: 'Faculty'),
        )),
      );

      expect(find.byType(GelAvatar), findsOneWidget);
      expect(find.text('JC'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);

      final pill = _decorationOf(tester, find.text('Juan Dela Cruz'));
      expect(pill.border, isNotNull,
          reason: 'a 40px pill is too small for a shadow alone to define it');
      expect(pill.boxShadow, hasLength(1),
          reason: 'a raised pill is seated by ONE soft clay shadow');
      // The shadow must be the tinted clay token, never a black alpha.
      expect(pill.boxShadow!.single.color.toARGB32(),
          isNot(const Color(0xFF000000).toARGB32()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a blank username still renders a labelled pill',
        (tester) async {
      await tester.pumpWidget(
        _host(const Topbar(trailing: TopbarUserPill(name: '   ', role: 'Admin'))),
      );
      expect(find.text('User'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin and faculty bars share the same kit', (tester) async {
      await tester.pumpWidget(
        _host(const FacultyTopbar()),
      );
      expect(find.byType(TopbarUserPill), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          child: _host(const AdminTopbar()),
        ),
      );
      await tester.pump();
      expect(find.byType(TopbarSearchField), findsOneWidget);
      expect(find.byType(TopbarUserPill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the search well fills its declared width', (tester) async {
      // The well is a fixed-width pill around a bare TextField. A loose
      // constraint would collapse the field to its intrinsic width, so pin the
      // rendered width instead.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(Topbar(
          leading: TopbarSearchField(controller: controller, width: 320),
        )),
      );

      // 320 wide, edge to edge: the well draws no rim at rest, and the field's
      // own 14px content padding is what keeps the text off the curve.
      expect(tester.getSize(find.byType(TextField)).width,
          closeTo(320, 1.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 2 — card surfaces', () {
    test('every thesis banner carries white text at WCAG AA', () {
      for (final stop in ThesisCard.bannerPalette) {
        final ratio = _contrast(const Color(0xFFFFFFFF), stop);
        expect(ratio, greaterThanOrEqualTo(_aaBody),
            reason: 'banner ${stop.toARGB32().toRadixString(16)} is '
                '${ratio.toStringAsFixed(2)}:1 — the 10px white label fails');
      }
    });

    test('the retired low-contrast banners stay retired', () {
      // #FF9900 was 2.14:1 and #0D9488 was 3.74:1 with white.
      expect(ThesisCard.bannerPalette,
          isNot(contains(const Color(0xFFFF9900))));
      expect(ThesisCard.bannerPalette,
          isNot(contains(const Color(0xFF0D9488))));
    });

    testWidgets('thesis card is clay with a solid white type pill',
        (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(height: 260, child: ThesisCard(thesis: _thesis()))),
      );

      expect(find.byType(ClaySurface), findsOneWidget,
          reason: 'thesis card went back to a hand-rolled white Container');
      expect(find.text('THESIS'), findsOneWidget);

      // The pill is white with dark ink (17.85:1) — the old 25%-white pill
      // composited to #409B4F and dropped white label text to 3.49:1.
      final pill = _decorationOf(tester, find.text('THESIS'));
      expect(pill.color, CScholarMaterial.shadowLight);
      final label = tester.widget<Text>(find.text('THESIS'));
      expect(label.style!.color, CScholarMaterial.textPrimary);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the match badge is legible on every banner', (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(
          height: 260,
          child: ThesisCard(thesis: _thesis(), similarityScore: 0.87),
        )),
      );
      expect(find.text('87% match'), findsOneWidget);
      final badge = _decorationOf(tester, find.text('87% match'));
      // Gold AI identity: goldSoft paper + amber ink (5.42:1), distinct from
      // green status chips.
      expect(badge.color, CScholarColors.goldSoft);
      final label =
          tester.widget<Text>(find.text('87% match'));
      expect(label.style!.color, CScholarColors.warningFg);
      expect(tester.takeException(), isNull);
    });

    testWidgets('result card keyword tokens are tonal wells',
        (tester) async {
      final thesis = Thesis(
        id: 3,
        title: 'An IoT Irrigation Controller for Upland Farms',
        abstract: 'Abstract.',
        researchType: 'Capstone',
        status: 'approved',
        programId: 1,
        academicYearId: 1,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        keywords: [
          Keyword(id: 1, term: 'IoT', createdAt: DateTime(2024)),
          Keyword(id: 2, term: 'irrigation', createdAt: DateTime(2024)),
        ],
      );

      await tester.pumpWidget(
        _host(ResultCard(
          thesis: thesis,
          isSaved: false,
          onToggleSave: () {},
        )),
      );

      expect(find.text('IoT'), findsOneWidget);
      final well = _decorationOf(tester, find.text('IoT'));
      expect(well.color, CScholarMaterial.clayDeep,
          reason: 'keyword chips fell back to the canvas fill (a hole)');
      expect(well.border, isNotNull);
      // The type token carries a rim now, like every other chip.
      expect(_decorationOf(tester, find.text('Capstone')).border, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 2 — layout chrome', () {
    testWidgets('the mobile shell app bar is clay, not white', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: CScholarShell(
            sidebar: SizedBox.shrink(),
            mobileTitle: 'CScholar',
            child: SizedBox.shrink(),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, CScholarMaterial.clay);
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0,
          reason: 'M3 tints the bar on scroll unless this is zeroed');
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 2 — palette law', () {
    test('clay casts ONE tinted shadow — no second light source', () {
      // clayDrop used to pair its tinted dark shadow with a white top-left
      // highlight. Two opposing lights only read as depth when the surface
      // matches its background exactly, which is why that style always needed a
      // drawn rim to be findable — and why the rim / inset / highlight trio went
      // out together. Clay seats a slab with a single light from above.
      final drop = CScholarMaterial.clayDrop();
      expect(drop, hasLength(1),
          reason: 'clay is ONE soft shadow; a second (light) shadow means the '
              'neumorphic layer is coming back');

      final shade = drop.single;
      // Tinted, never black-alpha: black on sage reads as dirt, not depth.
      expect(shade.color.r, greaterThan(0.5),
          reason: 'the shadow must be the tinted clay token');
      expect(shade.color, isNot(CScholarMaterial.shadowLight),
          reason: 'white is not a shadow');
      // It falls DOWNWARD. A shadow that creeps sideways or upward is a second
      // light source wearing a shadow's clothes.
      expect(shade.offset.dy, greaterThan(0));
      expect(shade.offset.dx, 0);
    });

    test('no black-alpha shadows or off-palette greys remain in lib/', () {
      // The exact literals tier 2 removed. A black-alpha shadow on the sage
      // canvas reads as dirt rather than depth, and these cool greys belong to
      // no hue family in this system.
      const banned = <String, String>{
        'Colors.black': 'black-alpha shadow — use the tinted clay/scrim tokens',
        '0xFFF9FAFB': 'off-palette cool white — use CScholarMaterial.clayHigh',
        '0xFFF1F5F9': 'off-palette slate — use clayDeep / dividerLight, or '
            'CScholarMaterial.rim for a hairline',
        '0xFFF3F4F6': 'off-palette grey canvas — use CScholarMaterial.canvas',
        '0xFFE2E8F0': 'off-palette slate — use CScholarMaterial.rim',
        '0xFFF8FAFC': 'off-palette cool canvas — use CScholarMaterial.canvas',
        '0xFFF2F7F1': 'retired canvas — use CScholarMaterial.canvas',
      };

      final offences = <String>[];
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      // A source scan that scans nothing always passes. Pin the corpus size so
      // a moved lib/ or a broken glob fails loudly instead.
      expect(files.length, greaterThan(40),
          reason: 'the palette scan found almost no sources — is lib/ still at '
              'the package root?');

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          banned.forEach((literal, why) {
            if (lines[i].contains(literal)) {
              offences.add('${file.path}:${i + 1} [$literal] $why');
            }
          });
        }
      }

      expect(offences, isEmpty,
          reason: 'palette law broken:\n${offences.join('\n')}');
    });
  });
}
