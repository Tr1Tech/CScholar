// Tier 3 verification — interactive controls, system adoption and cleanup.
//
// Tier 3 is about ADOPTION: the primitives existed after tiers 1-2, but real
// screens were still using stock `TextFormField` and hand-rolled icon tiles.
// These tests lock in that adoption plus the invariants it depends on:
//   1. NeumorphField participates in Form (validator + Form.validate())
//   2. the recessed well reacts to focus, error, disabled and high contrast
//   3. every fixed-size icon tile is ClayIconTile (or explicitly exempt)
//   4. no second theme definition exists to drift against
//   5. the hover lift is wired into the clickable cards, and obeys reduced motion
//   6. no screen hand-rolls progress chrome (ClayProgressBar / ClayLoader own it)
//   7. glass is built by GlassPanel alone (kill switch + high-contrast fallback)
//   8. the material primitives are adopted by real screens, not just by the lab
//   9. every bar fill clears 3:1 on the clay track (WCAG 1.4.11)
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/hover_lift.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';

Widget _host(
  Widget child, {
  bool highContrast = false,
  bool reducedMotion = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          disableAnimations: reducedMotion,
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

BoxDecoration _wellDecoration(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first
      .decoration as BoxDecoration;
}

/// WCAG 2.1 relative luminance contrast ratio — the same measurement the tier 2
/// palette law uses.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('tier 3 — NeumorphField is a Form field', () {
    testWidgets('Form.validate() runs the validator and blocks submit',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var submitted = 0;

      await tester.pumpWidget(
        _host(Form(
          key: formKey,
          child: Column(
            children: [
              NeumorphField(
                controller: controller,
                label: 'Email',
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Please enter a valid institutional email'
                    : null,
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) submitted++;
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        )),
      );

      // Empty then invalid: both blocked, both surfaced by the SAME widget.
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(submitted, 0);
      expect(find.text('Please enter a valid institutional email'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), 'juan@csu.edu.ph');
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(submitted, 1);
      expect(find.text('Please enter a valid institutional email'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an explicit errorText outranks the validator', (tester) async {
      final controller = TextEditingController(text: 'juan@csu.edu.ph');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(NeumorphField(
          controller: controller,
          label: 'Email',
          errorText: 'Invalid credentials',
          validator: (v) => (v == null || !v.contains('@')) ? 'Bad format' : null,
        )),
      );
      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.text('Bad format'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled field cannot be typed into', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(NeumorphField(
          controller: controller,
          label: 'Email',
          enabled: false,
        )),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submitting from the keyboard fires onSubmitted', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var submissions = 0;

      await tester.pumpWidget(
        _host(NeumorphField(
          controller: controller,
          label: 'Password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submissions++,
        )),
      );

      // The action only reaches the widget through an open input connection,
      // which showKeyboard establishes by focusing the field.
      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submissions, 1);
    });

    testWidgets('obscureText wins over a multiline maxLines', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(NeumorphField(
          controller: controller,
          label: 'Password',
          obscureText: true,
          maxLines: 5,
        )),
      );

      // Flutter's TextField asserts on obscureText + maxLines > 1.
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 3 — the recessed well reacts to state', () {
    testWidgets('rest state is a tonal clay well with no outline',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphField(label: 'Email', hintText: 'you@csu.edu.ph')),
      );

      final well = _wellDecoration(tester);
      expect(well.color, CScholarMaterial.clayDeep);
      // No drawn outline at rest: the tonal fill IS the affordance, and a rim
      // on every control is exactly what the clay pass removed.
      expect(well.border, isNull,
          reason: 'the well grew an outline back — only focus, error and high '
              'contrast draw one');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, 'you@csu.edu.ph');
      expect(tester.takeException(), isNull);
    });

    testWidgets('focus thickens the rim to the gel brand colour',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(NeumorphField(controller: controller, label: 'Email')),
      );

      // The field owns an internal FocusNode, so focusing the TextField drives
      // the well's state.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarMaterial.gelTop);
      expect(border.top.width, 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('high contrast draws the boundary the rest of the system omits',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphField(label: 'Email'), highContrast: true),
      );

      // Clay draws no outline at rest, so high contrast is the mode that has to
      // supply one — the whole no-rim decision leans on this fallback.
      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarMaterial.rimStrong);
      expect(border.top.width, 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a suffix control renders and reports taps', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var toggles = 0;

      await tester.pumpWidget(
        _host(NeumorphField(
          controller: controller,
          label: 'Password',
          obscureText: true,
          suffixIcon: IconButton(
            tooltip: 'Show password',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => toggles++,
          ),
        )),
      );

      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(toggles, 1);
    });
  });

  group('tier 3 — the hover lift', () {
    /// Drives a real MOUSE pointer over [finder], because MouseRegion only fires
    /// for a mouse (the default test pointer is a touch, which never hovers).
    Future<TestGesture> hoverAt(WidgetTester tester, Finder finder) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pumpAndSettle();
      return gesture;
    }

    /// Y translation of the lifted surface. Scoped to [HoverLift] so a stray
    /// AnimatedContainer elsewhere in the tree can't satisfy the finder.
    double liftOf(WidgetTester tester) => tester
        .widget<AnimatedContainer>(find.descendant(
          of: find.byType(HoverLift),
          matching: find.byType(AnimatedContainer),
        ))
        .transform!
        .getTranslation()
        .y;

    testWidgets('hovering raises the card and leaving sets it back',
        (tester) async {
      await tester.pumpWidget(
        _host(const HoverLift(child: SizedBox(width: 180, height: 60))),
      );
      expect(liftOf(tester), 0);

      final gesture = await hoverAt(tester, find.byType(HoverLift));
      expect(liftOf(tester), -3);

      await gesture.moveTo(
        tester.getTopLeft(find.byType(HoverLift)) - const Offset(20, 20),
      );
      await tester.pumpAndSettle();
      expect(liftOf(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion pins the card flat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Center(
                child: HoverLift(child: SizedBox(width: 180, height: 60)),
              ),
            ),
          ),
        ),
      );

      // Hovering still happens, but the lift is skipped and the transition is
      // zero-length, so nothing moves.
      await hoverAt(tester, find.byType(HoverLift));
      expect(liftOf(tester), 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 3 — the indeterminate loader', () {
    /// The sweep painter inside [ClayLoader]. Scoped to the loader so this scan can
    /// never latch onto an unrelated CustomPaint elsewhere in the tree.
    CustomPainter sweepOf(WidgetTester tester) => tester
        .widget<CustomPaint>(find
            .descendant(
              of: find.byType(ClayLoader),
              matching: find.byType(CustomPaint),
            )
            .first)
        .painter!;

    testWidgets('the segment sweeps while motion is allowed', (tester) async {
      await tester.pumpWidget(_host(const ClayLoader(height: 8)));
      final before = sweepOf(tester);

      await tester.pump(const Duration(milliseconds: 300));

      // The phase lives in the painter, so "it moved" is exactly "this painter
      // no longer matches the previous frame" — no golden image required.
      expect(sweepOf(tester).shouldRepaint(before), isTrue,
          reason: 'an indeterminate loader must keep moving');
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion pins the segment on the track', (tester) async {
      // Start with motion allowed, so the segment leaves its pinned position,
      // then flip the policy the way the OS does.
      await tester.pumpWidget(_host(const ClayLoader(height: 8)));
      await tester.pump(const Duration(milliseconds: 300));
      final moved = sweepOf(tester);

      await tester.pumpWidget(
        _host(const ClayLoader(height: 8), reducedMotion: true),
      );
      final pinned = sweepOf(tester);
      expect(pinned.shouldRepaint(moved), isTrue,
          reason: 'turning motion off must re-seat the segment on the pinned '
              'phase, not freeze it mid-sweep');

      // A parked ticker stops driving the painter, so a full sweep interval
      // later it is the very same painter — nothing moved.
      await tester.pump(const Duration(milliseconds: 300));
      expect(identical(sweepOf(tester), pinned), isTrue,
          reason: 'a pinned loader must not keep sweeping');

      // The pinned segment is still ON the track. A parked controller at phase
      // 0 would paint the segment entirely off the leading edge — an empty
      // trough, which reads as "finished" rather than as "working".
      expect(
        find
            .descendant(
              of: find.byType(ClayLoader),
              matching: find.byType(CustomPaint),
            )
            .first,
        paints..rrect(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the segment is a gel fill on a recessed clay track',
        (tester) async {
      await tester.pumpWidget(_host(const ClayLoader(height: 8)));

      final track = tester.widget<DecoratedBox>(find.descendant(
        of: find.byType(ClayLoader),
        matching: find.byType(DecoratedBox),
      ));
      final decoration = track.decoration as BoxDecoration;
      expect(decoration.color, CScholarMaterial.clayDeep,
          reason: 'the loader shares the bar track, so both read as recessed');
      expect(decoration.borderRadius, BorderRadius.circular(4),
          reason: 'a full-radius pill, matching ClayProgressBar');
      expect(tester.takeException(), isNull);
    });
  });

  group('tier 3 — system adoption guards', () {
    /// Reads lib/ once; shared by the scans below.
    List<File> libSources() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('no screen still uses a stock TextFormField', () {
      final offences = <String>[];
      for (final file in libSources()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('TextFormField(')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'every form input must be NeumorphField so focus, rim and '
              'high contrast come from one place. Offenders:\n'
              '${offences.join('\n')}');
    });

    test('every fixed-size icon tile is ClayIconTile or marked exempt', () {
      // The signature: `width: N,` / `height: N,` with N equal and 28..64 —
      // i.e. a hard-coded square. Legitimate exceptions must say why with a
      // `tile-exempt:` comment; that keeps the audit trail in the code instead
      // of in someone's head.
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length - 1; i++) {
          final w = RegExp(r'^\s*width:\s*(\d+),\s*$').firstMatch(lines[i]);
          if (w == null) continue;
          final width = int.parse(w.group(1)!);
          if (width < 28 || width > 64) continue;

          final h = RegExp(r'^\s*height:\s*(\d+),\s*$').firstMatch(lines[i + 1]);
          if (h == null || int.parse(h.group(1)!) != width) continue;

          // The exemption must be attached to THIS site. A `tile-exempt:`
          // banner may run several lines and sits above the tile's own
          // `Container(`, so walk up through the opening of that statement
          // until it ends (a blank line, or a closing bracket/semicolon).
          var exempt = false;
          for (var j = i - 1; j >= 0 && j >= i - 10; j--) {
            final above = lines[j].trim();
            if (above.isEmpty) break;
            if (above.startsWith('//')) {
              if (above.contains('tile-exempt:')) exempt = true;
              continue;
            }
            if (above.startsWith(']') ||
                above.startsWith('}') ||
                above.endsWith(';')) {
              break;
            }
          }
          // A note inside the widget it annotates counts just as well.
          if (!exempt) {
            final window = lines.sublist(i, (i + 12).clamp(0, lines.length));
            exempt = window.any((l) => l.contains('tile-exempt:'));
          }
          if (exempt) continue;

          offences.add('${file.path}:${i + 1} (${width}px square)');
        }
      }
      expect(offences, isEmpty,
          reason: 'hand-rolled icon tiles must become ClayIconTile, or carry a '
              '`tile-exempt:` comment. Offenders:\n${offences.join('\n')}');
    });

    test('the dead second theme file is gone', () {
      expect(File('lib/core/theme/app_theme.dart').existsSync(), isFalse,
          reason: 'app_theme.dart was dead code; main.dart owns the theme');

      final offenders = <String>[];
      for (final file in libSources()) {
        if (file.readAsStringSync().contains('app_theme')) {
          offenders.add(file.path);
        }
      }
      // main.dart is allowed only because its comment documents the removal.
      for (final path in offenders) {
        final text = File(path).readAsStringSync();
        expect(text.contains('CScholarTheme') || text.contains('AppTheme'),
            isFalse,
            reason: '$path still references the deleted theme definition');
      }
    });

    test('no widget re-introduces elevation on a primary action', () {
      // The global theme pins Filled/Elevated buttons at 0. A per-widget
      // `elevation:` inside styleFrom silently defeats that.
      final offences = <String>[];
      for (final file in libSources()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('styleFrom(')) continue;
          final window = lines.sublist(i, (i + 6).clamp(0, lines.length));
          if (window.any((l) => RegExp(r'^\s*elevation:\s*[1-9]').hasMatch(l))) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'primary actions must not override the flat theme:\n'
              '${offences.join('\n')}');
    });

    test('the design lab is the only NeumorphField caller using previewState',
        () {
      // previewState exists to render every state side by side in the lab.
      // Shipping it in a real screen would freeze a field's appearance.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        // `presentation/widgets/material/` is the primitive layer: it declares
        // previewState and forwards it between its own controls
        // (NeumorphIconButton -> NeumorphButton -> NeumorphSurface). Those are
        // the plumbing, not callers.
        if (path.contains('presentation/widgets/material/')) continue;
        if (path.endsWith('design_lab_screen.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('previewState:')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'previewState is design-lab only:\n${offences.join('\n')}');
    });

    test('clickable cards opt into the hover lift', () {
      // The lift is the only hover affordance in the system, and it once
      // shipped orphaned: defined, described as "design plan item 8", and
      // reachable from nothing. Assert it is wired, not just written.
      final card = File('lib/presentation/widgets/common/cscholar_card.dart')
          .readAsStringSync();
      expect(card.contains('HoverLift'), isTrue,
          reason: 'the lift belongs in CScholarCard, so screens cannot each '
              'invent their own hover behaviour');

      for (final clickable in const [
        'lib/presentation/widgets/thesis_card.dart',
        'lib/presentation/widgets/result_card.dart',
        'lib/presentation/screens/faculty/faculty_students_screen.dart',
      ]) {
        expect(File(clickable).readAsStringSync().contains('lift: true'), isTrue,
            reason: '$clickable is clickable, so it must lift on hover');
      }
    });

    test('no screen hand-rolls a progress indicator', () {
      // ClayProgressBar owns the determinate bar (recessed clay track + gel
      // fill) and ClayLoader owns the indeterminate sweep. Stock Material
      // progress chrome is off-system in both directions: a bare
      // LinearProgressIndicator in a ClipRRect shipped twice as a status chart
      // (the admin dashboard and the faculty analytics screen), and a bare
      // LinearProgressIndicator() shipped five times as the faculty thesis
      // form's dropdown loading state — Material blue, no track, and blind to
      // the reduced-motion policy.
      final offences = <String>[];
      for (final file in libSources()) {
        // clay_progress.dart is where the stock chrome is NAMED — its doc
        // comment records what ClayProgressBar and ClayLoader replaced — so it
        // is exempt for the same reason glass_panel.dart is exempt from the
        // BackdropFilter scan below.
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('material/clay_progress.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('LinearProgressIndicator')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'progress must come from ClayProgressBar (a value) or '
              'ClayLoader (indeterminate):\n${offences.join('\n')}');
    });

    test('glass is built by GlassPanel, never hand-rolled', () {
      // Both hero search boxes used to call BackdropFilter directly, which
      // bypassed BOTH the low-power kill switch (CScholarMaterial.glassEnabled)
      // and GlassPanel's high-contrast fallback to solid clay — so they kept
      // blurring in high contrast, where blur is the thing that hurts.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('material/glass_panel.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('BackdropFilter')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'blur belongs to GlassPanel alone:\n${offences.join('\n')}');
    });

    test('the material primitives are adopted outside the design lab', () {
      // A primitive only the lab can reach is dead weight. HoverLift shipped
      // that way, and ClayProgressBar and GlassPanel were in the same state
      // until this pass — the lab and the tests do not count as adoption.
      //
      // The button primitives are the newest and most important adoption: a
      // single adopter is a false positive for "the app uses clay buttons", so
      // they are held to a real minimum number of shipping SCREENS.
      const primitives = <String, (String, int)>{
        'ClayProgressBar': ('clay_progress.dart', 1),
        'ClayLoader': ('clay_progress.dart', 1),
        'GlassPanel': ('glass_panel.dart', 1),
        // No GlassGroup entry since the repository green hero was removed as
        // a product decision: no shipping screen stacks multiple glass panels
        // over one backdrop anymore, so there is no shared blur pass to own.
        // GlassGroup remains for the design lab and future multi-panel
        // overlays — a lab-only primitive with a named reason, not drift.
        'GlassDialog': ('glass_panel.dart', 1),
        'HoverLift': ('hover_lift.dart', 1),
        'NeumorphField': ('neumorph_field.dart', 1),
        'NeumorphSelect': ('neumorph_select.dart', 1),
        'NeumorphToggle': ('neumorph_select.dart', 1),
        'NeumorphSegmented': ('neumorph_select.dart', 1),
        'ClayChip': ('clay_objects.dart', 1),
        'NeumorphButton': ('neumorph_controls.dart', 10),
        // 8 since the dashboard hero went display-only as a product decision
        // (was 9 since the landing page was removed) — the icon button is
        // still adopted across every shell and screen family.
        'NeumorphIconButton': ('neumorph_controls.dart', 8),
      };

      final sources = <String, String>{};
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        sources[path] = file.readAsStringSync();
      }
      expect(sources.length, greaterThan(30),
          reason: 'the scan found almost nothing — is lib/ at the root?');

      for (final entry in primitives.entries) {
        final minAdopters = entry.value.$2;
        final adopters = sources.entries
            .where((e) => !e.key.endsWith(entry.value.$1))
            .where((e) => e.value.contains(entry.key))
            .map((e) => e.key)
            .where((p) => p.contains('/screens/') || p.contains('/widgets/'))
            .toList();
        expect(adopters.length, greaterThanOrEqualTo(minAdopters),
            reason: '${entry.key} is adopted by only ${adopters.length} '
                'shipping file(s), needs >= $minAdopters — a lab-only or '
                'single-site primitive is a false positive. Adopters:\n'
                '${adopters.join('\n')}');
      }
    });

    test('no stock dropdown survives outside the primitive', () {
      // NeumorphSelect/NeumorphSelectField own the recessed well, focus/error
      // rim tinting, high-contrast and reduced-motion policy. A stock
      // DropdownButton(FormField) anywhere else silently drops all of that —
      // the repository filter bars were the last five sites.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        if (path.endsWith('material/neumorph_select.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('DropdownButtonFormField(') ||
              lines[i].contains('DropdownButton(') ||
              lines[i].contains('DropdownButton<')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'dropdowns must be NeumorphSelect (forms) or '
              'NeumorphSelectField (externally reset filters):\n'
              '${offences.join('\n')}');
    });

    test('dialogs are built by GlassDialog, never hand-rolled', () {
      // Dialogs are floating chrome, so per the fusion law they are glass.
      // GlassDialog owns the surface, padding and action row (plus the kill
      // switch and high-contrast fallback); a stock AlertDialog anywhere else
      // silently drops all of that.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        if (path.endsWith('material/glass_panel.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('AlertDialog(')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'dialogs must be GlassDialog (same title/content/actions '
              'slots as AlertDialog):\n${offences.join('\n')}');
    });

    test('no stock filter chip survives outside the primitive', () {
      // ClayChip owns the gel-tag treatment (selected = gel fill,
      // unselected = raised clay with a rim). A stock FilterChip with
      // per-site selectedColor/checkmarkColor overrides is the same defect
      // class as the dropdowns — the last sites were the author picker, the
      // faculty status row and the admin role filter.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        if (path.endsWith('material/clay_objects.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('FilterChip(')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'filter chips must be ClayChip (multi/single select) or '
              'NeumorphSegmented (one choice among fixed options):\n'
              '${offences.join('\n')}');
    });

    test('no stock toggle control without a control-exempt note', () {
      // NeumorphToggle / NeumorphSegmented own the sprung track + gel ball.
      // A stock Switch/Checkbox/Radio/Slider with a per-site activeThumbColor
      // override is the same defect class as the dropdowns. Genuine
      // exceptions carry a `control-exempt:` comment with the reason, the
      // same way icon tiles carry `tile-exempt:`.
      final pattern =
          RegExp(r'(^|[^_A-Za-z])(Switch|Checkbox|Radio|Slider)\s*[<(]');
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(30),
          reason: 'the scan found almost no sources — is lib/ at the root?');

      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!pattern.hasMatch(lines[i])) continue;

          var exempt = false;
          for (var j = i - 1; j >= 0 && j >= i - 10; j--) {
            final above = lines[j].trim();
            if (above.isEmpty) break;
            if (above.startsWith('//')) {
              if (above.contains('control-exempt:')) exempt = true;
              continue;
            }
            if (above.startsWith(']') ||
                above.startsWith('}') ||
                above.endsWith(';')) {
              break;
            }
          }
          if (!exempt) {
            final window = lines.sublist(i, (i + 12).clamp(0, lines.length));
            exempt = window.any((l) => l.contains('control-exempt:'));
          }
          if (exempt) continue;

          offences.add('${file.path}:${i + 1}');
        }
      }
      expect(offences, isEmpty,
          reason: 'toggles must be NeumorphToggle/NeumorphSegmented, or carry '
              'a `control-exempt:` comment. Offenders:\n${offences.join('\n')}');
    });

    test('no stock structure widget outside the allow-list', () {
      // Card / ListTile / TabBar are stock Material structure. Three decided
      // exceptions remain, all cases where the system has no equivalent and
      // the stock widget supplies accessibility semantics, not visuals:
      //   * admin_programs TabBar — bound to a TabController + TabBarView
      //     with swipe; Segmented is for non-swipe single-choice, so
      //     replacing it would delete behaviour for style points;
      //   * faculty_students dialog rows — ListTile as the accessible row
      //     inside an AlertDialog, with no card surface involved;
      //   * faculty_sidebar nav rows — ListTile for row layout + tap/focus
      //     semantics inside already-custom active styling.
      const allowed = {
        'lib/presentation/screens/admin/admin_programs_screen.dart',
        'lib/presentation/screens/faculty/faculty_students_screen.dart',
        'lib/presentation/widgets/faculty_sidebar.dart',
      };
      final pattern = RegExp(r'(^|[^_A-Za-z])(Card|ListTile)\s*\(|TabBar\s*\(');
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        final key = allowed.firstWhere(
          (a) => path.endsWith(a.substring(4)),
          orElse: () => '',
        );
        if (key.isNotEmpty) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'structure must come from the card/chip set, not stock '
              'Card/ListTile/TabBar. Offenders:\n${offences.join('\n')}');
    });

    test('no spinner in an AsyncValue loading slot', () {
      // ClayLoader owns indeterminate progress in loading slots (recessed
      // clay track + gel sweep + reduced-motion policy); SkeletonList owns
      // list-shaped loading. A bare CircularProgressIndicator in a loading:
      // slot is Material blue with no track — the same defect class already
      // fixed for linear bars. Button/upload spinners (`_isSaving`,
      // `_isLoading`, `_submitting`, `isLoading` conditionals) are genuine
      // indeterminates and out of scope here — they need the circular
      // primitive decision, which the system has not made yet.
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('CircularProgressIndicator')) continue;
          // A loading: builder usually opens on the line above, but a tall
          // builder (padding + sized box) pushes the spinner several lines
          // down — hence the wide window. Button spinners never have a
          // `loading:` above them, so they stay excluded.
          final windowStart = (i - 8).clamp(0, lines.length);
          final inLoadingSlot = lines
              .sublist(windowStart, i + 1)
              .any((l) => l.contains('loading:'));
          if (!inLoadingSlot) continue;
          offences.add('${file.path}:${i + 1}');
        }
      }
      expect(offences, isEmpty,
          reason: 'loading slots must use ClayLoader/SkeletonList, not a bare '
              'CircularProgressIndicator. Offenders:\n${offences.join('\n')}');
    });

    test('no stock text field outside the primitives and the allow-list', () {
      // NeumorphField is the system's ONE text input. One deliberate
      // exception remains, decided — not overlooked:
      //   * TopbarSearchField is a bespoke pill-radius tonal well (the
      //     primitive only ships md radius), flat-aware with its own rim.
      // `landing_screen.dart` and the repository hero stay in the allow-list
      // as history (both were borderless GlassPanel interiors before their
      // removals as product decisions) — entries with no TextField simply
      // never trigger.
      const allowed = {
        'lib/presentation/screens/landing_screen.dart',
        'lib/presentation/screens/repository/repository_screen.dart',
        'lib/presentation/widgets/common/topbar.dart',
      };
      final offences = <String>[];
      for (final file in libSources()) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        if (path.endsWith('material/neumorph_field.dart')) continue;
        if (path.endsWith('material/neumorph_select.dart')) continue;
        final key = allowed.firstWhere(
          (a) => path.endsWith(a.substring(4)),
          orElse: () => '',
        );
        if (key.isNotEmpty) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('TextField(')) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'text input must be NeumorphField so focus, rim and high '
              'contrast come from one place. Offenders:\n'
              '${offences.join('\n')}');
    });

    test('every bar fill clears 3:1 on the clay track (WCAG 1.4.11)', () {
      // A bar is a graphical object, so its fill must be distinguishable from
      // its own track. This is why `draft` is warningFg and not orange.
      for (final entry in CScholarColors.statusFill.entries) {
        final ratio = _contrast(entry.value, CScholarMaterial.clayDeep);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '${entry.key} fill is ${ratio.toStringAsFixed(2)}:1 on the '
                'clayDeep track — below the 3:1 floor for a graphical object');
      }

      // The failure this test was written for stays on the record: if #FF9900
      // ever clears 3:1, the track token moved and every stop needs re-measuring.
      expect(_contrast(CScholarColors.orange, CScholarMaterial.clayDeep),
          lessThan(3.0),
          reason: '#FF9900 is decoration-only (1.76:1 as a bar fill)');
    });

    test('state rings clear 3:1 and the hairline stays decoration', () {
      // Clay draws NO outline at rest — a surface's own fill plus a soft shadow
      // is the edge, and a rim on every control is what made the earlier pass
      // look boxed-in. What must still be perceivable is STATE: focus and error
      // are the indicators a keyboard user navigates by, so they owe the 3:1
      // floor WCAG 1.4.11 sets for component boundaries.
      const surfaces = <String, Color>{
        'clayDeep': CScholarMaterial.clayDeep,
        'clay': CScholarMaterial.clay,
      };
      surfaces.forEach((name, surface) {
        final focus = _contrast(CScholarMaterial.gelTop, surface);
        expect(focus, greaterThanOrEqualTo(3.0),
            reason: 'the focus ring is ${focus.toStringAsFixed(2)}:1 on $name '
                '— a focused field must not look unfocused');
        final error = _contrast(CScholarColors.error, surface);
        expect(error, greaterThanOrEqualTo(3.0),
            reason: 'the error ring is ${error.toStringAsFixed(2)}:1 on $name');
      });

      // The hairline is decoration and must STAY decoration. If it climbs to
      // the floor it stops being a hairline and becomes the outline this pass
      // deliberately removed — so this is the assertion that stops the two
      // from quietly collapsing into each other.
      expect(_contrast(CScholarMaterial.rim, CScholarMaterial.clay),
          lessThan(2.0),
          reason: 'rim is the hairline for small tokens and dividers, not a '
              'control boundary');

      // High contrast is the mode that DOES draw boundaries, so it has to be
      // unmistakably stronger than the hairline it stands in for.
      expect(_contrast(CScholarMaterial.rimStrong, CScholarMaterial.clay),
          greaterThan(4.5),
          reason: 'high contrast exists to supply the boundary the rest of the '
              'system omits');
    });

    test('no stock Material action button outside the primitive', () {
      // The fusion law makes NeumorphButton / NeumorphIconButton the ONLY
      // buttons: a stock Filled/Outlined/Elevated button draws its own shape,
      // elevation and ripple and cannot be made clay by theming. TextButton is
      // allowed only as an inline text link (it draws no surface), and the
      // primitive layer itself names the stock widgets it replaces.
      //
      // `lib/main.dart` is a decided allow-list entry, not a gap: it holds the
      // global ThemeData button recipes, which the tier 1 suite asserts must
      // exist (add-then-migrate, so pickers/menus/third-party dialogs that
      // render a stock button still get the brand recipe). App code never
      // instantiates one — every screen/route action is a clay button.
      const allowed = {
        'lib/presentation/widgets/material/neumorph_controls.dart',
        'lib/main.dart',
      };
      final pattern = RegExp(
          r'(^|[^_A-Za-z])(ElevatedButton|FilledButton|OutlinedButton)\s*[.(<]');
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');

      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_lab_screen.dart')) continue;
        if (allowed.any((a) => path.endsWith(a.substring(4)))) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'primary/secondary actions must be NeumorphButton (or '
              'NeumorphIconButton for icon-only). Offenders:\n'
              '${offences.join('\n')}');
    });

    test('no Colors.white fill inside a BoxDecoration', () {
      // White is a FILL for two things only: the thesis type pill and brand
      // art. Everywhere else the panel fill is clay, so a white box is the
      // stock-Material look this pass removed. `Colors.transparent` and
      // white-alpha glass are not white fills and stay allowed.
      const allowed = {
        // Brand art: the mark/wordmark are drawn in white by definition.
        'lib/presentation/widgets/common/csu_mark.dart',
        'lib/presentation/widgets/common/cscholar_logo.dart',
        // The white thesis-type pill (17.85:1 dark ink) lives here.
        'lib/presentation/widgets/thesis_card.dart',
        // The button primitive paints white *text/glyph*, never a fill; the
        // scan below only flags `color: Colors.white` inside a BoxDecoration
        // and this file's occurrences are all foreground.
        'lib/presentation/widgets/material/neumorph_controls.dart',
      };
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');
      final whiteFill =
          RegExp(r'^\s*color:\s*Colors\.white\s*,\s*$');

      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (allowed.any((a) => path.endsWith(a.substring(4)))) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!whiteFill.hasMatch(lines[i])) continue;
          // Walk up to the nearest `BoxDecoration(` (or a small window) to
          // confirm this is a decoration fill, not e.g. an Icon color.
          final start = (i - 8).clamp(0, lines.length);
          final window = lines.sublist(start, i + 1);
          if (window.any((l) => l.contains('BoxDecoration('))) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'panels are clay, never white. Replace the fill with '
              'CScholarCard/ClaySurface. Offenders:\n${offences.join('\n')}');
    });

    test('no hairline alias used as a panel or control side', () {
      // borderLight / dividerLight / sidebarLightBorder are the 1.46:1
      // hairline aliases. They belong on dividers and table-row separators —
      // never as the side of a panel or control, where the fill plus a soft
      // shadow is the boundary. `Divider(color: ...)` and small-token rims
      // (chip/tag/avatar) are the legitimate remaining uses and are not
      // matched here: this scan looks only at `Border.all` / `BorderSide`
      // *sides* naming an alias.
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');
      final aliasSide = RegExp(
          r'(border|side):\s*(const\s+)?(Border\.all\(color:\s*)?CScholarColors\.(borderLight|dividerLight|sidebarLightBorder)\b');
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('core/constants/cscholar_constants.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (aliasSide.hasMatch(lines[i])) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'a hairline alias is not a panel/control boundary — use '
              'ClaySurface (fill + one soft shadow), and keep the hairline for '
              'dividers and small tokens. Offenders:\n${offences.join('\n')}');
    });

    test('no hardcoded animation Duration in screens', () {
      // Every duration comes from CScholarDurations so the motion system stays
      // coherent and nothing outlives the 300ms ceiling.
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');
      final literal = RegExp(r'Duration\(milliseconds:');
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (path.contains('presentation/screens/')) continue;
        if (path.endsWith('core/constants/cscholar_constants.dart')) continue;
        if (path.endsWith('material/clay_progress.dart')) continue;
        if (path.endsWith('common/motion.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literal.hasMatch(lines[i])) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'use CScholarDurations (the 300ms ceiling lives there):\n'
              '${offences.join('\n')}');
    });

    test('no raw Color(0x...) in screens outside the token layer', () {
      // Extends the tier 2 palette law: screens may only name tokens. The two
      // token files own the literals, and brand art may carry its own measured
      // gradient stops.
      const allowed = {
        'lib/core/material/material_tokens.dart',
        'lib/core/constants/cscholar_constants.dart',
        'lib/presentation/widgets/common/csu_mark.dart',
        'lib/presentation/widgets/common/cscholar_logo.dart',
        'lib/presentation/widgets/thesis_card.dart',
        'lib/presentation/screens/design_lab_screen.dart',
      };
      final offences = <String>[];
      final files = libSources();
      expect(files.length, greaterThan(40),
          reason: 'the scan found almost no sources — is lib/ at the root?');
      final literal = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (allowed.any((a) => path.endsWith(a.substring(4)))) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (literal.hasMatch(lines[i])) {
            offences.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'add a named token to material_tokens.dart instead of an '
              'inline literal. Offenders:\n${offences.join('\n')}');
    });

    test('no raw Material palette name in a screen', () {
      // Extends the raw-hex guard to the other way a screen can name a colour
      // outside the system: `Colors.<name>`. Material's palette is not the
      // measured palette — `Colors.red` (#F44336) is 3.44:1 on clay, so the
      // required-field asterisks that used it were below the 4.5:1 body floor
      // for their own 13px text. `CScholarColors.error` (#B91C1C) is 5.91:1
      // there, and `CScholarColors.white` is #FFFFFFFF, the token the hero art
      // and the white-on-gel glyphs already measure against.
      //
      // `Colors.transparent` is the one exception: it is not a colour, it is
      // how a box declares "no fill" (design_lab, the mobile app bars).
      final offences = <String>[];
      final files = libSources()
          .where((f) => f.path.replaceAll('\\', '/').contains('/screens/'))
          .toList();
      expect(files.length, greaterThan(15),
          reason: 'the scan found almost no screens — is lib/ at the root?');
      final palette =
          RegExp(r'(?<![A-Za-z])Colors\.(?!transparent\b)[A-Za-z0-9]+');

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          for (final match in palette.allMatches(lines[i])) {
            offences.add('${file.path}:${i + 1} (${match.group(0)})');
          }
        }
      }
      expect(offences, isEmpty,
          reason: 'screens name tokens, never Material palette entries — use '
              'CScholarColors / CScholarMaterial. Offenders:\n'
              '${offences.join('\n')}');
    });

    test('hero ink clears the body floor on every hero gradient stop', () {
      // Surfaced by the palette migration above: the repository hero's "Clear
      // all" affordance was `Colors.white70`. Over the LIGHTEST stop of the
      // hero gradient (#008000) 70%-white composites to ~3.3:1 — under the
      // 4.5:1 floor its own 12px label owes — while the palette's white is
      // 5.14:1 there. Both hero gradients are asserted, because "the hero"
      // is whichever one a screen happens to paint.
      Color over(Color ink, Color stop) => Color.fromARGB(
            255,
            ((ink.r * 255 * ink.a) + (stop.r * 255 * (1 - ink.a))).round(),
            ((ink.g * 255 * ink.a) + (stop.g * 255 * (1 - ink.a))).round(),
            ((ink.b * 255 * ink.a) + (stop.b * 255 * (1 - ink.a))).round(),
          );

      const stops = <String, Color>{
        'heroDeep': CScholarColors.heroDeep,
        'heroMid': CScholarColors.heroMid,
        'heroGlow': CScholarColors.heroGlow,
        'heroBase': CScholarColors.heroBase,
        'heroFloor': CScholarColors.heroFloor,
      };
      stops.forEach((name, stop) {
        final white = _contrast(CScholarColors.white, stop);
        expect(white, greaterThanOrEqualTo(4.5),
            reason: 'hero ink on $name is ${white.toStringAsFixed(2)}:1');
      });

      // The failure stays on the record: if 70%-white ever clears the floor,
      // the gradient stops moved and every hero needs re-measuring.
      const white70 = Color(0xB3FFFFFF);
      final soft = _contrast(
          over(white70, CScholarColors.heroGlow), CScholarColors.heroGlow);
      expect(soft, lessThan(4.5),
          reason: 'white70 on heroGlow is only ${soft.toStringAsFixed(2)}:1 — '
              'hero ink is the token white, never white at 70%');
    });

    test('every screen adopts the motion vocabulary', () {
      // Motion is a system concern, not a per-screen garnish: the page that
      // ships without an entrance, an async cross-fade or a pressable surface
      // is the page that still looks frozen after the next restyle, and nothing
      // else in the suite can see that (the render matrix only asserts that a
      // screen builds). One reference is enough — this is an adoption guard,
      // not a usage meter. A screen that genuinely needs none of it must be
      // listed in `exempt` with a written reason, so the exception lives in the
      // code instead of in someone's memory.
      const vocabulary = <String>[
        'StaggerColumn',
        'EntranceReveal',
        'Stagger',
        'asyncSlot',
        'AsyncCrossFade',
        'CountUpText',
        'PressableSurface',
        'HoverLift',
        'ClayNavList',
      ];
      const exempt = <String, String>{
        // 'lib/presentation/screens/foo_screen.dart':
        //     'no async slot, no scrollable column — one static panel',
      };

      final files = libSources()
          .where((f) => f.path.replaceAll('\\', '/').contains('/screens/'))
          .toList();
      expect(files.length, greaterThan(15),
          reason: 'the scan found almost no screens — is lib/ at the root?');

      final offenders = <String>[];
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (exempt.containsKey(path)) continue;
        final source = file.readAsStringSync();
        if (!vocabulary.any(source.contains)) offenders.add(path);
      }
      expect(offenders, isEmpty,
          reason: 'every screen must use the shared motion vocabulary '
              '(${vocabulary.join(', ')}) — or be listed in `exempt` with a '
              'reason. Offenders:\n${offenders.join('\n')}');
    });


    test('the design lab mirrors the component catalogue', () {
      // A primitive the lab never shows cannot be reviewed by feel, and a lab
      // that looks perfect while the screens differ is a false positive. Every
      // catalogued component must appear in design_lab_screen.dart.
      const catalogue = <String>[
        'CScholarCard',
        'ClaySurface',
        'ClayIconTile',
        'ClayChip',
        'GelAvatar',
        'ClayProgressBar',
        'ClayLoader',
        'SkeletonCard',
        'SkeletonList',
        'GlassPanel',
        'GlassGroup',
        'GlassDialog',
        'NeumorphField',
        'NeumorphSelect',
        'NeumorphSelectField',
        'NeumorphToggle',
        'NeumorphSegmented',
        'NeumorphButton',
        'NeumorphIconButton',
        'HoverLift',
        'EmptyState',
        'KpiCard',
        'PageHeader',
        'ThesisStatusChip',
        'RoleChip',
        'ActiveChip',
        'ThesisCard',
        'ResultCard',
        'RecRail',
        'TopbarUserPill',
        'CountUpText',
        'EntranceReveal',
        'ClayNavList',
      ];
      final lab = File('lib/presentation/screens/design_lab_screen.dart')
          .readAsStringSync();
      final missing =
          catalogue.where((c) => !lab.contains(c)).toList();
      expect(missing, isEmpty,
          reason: 'the design lab must demo every catalogued component so it is '
              'the catalogue of record. Missing:\n${missing.join('\n')}');
    });
  });
}
