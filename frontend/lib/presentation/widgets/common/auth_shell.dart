import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/csu_mark.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';

/// Shared shell for the two auth screens (login / register) — ONE visual unit.
///
/// MATERIAL FUSION (see material_tokens.dart): the card is floating chrome, so
/// per the fusion law it is GLASS (overlay recipe, same as dialogs); everything
/// inside it — fields, buttons, the checkbox — stays clay. Ambient orbs are
/// decoration: soft tinted washes that drift slowly behind the card so the
/// glass has something real to refract.
///
/// Both screens pass their form as [child]; the brand header and the campus
/// affiliation footer live here so they can never drift apart.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.maxCardWidth = 480,
  });

  final Widget child;

  /// Login is a single-column form (460); register carries two-column field
  /// rows and needs a wider slab (560).
  final double maxCardWidth;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    final mark = CSUMark(size: 56);

    return Scaffold(
      backgroundColor: CScholarMaterial.canvas,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          const _AmbientField(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EntranceReveal(
                    rise: 16,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      child: GlassPanel(
                        radius: CScholarRadius.xxl,
                        fill: CScholarMaterial.glassOverlay,
                        blur: CScholarMaterial.blurOverlay,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Brand identity, centered: the ONE prestige
                            // element on the screen carries the soft gold
                            // halo (decoration — dropped under high contrast).
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(56 * 0.24),
                                  boxShadow: highContrast
                                      ? null
                                      : CScholarMaterial.goldGlow(
                                          strength: 0.55),
                                ),
                                child: mark,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'CScholar',
                              textAlign: TextAlign.center,
                              style: CScholarTextStyles.poppins(
                                24,
                                FontWeight.w800,
                                CScholarColors.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CEIT THESIS REPOSITORY',
                              textAlign: TextAlign.center,
                              style: CScholarTextStyles.inter(
                                10.5,
                                FontWeight.w700,
                                CScholarColors.textMuted,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 24),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gold on canvas is decoration (1.26:1); the copy
                      // carries the meaning.
                      const Icon(Icons.school,
                          size: 14, color: CScholarColors.gold),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Caraga State University · CEIT Campus Portal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CScholarTextStyles.inter(
                            11.5,
                            FontWeight.w500,
                            CScholarColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three tinted washes, placed asymmetrically so the canvas never reads as a
/// flat void. Existing palette tints only (mint / sky / gold paper) — no new
/// colour enters the system for decoration.
class _AmbientField extends StatelessWidget {
  const _AmbientField();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(-0.85, -0.8),
          child: _AmbientOrb(
            size: 380,
            color: CScholarColors.primaryGreenLight,
            drift: const Offset(18, 12),
            duration: const Duration(seconds: 11),
          ),
        ),
        Align(
          alignment: const Alignment(0.9, -0.45),
          child: _AmbientOrb(
            size: 240,
            color: CScholarColors.skyTint,
            drift: const Offset(-14, 16),
            duration: const Duration(seconds: 9),
          ),
        ),
        Align(
          alignment: const Alignment(0.75, 0.9),
          child: _AmbientOrb(
            size: 320,
            color: CScholarColors.goldSoft,
            drift: const Offset(-16, -12),
            duration: const Duration(seconds: 13),
          ),
        ),
      ],
    );
  }
}

/// Soft radial wash that breathes — a slow, small, transform-only drift.
/// The controller is inert (static orb, no ticker) under reduced motion, and
/// the drift amplitude is small enough that the motion reads as ambience, not
/// animation.
class _AmbientOrb extends StatefulWidget {
  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.drift,
    required this.duration,
  });

  final double size;
  final Color color;
  final Offset drift;
  final Duration duration;

  @override
  State<_AmbientOrb> createState() => _AmbientOrbState();
}

class _AmbientOrbState extends State<_AmbientOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // motionEnabled() reads MediaQuery, which is only available here — and
    // this also re-targets if the OS reduced-motion setting changes.
    if (motionEnabled(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
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
    final orb = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.color.withValues(alpha: 0.95),
            widget.color.withValues(alpha: 0),
          ],
        ),
      ),
    );

    if (!motionEnabled(context)) return orb;
    return AnimatedBuilder(
      animation: _curve,
      child: orb,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          widget.drift.dx * _curve.value,
          widget.drift.dy * _curve.value,
        ),
        child: child,
      ),
    );
  }
}

/// Auth error slot: keeps the layout height while the error appears and clears
/// (size + fade + 6px rise), so the form never jumps when sign-in is rejected.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = (error ?? '').isNotEmpty;
    final duration = motionDuration(context, CScholarDurations.normal);

    return AnimatedSize(
      duration: duration,
      curve: CScholarCurves.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: CScholarCurves.entrance,
        switchOutCurve: CScholarCurves.entrance,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: hasError
            ? Container(
                key: ValueKey<String>(error!),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CScholarColors.errorLight,
                  borderRadius: BorderRadius.circular(CScholarRadius.md),
                  border: Border.all(
                      color: CScholarColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: CScholarColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: CScholarTextStyles.inter(
                            12, FontWeight.w500, CScholarColors.error),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}
