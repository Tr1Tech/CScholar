import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Standard empty panel: icon, headline, one-line guidance, optional action.
/// Replaces every sad blank list/table in the app (design plan, item 4).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EntranceReveal(
      // The block settles rather than just fading: an empty panel that lands
      // reads as an answer, not a flash of missing content.
      scaleFrom: 0.96,
      child: CScholarCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The tile floats ±2px on the breathe budget; the copy never
              // moves (nobody should chase reading text). Static under reduced
              // motion, high contrast and the global kill switch.
              _Float(
                child: ClayIconTile(
                  icon: icon,
                  size: 56,
                  gel: false,
                  background: CScholarColors.primaryGreenLight,
                  tint: CScholarColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: CScholarTextStyles.poppins(
                      16, FontWeight.w700, CScholarColors.textPrimary),
                  textAlign: TextAlign.center),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(message!,
                    style: CScholarTextStyles.inter(
                        13, FontWeight.w400, CScholarColors.textMuted),
                    textAlign: TextAlign.center),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                NeumorphButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
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
