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
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// The Opacity `EntranceReveal` wraps its child in — present only while motion
/// is on.
double _revealOpacity(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(find.descendant(
    of: find.byType(EntranceReveal),
    matching: find.byType(Opacity),
  ));
  return opacity.opacity;
}

void main() {
  testWidgets('entrance reveal starts hidden, fades in, then settles',
      (tester) async {
    await tester.pumpWidget(_host(const EntranceReveal(child: Text('clay'))));

    // First frame: the child is in the tree but not yet legible, so the reveal
    // is doing something. A helper that snapped to 1.0 here would pass a
    // "renders" assertion while animating nothing.
    expect(_revealOpacity(tester), lessThan(1.0));

    await tester.pump(const Duration(milliseconds: 300));
    expect(_revealOpacity(tester), 1.0);
    expect(find.text('clay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance reveal is inert under reduced motion', (tester) async {
    await tester.pumpWidget(
      _host(const EntranceReveal(child: Text('clay')), reduceMotion: true),
    );

    // No Opacity wrapper means no controller, no compositing layer and no
    // timer — the child is handed straight through.
    expect(
      find.descendant(
        of: find.byType(EntranceReveal),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(find.text('clay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stagger caps its delay so a long list never crawls in',
      (tester) async {
    await tester.pumpWidget(
      _host(const Stagger(index: 50, child: Text('row'))),
    );

    final reveal = tester.widget<EntranceReveal>(find.byType(EntranceReveal));
    expect(reveal.delay, const Duration(milliseconds: 240),
        reason: 'the stagger delay must clamp at max (240ms)');
  });

  testWidgets('async cross-fade swaps the skeleton for content',
      (tester) async {
    await tester.pumpWidget(_host(const AsyncCrossFade(
      isLoading: true,
      skeleton: Text('skeleton'),
      child: Text('content'),
    )));
    expect(find.text('skeleton'), findsOneWidget);

    final switcher =
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, CScholarDurations.normal);

    await tester.pumpWidget(_host(const AsyncCrossFade(
      isLoading: false,
      skeleton: Text('skeleton'),
      child: Text('content'),
    )));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('async cross-fade switches instantly under reduced motion',
      (tester) async {
    await tester.pumpWidget(_host(
      const AsyncCrossFade(
        isLoading: true,
        skeleton: Text('skeleton'),
        child: Text('content'),
      ),
      reduceMotion: true,
    ));

    final switcher =
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('count-up animates to the value, and snaps under reduced motion',
      (tester) async {
    await tester.pumpWidget(
      _host(CountUpText(value: 128, style: const TextStyle())),
    );
    expect(find.text('128'), findsNothing,
        reason: 'the number must count up, not appear complete');

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('128'), findsOneWidget);

    await tester.pumpWidget(_host(
      CountUpText(value: 128, style: const TextStyle()),
      reduceMotion: true,
    ));
    expect(find.text('128'), findsOneWidget);
  });

  testWidgets('pressable surface sinks on press', (tester) async {
    await tester.pumpWidget(_host(
      PressableSurface(onTap: () {}, child: const Text('tile')),
    ));

    final gesture = await tester.startGesture(tester.getCenter(find.text('tile')));
    await tester.pump(const Duration(milliseconds: 50));

    final pressed =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(pressed.duration, CScholarDurations.fast);
    expect(pressed.transform, isNot(Matrix4.identity()),
        reason: 'press must move the surface, not just repaint it');

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('press feedback is inert under reduced motion', (tester) async {
    await tester.pumpWidget(_host(
      PressableSurface(onTap: () {}, child: const Text('tile')),
      reduceMotion: true,
    ));

    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(box.duration, Duration.zero);

    final gesture = await tester.startGesture(tester.getCenter(find.text('tile')));
    await tester.pump(const Duration(milliseconds: 50));
    final held =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(held.transform, Matrix4.identity(),
        reason: 'reduced motion must not sink the surface');
    await gesture.up();
  });

  test('no motion helper outruns the 300ms cap', () {
    expect(CScholarDurations.slow, const Duration(milliseconds: 300));
    const reveal = EntranceReveal(child: SizedBox.shrink());
    expect(reveal.duration, lessThanOrEqualTo(CScholarDurations.slow));
  });

  testWidgets('the shell and the page header carry the entrance reveal',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(CScholarShell(
      sidebar: const SizedBox.shrink(),
      mobileTitle: 'CScholar',
      child: const PageHeader(title: 'Dashboard'),
    )));

    // One reveal for the shell content, one for the header: every shelled page
    // opens with the same fade + rise even if a screen forgets to add one.
    expect(find.byType(EntranceReveal), findsNWidgets(2));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
