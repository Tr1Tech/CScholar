import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile theme mode — mirrors the prototype's `cscholar-theme`
/// localStorage toggle (`cscholar-mobile-ui/src/App.tsx:266-283`).
final mobileThemeModeProvider = NotifierProvider<MobileThemeMode, bool>(
  () => MobileThemeMode(),
);

class MobileThemeMode extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('cscholar-mobile-theme-dark') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cscholar-mobile-theme-dark', state);
  }
}
