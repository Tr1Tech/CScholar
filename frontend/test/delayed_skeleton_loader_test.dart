// The no-flash contract: delay, hold, fade, clean up.
//
// A skeleton is feedback only if the eye can read it. These tests pin the three
// boundaries that keep it honest: a fast load skips the placeholder, a load
// that reveals one holds it for the minimum, and a disposed slot leaves no
// timer behind.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/delayed_skeleton_loader.dart';

Widget _host(
  ValueNotifier<bool> loading, {
  Duration delay = CScholarMotion.skeletonDelay,
  Duration minimumDisplay = CScholarMotion.skeletonMinimumDisplay,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: loading,
            builder: (context, isLoading, _) => DelayedSkeletonLoader(
              isLoading: isLoading,
              skeleton: const Text('skeleton'),
              delay: delay,
              minimumDisplay: minimumDisplay,
              fadeDuration: const Duration(milliseconds: 200),
              child: const Text('content'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The most visible copy of the skeleton, multiplied through the animated
/// wrappers the loader and [AnimatedSwitcher] put around it.
///
/// During a cross-fade there can be two copies (the outgoing one is hidden),
/// so reading a single [Opacity] would pick the wrong one.
double _skeletonOpacity(WidgetTester tester) {
  final texts = find.text('skeleton').evaluate();
  var best = 0.0;
  for (final element in texts) {
    var opacity = 1.0;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Opacity) opacity *= widget.opacity;
      if (widget is FadeTransition) opacity *= widget.opacity.value;
      return true;
    });
    if (opacity > best) best = opacity;
  }
  return best;
}

void main() {
  testWidgets('a load faster than the delay never paints the skeleton', (
    tester,
  ) async {
    final loading = ValueNotifier<bool>(true);
    await tester.pumpWidget(_host(loading));

    // The box exists so the layout is reserved, but nothing is visible.
    expect(find.text('skeleton'), findsOneWidget);
    expect(_skeletonOpacity(tester), 0);

    loading.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('content'), findsOneWidget);
    expect(find.text('skeleton'), findsNothing);
  });

  testWidgets('a revealed skeleton stays for the minimum display time', (
    tester,
  ) async {
    final loading = ValueNotifier<bool>(true);
    await tester.pumpWidget(_host(loading));

    await tester.pump(CScholarMotion.skeletonDelay);
    // Let the 200ms reveal fade finish so the skeleton is at full strength.
    await tester.pump(const Duration(milliseconds: 200));
    expect(_skeletonOpacity(tester), 1.0);

    // Data lands 250ms after the reveal — inside the 400ms minimum.
    await tester.pump(const Duration(milliseconds: 50));
    loading.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('content'),
      findsNothing,
      reason: 'the skeleton still owes the eye its minimum display time',
    );

    // Cross the minimum boundary (250ms used + 150ms more = 400ms).
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('content'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('skeleton'), findsNothing);
  });

  testWidgets('configurable delay and minimum are honoured', (tester) async {
    final loading = ValueNotifier<bool>(true);
    await tester.pumpWidget(
      _host(
        loading,
        delay: const Duration(milliseconds: 100),
        minimumDisplay: const Duration(milliseconds: 200),
      ),
    );

    await tester.pump(const Duration(milliseconds: 90));
    expect(_skeletonOpacity(tester), 0, reason: 'still inside the delay');

    await tester.pump(const Duration(milliseconds: 20));
    // The reveal cross-fade starts on the frame the timer fires; one more
    // pump advances it so the skeleton is no longer at zero.
    await tester.pump(const Duration(milliseconds: 20));
    expect(_skeletonOpacity(tester), greaterThan(0));

    loading.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('content'), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('dispose cancels both timers', (tester) async {
    final loading = ValueNotifier<bool>(true);
    await tester.pumpWidget(_host(loading));

    // Dispose while the reveal timer is still pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion snaps the state change', (tester) async {
    final loading = ValueNotifier<bool>(true);
    await tester.pumpWidget(_host(loading, reduceMotion: true));

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);

    loading.value = false;
    await tester.pump();
    expect(find.text('content'), findsOneWidget);
  });
}
