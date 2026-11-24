import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_header.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_nav.dart';

/// Mobile-only student scaffold — the prototype shell
/// (`cscholar-mobile-ui/src/App.tsx:353-517`, `index.css:344-517`).
///
/// Desktop/web > [AppConfig.mobileMaxWidth] never reaches this widget:
/// [StudentLayout] keeps the 248px sidebar there. No role switching lives
/// here — mobile is student-only by plan.
class MobileStudentScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  /// Depth screens (detail) hide the bottom nav and swap the header brand
  /// for a back action + focused title.
  final bool isDepth;
  final String depthTitle;

  /// List route the depth back action returns to when there is no page to pop.
  final String? depthBackRoute;

  const MobileStudentScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.isDepth = false,
    this.depthTitle = 'Thesis details',
    this.depthBackRoute,
  });

  /// True when the prototype shell should own the screen.
  static bool useMobileShell(BuildContext context, {double? widthOverride}) {
    final width =
        widthOverride ?? MediaQuery.sizeOf(context).width;
    return width <= AppConfig.mobileMaxWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Painted mode, via the scope: the toggle sets the provider at tap time but
    // the shell repaints when the root flips the palette under the curtain.
    final t = CScholarMobileTheme.of(context);

    // The mode scope is provided by [StudentLayout], above this scaffold:
    // screens resolve `CScholarMobileTheme.of` with the layout's context,
    // so scoping here would only cover header/nav, never the screen body.
    // This still watches the provider (via `isDark` above), so the toggle
    // rebuilds the whole subtree, and the scope above re-resolves with it.
    return Scaffold(
      backgroundColor: t.paper,
      body: SafeArea(
        // Prototype structure: `.bottom-nav` is `position: absolute;
        // inset: auto 10px 10px` OVER `.screen-content` (`index.css:395-404`),
        // not a Scaffold bottom bar. A Stack reproduces that exactly — the
        // body never reserves nav height, and content scrolls beneath it.
        child: Stack(
          children: [
            Column(
              children: [
                MobileStudentHeader(
                  isDepth: isDepth,
                  depthTitle: depthTitle,
                  backRoute: depthBackRoute,
                ),
                Expanded(
                  child: EntranceReveal(
                    rise: 9,
                    child: child,
                  ),
                ),
              ],
            ),
            if (!isDepth)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: MobileStudentNav(currentIndex: currentIndex),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prototype toast (`cscholar-mobile-ui/src/App.tsx:568-573`, `index.css:242`):
/// dark pill, 1.8s, fed by [message]. Callers show it via ScaffoldMessenger.
class MobileToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 17, color: Colors.white),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  message,
                  style: CScholarMobileTextStyles.dmSans(
                      10, FontWeight.w700, Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: CScholarMobileColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }
}

/// Prototype filter bottom sheet shell (`index.css:232-241 sheet-in .3s`).
/// Content is a Phase 2 concern — this is the handle + heading chrome only.
class MobileFilterSheet extends StatelessWidget {
  final Widget child;

  const MobileFilterSheet({super.key, required this.child});

  static Future<T?> show<T>(BuildContext context, Widget child) {
    final t = CScholarMobileTheme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      // Content-bearing sheet: without this the route caps it at 9/16 of the
      // screen and the last filters + apply button fall off the bottom.
      isScrollControlled: true,
      backgroundColor: t.surface,
      barrierColor: const Color(0x59231D18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CScholarMobileRadius.sheet),
        ),
      ),
      builder: (context) => MobileFilterSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 23),
        child: EntranceReveal(
          rise: 35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CScholarMobileTheme.of(context).line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
