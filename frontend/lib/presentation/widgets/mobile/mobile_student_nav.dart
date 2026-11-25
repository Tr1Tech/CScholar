import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Prototype bottom nav (`cscholar-mobile-ui/src/App.tsx:501-514`, styled
/// `index.css:395-421`): floating pill, 4 student tabs, hidden on depth
/// screens where a back action + focused title takes over.
class MobileStudentNav extends StatefulWidget {
  final int currentIndex;

  const MobileStudentNav({super.key, required this.currentIndex});

  /// The tab this nav last landed on, kept outside the widget tree.
  ///
  /// Every mobile screen builds its own scaffold, so a route change disposes
  /// this nav and mounts a fresh one. Without the memory the fill would be born
  /// under the new tab — a pop, not a slide.
  static final Map<String, int> _landed = <String, int>{};

  @override
  State<MobileStudentNav> createState() => _MobileStudentNavState();
}

class _MobileStudentNavState extends State<MobileStudentNav> {
  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home', '/student/dashboard'),
    (Icons.search_outlined, Icons.search, 'Search', '/repository'),
    (Icons.bookmark_outline, Icons.bookmark, 'Saved', '/saved'),
    (Icons.person_outline, Icons.person, 'Profile', '/profile'),
  ];

  /// Tab the fill is currently drawn under: the remembered one first, then the
  /// live selection after the next frame.
  late int _pillIndex =
      MobileStudentNav._landed['mobile-student'] ?? widget.currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pillIndex != widget.currentIndex) {
        setState(() => _pillIndex = widget.currentIndex);
      }
      MobileStudentNav._landed['mobile-student'] = widget.currentIndex;
    });
  }

  @override
  void didUpdateWidget(covariant MobileStudentNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pillIndex = widget.currentIndex;
      MobileStudentNav._landed['mobile-student'] = widget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    // Prototype radius is asymmetric — 24 top, 31 bottom.
    final radius = BorderRadius.vertical(
      top: const Radius.circular(CScholarMobileRadius.nav),
      bottom: const Radius.circular(CScholarMobileRadius.navBar),
    );
    final rim = t.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.75);

    // Prototype box: `height: 78px; padding: 7px 7px 13px`. The bar grows with
    // the OS text scale instead of clipping the label at 200% (A11Y-10); the
    // extra height keeps the same bottom safe-area padding.
    final labelHeight = MediaQuery.textScalerOf(context).scale(10) * 1.2;
    final barHeight = 78 + (labelHeight - 12).clamp(0.0, 26.0);
    return SizedBox(
      height: barHeight,
      child: DecoratedBox(
        // Shadow lives outside the clip so the rounded pill still casts it.
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14293C32),
              blurRadius: 26,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 13),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.96),
            borderRadius: radius,
            border: Border.all(color: rim),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Tabs are equal-width, so the fill can be positioned by index
              // without measuring anything.
              final cell = constraints.maxWidth / _tabs.length;
              final index = _pillIndex.clamp(0, _tabs.length - 1);
              return Stack(
                children: [
                  // One fill that travels, instead of four that blink on and
                  // off: the tab you left stays linked to the one you landed on.
                  AnimatedPositioned(
                    duration: motionDuration(context, CScholarDurations.fast),
                    curve: CScholarCurves.standard,
                    left: index * cell,
                    top: 0,
                    bottom: 0,
                    width: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.mint,
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: widget.currentIndex == i
                                ? _tabs[i].$2
                                : _tabs[i].$1,
                            label: _tabs[i].$3,
                            active: widget.currentIndex == i,
                            onTap: () {
                              selectionHaptic();
                              context.go(_tabs[i].$4);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    // Prototype inactive tab colour is #8a938e in light.
    final fg = active
        ? t.green
        : (t.isDark ? t.muted : const Color(0xFF8A938E));
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // The fill is painted behind the whole row by the nav, so the tab only
        // carries its own glyph and label.
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Static glyph: the travelling fill is the only motion here. The
              // old lift-and-scale made every tab jump as it became current.
              Icon(icon, size: 21, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.dmSans(10, FontWeight.w600, fg, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
