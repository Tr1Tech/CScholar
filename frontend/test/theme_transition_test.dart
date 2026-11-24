// The shipping light/dark switch, end to end.
//
// Guards the whole chain: the button in the top-right corner flips the mode
// provider, the root holds the flip behind the curtain, and the paint comes up
// on the dark palette — even though the route was never rebuilt by the
// Navigator. Also pins that the curtain is gone afterwards (it absorbs
// pointers, so a parked curtain would make the app dead to taps).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/mobile_theme_provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/widgets/common/theme_toggle.dart';

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
  });

  tearDown(() {
    CScholarPalette.activate(false);
    CScholarModeStore.initialDark = false;
  });

  testWidgets('the switch starts light, flips dark, and flips back', (
    tester,
  ) async {
    await _pumpApp(tester);

    // The auth shell owns the whole viewport, so the switch floats top-right.
    expect(find.byType(ThemeModeButton), findsOneWidget);
    expect(CScholarColors.textPrimary, CScholarMobileColors.ink);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pump();
    // Mid-transition the painter is already covering; the palette is not yet
    // swapped, which is what hides the flip.
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      CScholarColors.textPrimary,
      CScholarMobileColors.inkDark,
      reason: 'the palette swaps under full cover',
    );

    // Let the curtain finish and unmount.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
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
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(CScholarColors.textPrimary, CScholarMobileColors.ink);
    expect(find.byKey(themeCurtainKey), findsNothing);
  });

  testWidgets('reduced motion swaps instantly with no curtain', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _pumpApp(tester);
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pump();

    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
    expect(find.byKey(themeCurtainKey), findsNothing);
  });

  testWidgets('the saved mode is adopted before the first frame', (
    tester,
  ) async {
    CScholarModeStore.initialDark = true;
    await _pumpApp(tester);
    expect(CScholarColors.textPrimary, CScholarMobileColors.inkDark);
  });
}
