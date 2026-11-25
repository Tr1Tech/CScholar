import 'package:flutter/widgets.dart' show Brightness, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One light/dark mode for the WHOLE app — web and mobile.
///
/// The switch lives in the top-right corner of every shell (desktop topbar,
/// mobile header, auth screens). It used to drive the mobile shell only; the
/// web now resolves the same flag through `CScholarPalette`, so both builds
/// flip together and the choice is shared per device.
///
/// The persisted value is read once in `main()` before `runApp`, so the first
/// frame is already painted in the saved mode: no flash of light before dark,
/// and no unrequested transition on start-up.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(
  ThemeModeNotifier.new,
);

/// Historically the mobile-only toggle. Same provider — the mode is app-wide
/// now, and every existing (mobile) call site keeps working unchanged.
final mobileThemeModeProvider = themeModeProvider;

/// Where the app starts before the notifier exists (set by `main()`).
class CScholarModeStore {
  CScholarModeStore._();

  /// The persisted mode, already merged with the legacy mobile key.
  static bool initialDark = false;

  static const String prefsKey = 'cscholar-theme-dark';

  /// The key the mobile-only toggle used. Read as a fallback so nobody loses
  /// the choice they already made.
  static const String legacyPrefsKey = 'cscholar-mobile-theme-dark';

  /// Resolves the saved mode. Call from `main()` before `runApp`.
  ///
  /// With no saved choice the app follows the OS: a phone or browser in dark
  /// mode opens dark (DS-3). The first tap of the switch records an explicit
  /// override, which then wins on every later launch.
  static Future<bool> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(prefsKey) ?? prefs.getBool(legacyPrefsKey);
      initialDark =
          saved ??
          (WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);
    } catch (_) {
      // No prefs on this platform (or a test host): follow the OS too.
      initialDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return initialDark;
  }
}

class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => CScholarModeStore.initialDark;

  /// Flips the mode and persists it. The visual swap is animated by the root
  /// shell (see `CScholarApp`), which repaints the palette mid-transition.
  Future<void> toggle() => setDark(!state);

  Future<void> setDark(bool value) async {
    if (state == value) return;
    state = value;
    await _persist(value);
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CScholarModeStore.prefsKey, value);
    } catch (_) {
      // Best-effort: the mode still applies for this session.
    }
  }
}
