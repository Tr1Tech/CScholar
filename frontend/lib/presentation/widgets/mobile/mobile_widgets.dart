import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// Prototype thesis card (`cscholar-mobile-ui/src/App.tsx:206-243`, styled
/// `index.css:97-107`): program eyebrow + save toggle, title, author/year,
/// tag row. Data comes from the backend [Thesis] — same shape, new skin.
class MobileThesisCard extends StatelessWidget {
  final Thesis thesis;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  /// Semantic match for this card, 0-100. Null on keyword results, which have
  /// no score to show.
  final int? matchPercent;

  const MobileThesisCard({
    super.key,
    required this.thesis,
    required this.saved,
    required this.onOpen,
    required this.onSave,
    this.matchPercent,
  });

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(CScholarMobileRadius.card),
          border: Border.all(color: t.line),
          boxShadow: CScholarMobileShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (thesis.program?.name ?? '').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.dmSans(
                      9,
                      FontWeight.w800,
                      t.green2,
                      height: 1.2,
                      letterSpacing: 0.72,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (matchPercent != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: t.mint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: t.green),
                        const SizedBox(width: 3),
                        Text(
                          '$matchPercent%',
                          style: t.dmSans(8, FontWeight.w800, t.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () {
                    selectionHaptic();
                    onSave();
                  },
                  child: Container(
                    // tile-exempt: compact save toggle.
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: saved ? t.mint : t.surfaceSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: saved ? t.green : t.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.only(right: 28),
              child: Text(
                thesis.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: t.cardTitle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${thesis.authorsString} · ${thesis.academicYear?.label ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.dmSans(10, FontWeight.w400, t.muted),
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final tag
                    in (thesis.keywords ?? []).take(2).map((k) => k.term))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: t.dmSans(8, FontWeight.w600, t.muted),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Prototype research orbit decoration
/// (`cscholar-mobile-ui/src/App.tsx:245-263`, styled `index.css:450-544`).
///
/// The three prototype loops are copied 1:1:
///   * core  — `orbit-float`  4.2s ease-in-out:  0 -> -7px, -8deg -> -4deg
///   * paper — `paper-float` 4.2s after 450ms:   0 -> +5px, 11deg -> 7deg
///   * nodes — `node-pulse`  3s ease-in-out:     scale 1 -> 1.22,
///     staggered 0 / 800ms / 1500ms.
///
/// CSS's 4.2s / 3s is a FULL 0% -> 50% -> 100% cycle, but a
/// `repeat(reverse: true)` controller spends one duration on the way out and
/// another coming back, so each controller runs for HALF the CSS cycle.
/// Passing the full cycle here (as the first port did) made the orbit run at
/// half the prototype's speed.
///
/// The base rotations also apply in the static frame (the prototype rotates
/// the core and paper even when animations are killed). Every loop runs only
/// while [ambientMotionEnabled]; reduced motion, high contrast and the test
/// kill switch render that static frame with no ticker.
class MobileResearchOrbit extends StatelessWidget {
  const MobileResearchOrbit({super.key});

  static const double _deg = math.pi / 180;
  // 4.2s CSS cycle -> 2.1s per leg; 3s CSS cycle -> 1.5s per leg.
  static const Duration _coreDuration = Duration(milliseconds: 2100);
  static const Duration _paperDuration = Duration(milliseconds: 2100);
  static const Duration _paperDelay = Duration(milliseconds: 450);
  static const Duration _nodeDuration = Duration(milliseconds: 1500);
  static const List<Duration> _nodeDelays = [
    Duration.zero,
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
  ];

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        children: [
          Positioned(
            left: 9,
            top: 50,
            child: _OrbitLoop(
              duration: _nodeDuration,
              delay: _nodeDelays[0],
              builder: _pulseNode,
              child: _node(CScholarMobileColors.coral),
            ),
          ),
          Positioned(
            top: 5,
            right: 28,
            child: _OrbitLoop(
              duration: _nodeDuration,
              delay: _nodeDelays[1],
              builder: _pulseNode,
              child: _node(CScholarMobileColors.lilac),
            ),
          ),
          Positioned(
            left: 38,
            bottom: 4,
            child: _OrbitLoop(
              duration: _nodeDuration,
              delay: _nodeDelays[2],
              builder: _pulseNode,
              child: _node(const Color(0xFFEFB75F)),
            ),
          ),
          Positioned(
            left: 35,
            top: 33,
            child: _OrbitLoop(
              duration: _coreDuration,
              delay: Duration.zero,
              builder: _floatCore,
              child: Container(
                // tile-exempt: orbit core illustration.
                width: 61,
                height: 61,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF34765E), CScholarMobileColors.green],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D174F3D),
                      blurRadius: 25,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 7,
            child: _OrbitLoop(
              duration: _paperDuration,
              delay: _paperDelay,
              builder: _floatPaper,
              child: Container(
                width: 40,
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: CScholarMobileShadows.card,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: CScholarMobileColors.coral,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(height: 3, color: t.muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 4),
                    Container(height: 3, color: t.muted.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _floatCore(BuildContext context, double t, Widget child) {
    return Transform.translate(
      offset: Offset(0, -7 * t),
      child: Transform.rotate(angle: (-8 + 4 * t) * _deg, child: child),
    );
  }

  static Widget _floatPaper(BuildContext context, double t, Widget child) {
    return Transform.translate(
      offset: Offset(0, 5 * t),
      child: Transform.rotate(angle: (11 - 4 * t) * _deg, child: child),
    );
  }

  static Widget _pulseNode(BuildContext context, double t, Widget child) {
    return Transform.scale(scale: 1 + 0.22 * t, child: child);
  }

  Widget _node(Color color) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E263C31),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

/// One prototype ambient loop (`ease-in-out`, infinite, optional start delay).
///
/// Returns the exact static frame when [ambientMotionEnabled] is false, and
/// carries its own [RepaintBoundary] while running so the loop never repaints
/// the welcome copy around the orbit.
class _OrbitLoop extends StatefulWidget {
  const _OrbitLoop({
    required this.duration,
    required this.delay,
    required this.builder,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext context, double t, Widget child) builder;
  final Widget child;

  @override
  State<_OrbitLoop> createState() => _OrbitLoopState();
}

class _OrbitLoopState extends State<_OrbitLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  Timer? _delayTimer;
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (!ambientMotionEnabled(context)) {
      _delayTimer?.cancel();
      _delayTimer = null;
      _running = false;
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0;
      return;
    }
    if (_running) return;
    _running = true;
    if (widget.delay == Duration.zero) {
      _controller.repeat(reverse: true);
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      _delayTimer = null;
      if (!mounted || !ambientMotionEnabled(context)) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    if (!ambientMotionEnabled(context)) {
      return widget.builder(context, 0, widget.child);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) =>
            widget.builder(context, _curve.value, child!),
        child: widget.child,
      ),
    );
  }
}
