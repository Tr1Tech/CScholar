// Material system smoke tests (clay / glass).
//
// These render the primitives in the states that are hardest to verify by eye:
// high contrast, global glass off, 200% text, and the smallest viewport. They
// exist to catch state-dependent throws (BackdropFilter.grouped, the glass
// switch, high contrast) and layout overflows — not to assert pixel output.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/screens/design_lab_screen.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';

Widget _host(
  Widget child, {
  bool highContrast = false,
  bool reduceMotion = false,
  double textScale = 1,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
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

void main() {
  testWidgets('clay surface casts one tinted shadow', (tester) async {
    await tester.pumpWidget(_host(const ClaySurface(child: Text('clay'))));
    final decoration = _decorationOf(tester, find.text('clay'));
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, hasLength(1),
        reason: 'clay is seated by ONE soft shadow — a second (light) shadow '
            'means the neumorphic pair is back');
    // The slab IS the boundary at rest; only high contrast draws a rim.
    expect(decoration.border, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clay surface drops shadows under high contrast',
      (tester) async {
    await tester.pumpWidget(
      _host(const ClaySurface(child: Text('clay')), highContrast: true),
    );
    final decoration = _decorationOf(tester, find.text('clay'));
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('glass blurs when enabled, inside one shared group',
      (tester) async {
    CScholarMaterial.glassEnabled = true;
    await tester.pumpWidget(
      _host(
        const GlassGroup(
          child: Column(
            children: [
              GlassPanel(child: Text('chrome')),
              GlassPanel(child: Text('overlay')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    expect(find.byType(BackdropGroup), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('glass degrades to a solid surface when the switch is off',
      (tester) async {
    CScholarMaterial.glassEnabled = false;
    addTearDown(() => CScholarMaterial.glassEnabled = true);
    await tester.pumpWidget(_host(const GlassPanel(child: Text('glass'))));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('glass'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all five control states render without throwing',
      (tester) async {
    for (final state in NeumorphState.values) {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              NeumorphButton(
                  label: 'Go', previewState: state, onPressed: () {}),
              NeumorphIconButton(
                icon: Icons.bookmark_outline,
                tooltip: 'Save',
                previewState: state,
                onPressed: () {},
              ),
              NeumorphToggle(
                  value: true, previewState: state, onChanged: (_) {}),
              NeumorphField(label: 'Keyword', previewState: state),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull,
          reason: 'state ${state.name} threw');
    }
  });

  testWidgets('disabled control ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        NeumorphButton(
          label: 'Go',
          previewState: NeumorphState.disabled,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 0);
  });

  testWidgets('toggle and segmented report changes', (tester) async {
    var flagged = false;
    var segment = 0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setLocal) => Column(
            children: [
              NeumorphToggle(
                value: flagged,
                label: 'Semantic',
                onChanged: (v) => setLocal(() => flagged = v),
              ),
              NeumorphSegmented(
                labels: const ['A', 'B', 'C'],
                selectedIndex: segment,
                onChanged: (i) => setLocal(() => segment = i),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AnimatedContainer));
    await tester.pumpAndSettle();
    expect(flagged, isTrue);

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(segment, 2);
  });

  testWidgets('identity objects and progress render', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            ClayIconTile(icon: Icons.article_outlined),
            GelAvatar(name: 'Juan Dela Cruz'),
            ClayChip(label: 'BSIT', selected: true),
            ClayProgressBar(value: 0.75),
          ],
        ),
      ),
    );
    expect(find.text('JC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon tile centres its glyph in both variants', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            ClayIconTile(icon: Icons.article_outlined, size: 44),
            ClayIconTile(icon: Icons.school_outlined, size: 44, gel: false),
          ],
        ),
      ),
    );

    // The tile must centre its glyph. A Stack defaults to topStart, which is
    // why the old InsetShadow wrapper silently pinned the glyph to the corner.
    for (final probe in const [
      (0, Icons.article_outlined),
      (1, Icons.school_outlined),
    ]) {
      final tile = tester.getRect(find.byType(ClayIconTile).at(probe.$1));
      final glyph = tester.getRect(find.byIcon(probe.$2));
      expect(glyph.center.dx, moreOrLessEquals(tile.center.dx, epsilon: 0.5),
          reason: 'tile ${probe.$1} glyph is not horizontally centred');
      expect(glyph.center.dy, moreOrLessEquals(tile.center.dy, epsilon: 0.5),
          reason: 'tile ${probe.$1} glyph is not vertically centred');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('gold tile emits a halo and keeps a dark glyph', (tester) async {
    await tester.pumpWidget(
      _host(
        const ClayIconTile(
            icon: Icons.workspace_premium_outlined, gold: true),
      ),
    );
    final decoration =
        _decorationOf(tester, find.byIcon(Icons.workspace_premium_outlined));
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow!.length, 3,
        reason: 'the halo needs a hot core + bloom + wide falloff');
    expect(decoration.gradient, isA<LinearGradient>());

    // Dark glyph on gold: measured 12.98:1 (top stop) to 6.08:1 (bottom stop).
    final glyph =
        tester.widget<Icon>(find.byIcon(Icons.workspace_premium_outlined));
    expect(glyph.color, CScholarMaterial.textPrimary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gold halo is dropped under high contrast', (tester) async {
    await tester.pumpWidget(
      _host(
        const ClayIconTile(
            icon: Icons.workspace_premium_outlined, gold: true),
        highContrast: true,
      ),
    );
    final decoration =
        _decorationOf(tester, find.byIcon(Icons.workspace_premium_outlined));
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controls survive 200% text scale', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            NeumorphButton(label: 'View Details', onPressed: () {}),
            NeumorphField(
              label: 'Keyword',
              hintText: 'Search the repository',
              errorText: 'Required',
            ),
            const ClayChip(label: 'BS Information Technology', selected: true),
          ],
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('design lab renders on desktop and on a small phone',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DesignLabScreen()));
    // Not pumpAndSettle: section 7 now carries ClayLoader, whose sweep repeats
    // forever by design, so "settled" is a state this page never reaches. A
    // frame budget longer than any entrance transition is what the assertions
    // actually need.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Design Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(400, 860);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Design Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
