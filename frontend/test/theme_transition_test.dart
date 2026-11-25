// The shipping light/dark switch, end to end.
//
// Guards the whole chain: the button in the top-right corner reports its icon
// centre, the root freezes the outgoing frame, flips the palette, and opens an
// iris wipe from that point — even though the route was never rebuilt by the
// Navigator. Also pins that the overlay is gone afterwards (it absorbs
// pointers, so a parked one would make the app dead to taps).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/widgets/common/theme_iris.dart';
import 'package:frontend/presentation/widgets/common/theme_toggle.dart';

/// A tiny opaque frame, handed to the transition in place of the engine raster
/// (which never completes under the test clock).
ui.Image _stubFrame() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 4, 4),
    Paint()..color = CScholarMobileColors.paper,
  );
  return recorder.endRecording().toImageSync(4, 4);
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const ProviderScope(child: CScholarApp()));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CScholarPalette.activate(false);
    CScholarModeStore.initialDark = false;
    CScholarApp.debugFrameCapture = () async => _stubFrame();
  });

  tearDown(() {
    CScholarPalette.activate(false);
    CScholarModeStore.initialDark = false;
    CScholarApp.debugFrameCapture = null;
  });

  testWidgets('the switch wipes the new theme in from the icon', (
    tester,
  ) async {
    await _pumpApp(tester);

    // The auth shell owns the whole viewport, so the switch floats top-right.
    expect(find.byType(ThemeModeButton), findsOneWidget);
    expect(CScholarColors.textPrimary, CScholarMobileColors.ink);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The wipe is up: a frozen frame of the OLD theme with a circular hole in
    // it, and the live app already repainted in the new palette beneath.
    expect(find.byKey(themeCurtainKey), findsOneWidget);
    expect(
      find.byType(ThemeIris),
      findsOneWidget,
      reason: 'a captured frame is what makes the reveal an iris, not a fade',
    );
    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);

    // The hole is centred on the switch, not on the screen.
    final iris = tester.widget<ThemeIris>(find.byType(ThemeIris));
    final button = tester.getCenter(find.byType(ThemeModeButton));
    expect(iris.center.dx, moreOrLessEquals(button.dx, epsilon: 1));
    expect(iris.center.dy, moreOrLessEquals(button.dy, epsilon: 1));

    // Let the circle finish and unmount. The pump derives from the token, so a
    // slower wipe never leaves this test reading a live overlay.
    await tester.pump(
      CScholarMotion.themeSwap + const Duration(milliseconds: 120),
    );
    await tester.pump();
    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
    expect(find.byType(ThemeIris), findsNothing);
    // The ROUTE repainted: the auth shell's scaffold now carries the dark
    // canvas. This is the assertion the palette scope exists for — a root-only
    // rebuild would have left this light.
    final shells = tester.widgetList<Scaffold>(find.byType(Scaffold));
    expect(
      shells.first.backgroundColor,
      CScholarMobileColors.paperDark,
      reason: 'the login route must be painted in the dark palette',
    );

    // Nothing is still absorbing taps.
    expect(find.byKey(themeCurtainKey), findsNothing);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pump();
    await tester.pump(
      CScholarMotion.themeSwap + const Duration(milliseconds: 120),
    );
    await tester.pump();
    expect(CScholarColors.textPrimary, CScholarMobileColors.ink);
    expect(find.byKey(themeCurtainKey), findsNothing);
  });

  testWidgets('reduced motion swaps instantly with no overlay', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _pumpApp(tester);
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pump();

    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
    expect(find.byKey(themeCurtainKey), findsNothing);
    expect(find.byType(ThemeIris), findsNothing);
  });

  testWidgets('the saved mode is adopted before the first frame', (
    tester,
  ) async {
    CScholarModeStore.initialDark = true;
    await _pumpApp(tester);
    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
  });

  group('iris geometry', () {
    const size = Size(400, 800);
    const centre = Offset(380, 40);

    Path clipAt(double progress) =>
        CScholarIrisClipper(center: centre, progress: progress).getClip(size);

    test('nothing is revealed at 0 and everything at 1', () {
      expect(
        clipAt(0).contains(const Offset(200, 400)),
        isTrue,
        reason: 'the frozen frame still covers the whole screen',
      );
      expect(
        clipAt(1).contains(const Offset(200, 400)),
        isFalse,
        reason: 'the circle has passed every corner',
      );
      expect(clipAt(1).getBounds().isEmpty, isTrue);
    });

    test('the hole opens from the toggle and grows outward', () {
      // Just after the start the switch itself is already inside the circle,
      // while the opposite corner is still covered.
      final early = clipAt(0.02);
      expect(early.contains(centre), isFalse);
      expect(early.contains(const Offset(20, 780)), isTrue);

      // Halfway, the near corner has been swept but the far one has not.
      final mid = clipAt(0.5);
      expect(mid.contains(centre), isFalse);
      expect(mid.contains(Offset.zero), isFalse);
      expect(mid.contains(const Offset(10, 790)), isTrue);
    });

    test('the reach is the farthest corner, so coverage always completes', () {
      expect(
        CScholarIrisClipper.reachFor(size, centre),
        moreOrLessEquals(_far(centre)),
      );
      // At exactly 1 there is nothing left anywhere.
      for (final corner in const [
        Offset.zero,
        Offset(400, 0),
        Offset(0, 800),
        Offset(400, 800),
      ]) {
        expect(clipAt(1).contains(corner), isFalse);
      }
    });
  });
}

double _far(Offset centre) {
  final corners = <Offset>[
    Offset.zero,
    const Offset(400, 0),
    const Offset(0, 800),
    const Offset(400, 800),
  ];
  var best = 0.0;
  for (final corner in corners) {
    final d = (corner - centre).distance;
    if (d > best) best = d;
  }
  return best;
}
