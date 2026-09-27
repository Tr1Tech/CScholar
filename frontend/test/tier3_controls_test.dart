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
import 'package:frontend/presentation/widgets/material/inset_shadow.dart';
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
    testWidgets('rest state is a recessed clay well with a rim',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphField(label: 'Email', hintText: 'you@csu.edu.ph')),
      );

      final well = _wellDecoration(tester);
      expect(well.color, CScholarMaterial.clayDeep);
      expect((well.border as Border).top.color, CScholarMaterial.rim);

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

    testWidgets('high contrast drops the inset and strengthens the rim',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphField(label: 'Email'), highContrast: true),
      );

      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarMaterial.rimStrong);

      // The inset is painted by InsetShadow, which collapses to a bare child
      // when its shadow list is empty — so nothing overlays the well. Assert on
      // the shadow list itself: TextField paints its own CustomPaint, so a
      // `findsNothing` on CustomPaint could never hold.
      final inset = tester.widget<InsetShadow>(
        find.descendant(
          of: find.byType(NeumorphField),
          matching: find.byType(InsetShadow),
        ),
      );
      expect(inset.shadows, isEmpty);
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
    /// The sweep painter inside [ClayLoader]. Scoped to the loader because
    /// InsetShadow paints its own CustomPaint; the segment's painter is the
    /// first one down the tree (Stack draws its child before the overlay).
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
      const primitives = <String, String>{
        'ClayProgressBar': 'clay_progress.dart',
        'ClayLoader': 'clay_progress.dart',
        'GlassPanel': 'glass_panel.dart',
        'GlassGroup': 'glass_panel.dart',
        'HoverLift': 'hover_lift.dart',
        'NeumorphField': 'neumorph_field.dart',
        'NeumorphSelect': 'neumorph_select.dart',
        'NeumorphToggle': 'neumorph_select.dart',
        'NeumorphSegmented': 'neumorph_select.dart',
        'ClayChip': 'clay_objects.dart',
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
        final adopters = sources.entries
            .where((e) => !e.key.endsWith(entry.value))
            .where((e) => e.value.contains(entry.key))
            .map((e) => e.key)
            .toList();
        expect(adopters, isNotEmpty,
            reason: '${entry.key} is reachable only from the design lab — '
                'adopt it in a real screen or delete it');
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
      // Card / ListTile / TabBar are stock Material structure. Each remaining
      // site is Task C.3 backlog: either the card/chip set replaces it, or it
      // earns a justified exemption. New sites must not add to the list.
      const allowed = {
        'lib/presentation/screens/admin/admin_programs_screen.dart',
        'lib/presentation/screens/admin/admin_user_management_screen.dart',
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

    test('no spinner in an AsyncValue loading slot outside the allow-list', () {
      // ClayLoader owns indeterminate progress in loading slots (recessed
      // clay track + gel sweep + reduced-motion policy); SkeletonList owns
      // list-shaped loading. A bare CircularProgressIndicator in a loading:
      // slot is Material blue with no track — the same defect class already
      // fixed for linear bars. The remaining sites are Task C.4 backlog.
      // Button/upload spinners (`_isSaving`, `_isLoading`, `_submitting`,
      // `isLoading` conditionals) are genuine indeterminates and out of
      // scope here — they need the Task C.4 circular-primitive decision.
      const allowed = {
        'lib/presentation/screens/landing_screen.dart',
        'lib/presentation/screens/auth/register_screen.dart',
        'lib/presentation/screens/faculty/faculty_dashboard_screen.dart',
        'lib/presentation/screens/thesis/thesis_detail_screen.dart',
        'lib/presentation/screens/admin/admin_user_management_screen.dart',
        'lib/presentation/screens/student/student_dashboard_screen.dart',
        'lib/presentation/screens/admin/admin_programs_screen.dart',
        'lib/presentation/widgets/rec_rail.dart',
      };
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
          final key = allowed.firstWhere(
            (a) => path.endsWith(a.substring(4)),
            orElse: () => '',
          );
          if (key.isNotEmpty) continue;
          offences.add('${file.path}:${i + 1}');
        }
      }
      expect(offences, isEmpty,
          reason: 'loading slots must use ClayLoader/SkeletonList, not a bare '
              'CircularProgressIndicator. Offenders:\n${offences.join('\n')}');
    });

    test('no stock text field outside the primitives and the allow-list', () {
      // NeumorphField is the system's ONE text input. Two deliberate
      // exceptions remain, both decided — not overlooked:
      //   * the landing + repository hero searches are borderless interiors
      //     of a GlassPanel; a clay well nested inside glass would put two
      //     styles on one element;
      //   * TopbarSearchField is a bespoke pill-radius recessed well (the
      //     primitive only ships md radius), flat-aware with its own inset.
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
  });
}
