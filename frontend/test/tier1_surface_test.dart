// Tier 1 verification — the surfaces every dashboard shows.
//
// Tier 1 makes three promises that are easy to break silently, so they are
// pinned here rather than checked by eye:
//   1. status / role colours stay at WCAG AA (they were alpha-washed before)
//   2. KPI + metric cards are tactile (ClaySurface + ClayIconTile), not flat
//      hand-rolled `Container`s — and still fit the dashboards' grid ratios
//   3. the global theme carries the control recipes (buttons, chips, inputs)
//
// Contrast is computed from the live tokens, never from literals, so moving a
// colour back below 4.5:1 fails the build instead of shipping.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/widgets/common/kpi_card.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';

/// WCAG 2.1 contrast ratio, 1.0 (identical) to 21.0 (black on white).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Chip labels are 11px w700, which is NOT WCAG "large text" (that needs
/// 18.66px bold), so the 4.5:1 body floor applies — not the 3:1 graphics floor.
const double _aaBody = 4.5;

/// The neutral chip pair, shared by [ThesisStatusChip] and [ActiveChip].
const Color _clayNeutral = Color(0xFFE2EAE1);

/// Pins the test surface. Without this the harness renders at 800x600 and the
/// grid cells are far narrower than any real dashboard, which produces
/// overflow that the app never sees.
void _setSurface(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child, {bool highContrast = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: CScholarMaterial.canvas,
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _decorationOf(WidgetTester tester, Finder descendant) {
  return tester
      .widgetList<DecoratedBox>(
        find.ancestor(of: descendant, matching: find.byType(DecoratedBox)),
      )
      .first
      .decoration as BoxDecoration;
}

/// The dashboards place KPI cards in a `GridView` driven by
/// [kpiGridDelegate]; this mirrors that exactly, so a change to the shared
/// geometry is what this fixture exercises.
Widget _kpiGrid(BuildContext context, int columns) {
  return GridView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: kpiGridDelegate(context, columns),
    children: const [
      KpiCard(
        label: 'STUDIES',
        value: '128',
        trend: '+4 this week',
        icon: Icons.article_outlined,
        iconBg: Color(0xFFDCFCE7),
        iconColor: CScholarColors.primaryGreen,
      ),
      KpiCard(
        label: 'PROGRAMS',
        value: '7',
        trend: '7 CEIT programs',
        icon: Icons.school_outlined,
        iconBg: Color(0xFFFEF9C3),
        iconColor: Color(0xFFCA8A04),
      ),
      KpiCard(
        label: 'USERS',
        value: '512',
        trend: '480 active',
        icon: Icons.people_outline,
        iconBg: Color(0xFFFEF3C7),
        iconColor: CScholarColors.warningFg,
      ),
      KpiCard(
        label: 'SEARCHES',
        value: '10342',
        trend: '+12%',
        icon: Icons.search,
        iconBg: Color(0xFFDBEAFE),
        iconColor: CScholarColors.info,
      ),
    ],
  );
}

void main() {
  group('tier 1 — WCAG AA status tokens', () {
    test('every status chip pair clears 4.5:1', () {
      final pairs = <String, (Color, Color)>{
        'published':
            (CScholarColors.primaryGreen, CScholarColors.primaryGreenLight),
        'approved': (CScholarColors.info, CScholarColors.infoLight),
        'draft': (CScholarColors.adminColor, CScholarColors.adminLight),
        'other': (CScholarColors.textMuted, _clayNeutral),
        'role admin': (CScholarColors.adminColor, CScholarColors.adminLight),
        'role faculty':
            (CScholarColors.facultyColor, CScholarColors.facultyLight),
        'role student': (CScholarColors.studentColor, CScholarColors.infoLight),
        'active':
            (CScholarColors.primaryGreen, CScholarColors.primaryGreenLight),
        'inactive': (CScholarColors.textMuted, _clayNeutral),
      };

      pairs.forEach((name, pair) {
        final ratio = _contrast(pair.$1, pair.$2);
        expect(ratio, greaterThanOrEqualTo(_aaBody),
            reason: '$name is ${ratio.toStringAsFixed(2)}:1 — below WCAG AA');
      });
    });

    test('the retired low-contrast accents stay retired', () {
      // #9333EA (3.86:1 on #F3E8FF) and #2563EB on #DBEAFE (4.6:1 but it
      // degrades on clay) are what tier 1 replaced. Without this, someone could
      // revert one token and only the chip that uses it would regress.
      expect(CScholarColors.facultyColor, isNot(const Color(0xFF9333EA)));
      expect(CScholarColors.info, isNot(const Color(0xFF2563EB)));
      expect(_contrast(CScholarColors.facultyColor, CScholarColors.facultyLight),
          greaterThanOrEqualTo(_aaBody));
    });

    test('chip tints stay lighter than their ink', () {
      for (final pair in const [
        (CScholarColors.primaryGreen, CScholarColors.primaryGreenLight),
        (CScholarColors.info, CScholarColors.infoLight),
        (CScholarColors.adminColor, CScholarColors.adminLight),
        (CScholarColors.facultyColor, CScholarColors.facultyLight),
      ]) {
        expect(pair.$1.computeLuminance(),
            lessThan(pair.$2.computeLuminance()));
      }
    });
  });

  group('tier 1 — tactile status badges', () {
    testWidgets('chips carry a rim and a micro-shadow', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThesisStatusChip('Published'),
              ThesisStatusChip('Approved'),
              ThesisStatusChip('Draft'),
              ThesisStatusChip('Archived'),
              RoleChip('admin'),
              RoleChip('faculty'),
              RoleChip('student'),
              ActiveChip(true),
              ActiveChip(false),
            ],
          ),
        ),
      );

      // Shadow alone is not an affordance; every chip must also carry a border.
      for (final text in const [
        'PUBLISHED',
        'APPROVED',
        'DRAFT',
        'ARCHIVED',
        'admin',
        'faculty',
        'student',
        'ACTIVE',
        'INACTIVE',
      ]) {
        final decoration = _decorationOf(tester, find.text(text));
        expect(decoration.border, isNotNull, reason: '$text lost its rim');
        expect(decoration.boxShadow, isNotNull, reason: '$text lost its depth');
        expect(decoration.color, isNotNull, reason: '$text is not a solid pair');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('chips flatten to a strong rim under high contrast',
        (tester) async {
      await tester.pumpWidget(
        _host(const ThesisStatusChip('Published'), highContrast: true),
      );
      final decoration = _decorationOf(tester, find.text('PUBLISHED'));
      expect(decoration.boxShadow, isNull);
      final border = decoration.border as Border;
      expect(border.top.color, CScholarColors.textPrimary);
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 1 — tactile KPI surfaces', () {
    testWidgets('KPI card is clay, not a flat container', (tester) async {
      await tester.pumpWidget(
        _host(
          const KpiCard(
            label: 'STUDIES',
            value: '128',
            trend: '+4 this week',
            icon: Icons.article_outlined,
          ),
        ),
      );

      expect(find.byType(ClaySurface), findsOneWidget);
      expect(find.byType(ClayIconTile), findsOneWidget);
      expect(find.text('STUDIES'), findsOneWidget);
      // The value line counts up from zero, so it is asserted once the tween
      // has settled — and the first frame is asserted too, because a count-up
      // that lands complete on frame one is not a count-up.
      expect(find.text('128'), findsNothing,
          reason: 'the KPI value must animate up, not appear complete');
      await tester.pump(CScholarDurations.slow);
      await tester.pump();
      expect(find.text('128'), findsOneWidget);
      expect(find.text('+4 this week'), findsOneWidget);

      // The panel is clay: ONE soft shadow and no rim (the slab is the
      // boundary). The tile is a moulded object with its own gradient + rim.
      final panel = _decorationOf(tester, find.text('STUDIES'));
      expect(panel.boxShadow, hasLength(1),
          reason: 'the KPI slab is clay — one shadow, not a light/dark pair');
      final tile = _decorationOf(tester, find.byIcon(Icons.article_outlined));
      expect(tile.gradient, isNotNull);
      expect(tile.border, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KPI card survives every dashboard grid width', (tester) async {
      // Widths the three dashboards actually render at, including the narrow
      // 4-up desktop band (~1000px window) that used to crush the cards.
      const cases = <(double, int)>[
        (1600, 4),
        (1280, 4),
        (1000, 4),
        (880, 2),
        (600, 2),
        (360, 1),
      ];

      for (final probe in cases) {
        _setSurface(tester, probe.$1, 900);
        await tester.pumpWidget(
          _host(
            Builder(builder: (context) => _kpiGrid(context, probe.$2)),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'KPI grid overflowed at ${probe.$1}px '
                '(${probe.$2} columns)');
      }
    });

    testWidgets('KPI strip grows with the text scale instead of clipping',
        (tester) async {
      _setSurface(tester, 1280, 900);
      for (final scale in const [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 900))
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                backgroundColor: CScholarMaterial.canvas,
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        Builder(builder: (context) => _kpiGrid(context, 4)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'KPI grid clipped at text scale ${scale}x');
      }
    });

    testWidgets('KPI card drops its shadows under high contrast',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const KpiCard(
            label: 'STUDIES',
            value: '128',
            trend: '+4 this week',
            icon: Icons.article_outlined,
          ),
          highContrast: true,
        ),
      );
      expect(_decorationOf(tester, find.text('STUDIES')).boxShadow, isNull);
      final tile = _decorationOf(tester, find.byIcon(Icons.article_outlined));
      expect(tile.boxShadow, isNull);
      expect(tile.border, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KPI card survives 200% text scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(400, 900),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: KpiCard(
                    label: 'ARCHIVED STUDIES',
                    value: '12,480',
                    trend: 'since 2019',
                    icon: Icons.article_outlined,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 1 — global control recipes', () {
    testWidgets('the app theme carries every tier 1 control recipe',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CScholarApp()));
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = app.theme!;

      expect(theme.outlinedButtonTheme.style, isNotNull,
          reason: 'secondary buttons fell back to stock Material');
      expect(theme.textButtonTheme.style, isNotNull,
          reason: 'text buttons fell back to stock Material');
      expect(theme.elevatedButtonTheme.style, isNotNull);
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.chipTheme.shape, isNotNull,
          reason: 'chips fell back to stock Material');
      expect(theme.checkboxTheme.fillColor, isNotNull);
      expect(theme.switchTheme.trackColor, isNotNull);
      expect(theme.progressIndicatorTheme.color, CScholarColors.primaryGreen);
      expect(theme.tooltipTheme.decoration, isNotNull);
      expect(theme.listTileTheme.titleTextStyle, isNotNull);
      expect(theme.cardTheme.color, CScholarColors.surface);
      expect(theme.dialogTheme.backgroundColor, CScholarColors.surface);
      expect(theme.iconTheme.color, isNotNull);

      // One release recipe: primary actions never re-introduce elevation.
      expect(theme.filledButtonTheme.style!.elevation?.resolve({}), 0);
      expect(theme.elevatedButtonTheme.style!.elevation?.resolve({}), 0);

      // Secondary buttons wear the same 1.5px brand rim everywhere.
      final outline = theme.outlinedButtonTheme.style!.side?.resolve({});
      expect(outline?.color, CScholarColors.primaryGreen);
      expect(outline?.width, 1.5);
    });
  });
}
