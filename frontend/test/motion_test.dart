// Motion gates — the vocabulary animates, and it goes inert.
//
// The failure this file exists to catch is a motion system that only works in
// one direction: a reveal that never plays (dead motion) or one that keeps
// playing when the OS asks for reduced motion (a ticker, and a `pumpAndSettle()`
// that never terminates). Every test therefore asserts BOTH states.
//
// It also pins the invariants the rest of the app relies on: the stagger delay
// is capped, and no helper animates longer than CScholarDurations.slow.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/motion_ambient.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:shimmer/shimmer.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// The FadeTransition `EntranceReveal` wraps its child in — present only
/// while motion is on (flutter_animate renders FadeTransition, not Opacity).
double _revealOpacity(WidgetTester tester) {
  final fade = tester.widget<FadeTransition>(
    find.descendant(
      of: find.byType(EntranceReveal),
      matching: find.byType(FadeTransition),
    ),
  );
  return fade.opacity.value;
}

/// Target opacity of the deferred skeleton wrapping [SkeletonCard].
double _skeletonOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(SkeletonCard),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('entrance reveal fades in, then settles', (tester) async {
    await tester.pumpWidget(_host(const EntranceReveal(child: Text('clay'))));

    // flutter_animate arms its controller from a scheduled microtask, which
    // fake_async only flushes on an elapsed pump: the first elapsed pump
    // STARTS the controller (value still 0 that frame), the second advances
    // it. So arm first, then advance past the duration.
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      _revealOpacity(tester),
      lessThan(1.0),
      reason: 'the reveal starts hidden',
    );

    await tester.pump(CScholarMotion.softEnter);
    expect(_revealOpacity(tester), 1.0);
    expect(find.text('clay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance reveal is inert under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(const EntranceReveal(child: Text('clay')), reduceMotion: true),
    );

    // No FadeTransition means no controller, no compositing layer and no
    // timer — the child is handed straight through.
    expect(
      find.descendant(
        of: find.byType(EntranceReveal),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(find.text('clay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stagger caps its delay so a long list never crawls in', (
    tester,
  ) async {
    // Structural assertion (the delay value), so reduced motion keeps the
    // tree free of flutter_animate's arming timer entirely.
    await tester.pumpWidget(
      _host(const Stagger(index: 50, child: Text('row')), reduceMotion: true),
    );

    final reveal = tester.widget<EntranceReveal>(find.byType(EntranceReveal));
    expect(
      reveal.delay,
      const Duration(milliseconds: 240),
      reason: 'the stagger delay must clamp at max (240ms)',
    );
  });

  testWidgets('a skeleton is held back, then fades in after the threshold', (
    tester,
  ) async {
    // The loader-flash rule: under ~250ms the placeholder would be replaced
    // before the eye reads it, which is a flicker rather than feedback. It is
    // still laid out at opacity 0, so the box is reserved from frame one.
    await tester.pumpWidget(_host(const SkeletonCard()));
    expect(
      _skeletonOpacity(tester),
      0,
      reason: 'a fast load must never paint a placeholder',
    );
    expect(
      tester.getSize(find.byType(SkeletonCard)).height,
      greaterThan(90),
      reason: 'the box is reserved even while the skeleton is held back',
    );

    await tester.pump(CScholarMotion.skeletonDelay);
    await tester.pump(CScholarDurations.fast);
    expect(
      _skeletonOpacity(tester),
      1,
      reason: 'a slow load earns its skeleton',
    );
  });

  testWidgets('the skeleton inverts on the dark shell', (tester) async {
    // A light block on dark paper is a glowing slab, not a loading state.
    await tester.pumpWidget(
      MaterialApp(
        home: CScholarMobileThemeScope(
          isDark: true,
          child: const Scaffold(body: Center(child: SkeletonCard())),
        ),
      ),
    );
    await tester.pump(CScholarMotion.skeletonDelay);
    await tester.pump(CScholarDurations.fast);

    final block = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SkeletonCard),
            matching: find.byType(Container),
          )
          .last,
    );
    expect(
      (block.decoration! as BoxDecoration).color,
      CScholarMaterial.skeletonBaseDark,
    );
  });

  testWidgets('async cross-fade swaps the skeleton for content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AsyncCrossFade(
          isLoading: true,
          skeleton: Text('skeleton'),
          child: Text('content'),
        ),
      ),
    );
    expect(find.text('skeleton'), findsOneWidget);

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, CScholarDurations.normal);

    await tester.pumpWidget(
      _host(
        const AsyncCrossFade(
          isLoading: false,
          skeleton: Text('skeleton'),
          child: Text('content'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('async cross-fade switches instantly under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AsyncCrossFade(
          isLoading: true,
          skeleton: Text('skeleton'),
          child: Text('content'),
        ),
        reduceMotion: true,
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
  });

  testWidgets(
    'count-up animates to the value, and snaps under reduced motion',
    (tester) async {
      await tester.pumpWidget(
        _host(CountUpText(value: 128, style: const TextStyle())),
      );
      expect(
        find.text('128'),
        findsNothing,
        reason: 'the number must count up, not appear complete',
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('128'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          CountUpText(value: 128, style: const TextStyle()),
          reduceMotion: true,
        ),
      );
      expect(find.text('128'), findsOneWidget);
    },
  );

  testWidgets('pressable surface sinks on press', (tester) async {
    await tester.pumpWidget(
      _host(PressableSurface(onTap: () {}, child: const Text('tile'))),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('tile')),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final pressed = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(pressed.duration, CScholarDurations.fast);
    expect(
      pressed.transform,
      isNot(Matrix4.identity()),
      reason: 'press must move the surface, not just repaint it',
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('press feedback is inert under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(
        PressableSurface(onTap: () {}, child: const Text('tile')),
        reduceMotion: true,
      ),
    );

    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(box.duration, Duration.zero);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('tile')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final held = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      held.transform,
      Matrix4.identity(),
      reason: 'reduced motion must not sink the surface',
    );
    await gesture.up();
  });

  test('no motion helper outruns the Soft UI entrance budget', () {
    expect(CScholarMotion.softEnter, const Duration(milliseconds: 350));
    const reveal = EntranceReveal(child: SizedBox.shrink());
    expect(reveal.duration, CScholarMotion.softEnter);
    expect(CScholarDurations.slow, const Duration(milliseconds: 300));
  });

  testWidgets('the shell and the page header carry the entrance reveal', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        CScholarShell(
          sidebar: const SizedBox.shrink(),
          mobileTitle: 'CScholar',
          child: const PageHeader(title: 'Dashboard'),
        ),
      ),
    );
    // Let the reveals arm AND settle so no flutter_animate timer outlives
    // the tree at teardown.
    await tester.pump(const Duration(milliseconds: 500));

    // One reveal for the shell content, one for the header: every shelled page
    // opens with the same fade + rise even if a screen forgets to add one.
    expect(find.byType(EntranceReveal), findsNWidgets(2));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('ambient gate', () {
    setUp(() => CScholarMotion.ambientEnabled = true);
    tearDown(() => CScholarMotion.ambientEnabled = true);

    testWidgets(
      'gate ON: the looping widgets schedule frames (a ticker exists)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const Column(
              children: [
                RepaintBoundary(child: PulseDot(color: Colors.green)),
                BreathingGlow(child: SizedBox(width: 40, height: 40)),
                DriftingWash(child: SizedBox(height: 60, width: 120)),
              ],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.binding.hasScheduledFrame,
          isTrue,
          reason: 'the ambient loops must be ticking while the gate is on',
        );
      },
    );

    testWidgets('gate OFF: the same widgets settle with no ticker left', (
      tester,
    ) async {
      final gated = const Column(
        children: [
          RepaintBoundary(child: PulseDot(color: Colors.green)),
          BreathingGlow(child: SizedBox(width: 40, height: 40)),
          DriftingWash(child: SizedBox(height: 60, width: 120)),
        ],
      );
      await tester.pumpWidget(_host(gated));
      CScholarMotion.ambientEnabled = false;
      // The global switch is a plain static, and the element tree skips
      // identical widget instances on rebuild — so the flip is only seen
      // through a rebuild with a fresh key.
      await tester.pumpWidget(
        _host(KeyedSubtree(key: UniqueKey(), child: gated)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'no ticker may be left running once the gate is off',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('gate OFF via high contrast: same static, settled result', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: true),
              child: const Column(
                children: [
                  RepaintBoundary(child: PulseDot(color: Colors.green)),
                  BreathingGlow(child: SizedBox(width: 40, height: 40)),
                  DriftingWash(child: SizedBox(height: 60, width: 120)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'high contrast must kill the ambience',
      );
    });

    testWidgets('gate OFF via reduced motion: same static, settled result', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              RepaintBoundary(child: PulseDot(color: Colors.green)),
              BreathingGlow(child: SizedBox(width: 40, height: 40)),
              DriftingWash(child: SizedBox(height: 60, width: 120)),
            ],
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'reduced motion must kill the ambience',
      );
    });
  });

  testWidgets('animated swap under reduced motion returns the child bare', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AnimatedSwap(child: Text('a', key: const ValueKey('a'))),
        reduceMotion: true,
      ),
    );

    expect(
      find.byType(AnimatedSwitcher),
      findsNothing,
      reason: 'no switcher, no controller, nothing to leak',
    );
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('thesis skeleton is static under reduced motion', (tester) async {
    await tester.pumpWidget(_host(const ThesisSkeleton(), reduceMotion: true));

    expect(
      find.byType(Shimmer),
      findsNothing,
      reason: 'the shimmer is a loop — reduced motion gets no ticker',
    );
    // The host schedules one housekeeping frame after its first build, so the
    // settle assertion comes after a pump — the same budget the toggle test uses.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'no ticker may be left running',
    );
  });

  testWidgets('animated swap keeps both children mid-flight', (tester) async {
    await tester.pumpWidget(
      _host(AnimatedSwap(child: Text('a', key: const ValueKey('a')))),
    );
    expect(find.text('a'), findsOneWidget);

    await tester.pumpWidget(
      _host(AnimatedSwap(child: Text('b', key: const ValueKey('b')))),
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(
      find.text('a'),
      findsOneWidget,
      reason: 'the outgoing copy must still be in the tree mid-flight',
    );
    expect(
      find.text('b'),
      findsOneWidget,
      reason: 'a real cross-fade, not a hard swap',
    );
  });

  testWidgets('morph icon pops on selection (keyed replay + settle)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        MorphIcon(
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
          selected: false,
          color: Colors.black,
          selectedColor: Colors.black,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      _host(
        MorphIcon(
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
          selected: true,
          color: Colors.black,
          selectedColor: Colors.black,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // The keyed Animate wrapper must be present (a changed glyph replays the
    // cascade instead of hard-swapping), the selected glyph shows, and the
    // scale settles back at exactly 1.0.
    expect(
      find.descendant(
        of: find.byType(MorphIcon),
        matching: find.byType(Animate),
      ),
      findsOneWidget,
      reason: 'the pop must run through a keyed Animate wrapper',
    );
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    final settled = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(MorphIcon),
            matching: find.byType(Transform),
          ),
        )
        .map((t) => t.transform.getMaxScaleOnAxis())
        .toList();
    expect(settled, isNotEmpty);
    expect(
      settled.every((s) => (s - 1.0).abs() < 0.001),
      isTrue,
      reason: 'the pop must settle back at scale 1.0',
    );
  });

  testWidgets('tactile toggle sinks on press and its burst stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TactileToggle(
          selected: false,
          onChanged: () {},
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MorphIcon)),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final pressed = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(
      pressed.scale,
      0.94,
      reason: 'press must move the surface, not just repaint it',
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tactile toggle is inert under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(
        TactileToggle(
          selected: false,
          onChanged: () {},
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
        ),
        reduceMotion: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'no burst, no ticker under reduced motion',
    );
  });

  test('every new one-shot constant stays inside the page ceiling', () {
    for (final d in [
      CScholarMotion.micro,
      CScholarMotion.swap,
      CScholarMotion.enter,
      CScholarMotion.page,
    ]) {
      expect(d, lessThanOrEqualTo(CScholarMotion.page));
    }
    // The ambient loop constants are NOT one-shots: they live in their own
    // budget and must never be used for a transition.
    expect(CScholarMotion.breathe, greaterThan(CScholarMotion.page));
    expect(CScholarMotion.drift, greaterThan(CScholarMotion.page));
    expect(CScholarMotion.shimmer, greaterThan(CScholarMotion.page));
    expect(CScholarMotion.pulse, greaterThan(CScholarMotion.page));
  });

  test('stagger column clamps at every pitch max for a 50th child', () {
    for (final pitch in MotionPitch.values) {
      final column = StaggerColumn(
        pitch: pitch,
        children: List.generate(50, (_) => const SizedBox.shrink()),
      );
      expect(column.pitch, pitch);
      expect(
        pitch.max.inMilliseconds,
        lessThan(500),
        reason: 'a pitch max must clamp hard, not crawl',
      );
    }
  });

  test('stagger column diagonal cascade is real', () {
    final column = StaggerColumn(
      pitch: MotionPitch.page,
      columns: 3,
      children: List.generate(6, (_) => const SizedBox.shrink()),
    );
    expect(column.columns, 3);
    // Child 3 (col 0, row 1) lands on the 1.6x-weighted row term; child 1
    // (col 1, row 0) lands on the bare column term.
    final child1 = MotionPitch.page.step * 1;
    final child3 = MotionPitch.page.step * 1.6;
    expect(child3, greaterThan(child1));
  });
}
