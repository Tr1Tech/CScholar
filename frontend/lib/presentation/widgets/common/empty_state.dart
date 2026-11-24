import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/presentation/widgets/common/animate_x.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Standard empty panel: icon, headline, one-line guidance, optional action.
/// Replaces every sad blank list/table in the app (design plan, item 4).
///
/// The same anatomy ships on both shells. Desktop uses the clay card and
/// neumorphic action; mobile passes [mobile] so the panel is skinned with the
/// mobile paper/clay tokens (surface, border, radius, Manrope/DM Sans, green
/// pill) while keeping the identical tile → headline → guidance → action
/// rhythm. One empty state, two materials — never two designs.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Render the mobile-shell skin. Only meaningful in the student mobile
  /// branch; desktop and admin shells leave this false.
  final bool mobile;

  /// Inline variant for an empty region that already sits inside a card (a
  /// dashboard panel, a profile side card). Same tile → headline → guidance
  /// rhythm, no second card around it, tighter vertical rhythm.
  final bool compact;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.mobile = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return mobile ? _buildMobile(context) : _buildDesktop(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final tileSize = compact ? 44.0 : 56.0;
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The tile floats ±2px on the breathe budget; the copy never
          // moves (nobody should chase reading text). Static under reduced
          // motion, high contrast and the global kill switch. A one-shot
          // shimmer sweep announces the panel once, then it rests. An
          // inline (compact) panel stays still: it is a footnote, not a page.
          if (compact)
            ClayIconTile(
              icon: icon,
              size: tileSize,
              gel: false,
              background: CScholarColors.primaryGreenLight,
              tint: CScholarColors.primaryGreen,
            )
          else
            _Float(
              child: ClayIconTile(
                icon: icon,
                size: tileSize,
                gel: false,
                background: CScholarColors.primaryGreenLight,
                tint: CScholarColors.primaryGreen,
              ).shimmerOnce(context),
            ),
          SizedBox(height: compact ? 10 : 16),
          Text(title,
              style: CScholarTextStyles.heading(
                  compact ? 14 : 17, FontWeight.w700, CScholarColors.textPrimary),
              textAlign: TextAlign.center),
          if (message != null && message!.isNotEmpty) ...[
            SizedBox(height: compact ? 4 : 6),
            Text(message!,
                style: CScholarTextStyles.body(
                    compact ? 12 : 13, FontWeight.w400, CScholarColors.textMuted),
                textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 12 : 16),
            NeumorphButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );

    if (compact) {
      return EntranceReveal(
        scaleFrom: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: content,
        ),
      );
    }

    return EntranceReveal(
      // The block settles rather than just fading: an empty panel that lands
      // reads as an answer, not a flash of missing content.
      scaleFrom: 0.96,
      child: CScholarCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: content,
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    final tileSize = compact ? 44.0 : 56.0;
    final column = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact)
            _MobileIconTile(
              icon: icon,
              size: tileSize,
              background: t.mint,
              tint: t.green,
              rim: t.line,
            )
          else
            _Float(
              child: _MobileIconTile(
                icon: icon,
                size: tileSize,
                background: t.mint,
                tint: t.green,
                rim: t.line,
              ).shimmerOnce(context),
            ),
          SizedBox(height: compact ? 10 : 16),
          Text(title,
              style: t.manrope(compact ? 14 : 17, FontWeight.w700, t.ink),
              textAlign: TextAlign.center),
          if (message != null && message!.isNotEmpty) ...[
            SizedBox(height: compact ? 4 : 6),
            Text(message!,
                style: t.dmSans(compact ? 12 : 13, FontWeight.w400, t.muted),
                textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? 12 : 16),
            _MobileAction(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );

    if (compact) {
      return EntranceReveal(
        scaleFrom: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: column,
        ),
      );
    }

    return EntranceReveal(
      scaleFrom: 0.96,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(CScholarMobileRadius.card),
          border: Border.all(color: t.line),
          boxShadow: CScholarMobileShadows.card,
        ),
        child: column,
      ),
    );
  }
}

/// Mobile twin of [ClayIconTile]: same 56px tile, soft gradient, rim and drop,
/// but built from the mobile palette so it flips with light/dark correctly.
class _MobileIconTile extends StatelessWidget {
  const _MobileIconTile({
    required this.icon,
    required this.background,
    required this.tint,
    required this.rim,
    this.size = 56,
  });

  final IconData icon;
  final Color background;
  final Color tint;
  final Color rim;
  final double size;

  @override
  Widget build(BuildContext context) {
    final flat = MediaQuery.highContrastOf(context);
    return Container(
      // tile-exempt: mobile twin of ClayIconTile — the web tile's clay
      // gradient goes near-white in dark mode, so this one must read the
      // resolved mobile palette.
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: flat ? background : null,
        gradient: flat
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(background, Colors.white, 0.22)!,
                  background,
                ],
              ),
        border: Border.all(color: rim),
        boxShadow: flat ? null : CScholarMobileShadows.pressed,
      ),
      child: Icon(icon, size: size * 0.46, color: tint),
    );
  }
}

/// Mobile action pill — the prototype CTA geometry (green fill, rounded 22)
/// paired with the same tap/haptic behavior as the desktop neumorphic button.
class _MobileAction extends StatelessWidget {
  const _MobileAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    // Use the brand green as a FILL in both modes. Resolved `t.green` is the
    // light mint accent in dark mode, which is a tint for icons — as a button
    // fill it read washed out against the dark canvas. White carries the label
    // on the solid brand green in either mode.
    return GestureDetector(
      onTap: () {
        selectionHaptic();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: CScholarMobileColors.green,
          borderRadius: BorderRadius.circular(CScholarMobileRadius.cta),
        ),
        child: Text(
          label,
          style: t.dmSans(12, FontWeight.w800, Colors.white),
        ),
      ),
    );
  }
}

/// ±2px float loop for the empty-state tile, on the breathe budget.
///
/// Private on purpose: only the empty state floats, so no new public
/// primitive enters the vocabulary. Gated by [ambientMotionEnabled] with its
/// own [RepaintBoundary] and a disposal path — an empty panel must never be
/// the reason `pumpAndSettle()` hangs. Transform only; the loop is symmetric
/// ([CScholarCurves.anticipate]) so it never hitches at the turnaround.
class _Float extends StatefulWidget {
  const _Float({required this.child});

  final Widget child;

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CScholarMotion.breathe,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (ambientMotionEnabled(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    // Inert, not fast: no controller runs, no ticker, no extra layer.
    if (!ambientMotionEnabled(context)) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // Same transient-curve read PulseDot uses: the value is sampled per
          // frame, nothing is created that needs disposing.
          final t = CurvedAnimation(
            parent: _c,
            curve: CScholarCurves.anticipate,
            reverseCurve: CScholarCurves.anticipate,
          ).value;
          return Transform.translate(
            offset: Offset(0, -2 + 4 * t),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
