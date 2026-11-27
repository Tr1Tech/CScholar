import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// Tells a nested `DeferredSkeleton` that its own reveal timer is redundant.
///
/// [DelayedSkeletonLoader] owns the whole reveal lifecycle when it wraps a
/// skeleton: delay, reveal and minimum display. A skeleton inside that subtree
/// must not start a second 250ms timer, or the placeholder would wait twice as
/// long before it becomes visible.
class SkeletonDelayScope extends InheritedWidget {
  const SkeletonDelayScope({
    super.key,
    required this.managed,
    required super.child,
  });

  /// Whether an ancestor loader owns the reveal timing for this subtree.
  final bool managed;

  static bool managedOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SkeletonDelayScope>()
          ?.managed ??
      false;

  @override
  bool updateShouldNotify(SkeletonDelayScope oldWidget) =>
      oldWidget.managed != managed;
}

enum _LoaderPhase { waiting, skeleton, content }

/// A skeleton slot that never flashes: delay, reveal, then hold for a minimum.
///
/// Three rules, in order:
///
/// 1. **Delay** — nothing is shown for [delay]. A response that lands inside
///    that window skips the skeleton entirely and paints the real [child].
/// 2. **Minimum display** — once the skeleton has appeared it stays for at
///    least [minimumDisplay]. A load that finishes just after the delay cannot
///    paint a one-frame placeholder.
/// 3. **Fade** — every state change cross-fades over [fadeDuration], so the
///    swap reads as content settling in rather than a hard repaint.
///
/// Timers are cancelled on every state change, in [didUpdateWidget] and in
/// [dispose], so a load that finishes early (or a screen that pops while it is
/// still waiting) leaves nothing behind.
///
/// While waiting, the skeleton is still laid out at zero opacity. That reserves
/// the card rhythm from the first frame, so a fast response lands exactly where
/// the skeleton would have been and the page does not jump.
///
/// Typical use — the widget is a drop-in for any boolean loading slot:
///
/// ```dart
/// DelayedSkeletonLoader(
///   isLoading: _isLoading,
///   skeleton: const SkeletonList(count: 3),
///   child: ResultsList(items: _items),
/// )
/// ```
///
/// [delay] and [minimumDisplay] default to the app-wide skeleton budget
/// ([CScholarMotion.skeletonDelay] and
/// [CScholarMotion.skeletonMinimumDisplay]); override them only for a slot with
/// a genuinely different rhythm.
class DelayedSkeletonLoader extends StatefulWidget {
  const DelayedSkeletonLoader({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.delay = CScholarMotion.skeletonDelay,
    this.minimumDisplay = CScholarMotion.skeletonMinimumDisplay,
    this.fadeDuration = CScholarDurations.normal,
  });

  /// The loading state. Flip it to false when the data (or error) is ready.
  final bool isLoading;

  /// The placeholder to show while [isLoading] has run longer than [delay].
  final Widget skeleton;

  /// The real content, shown once loading is done and the skeleton has met its
  /// minimum display time.
  final Widget child;

  /// How long loading may run before the skeleton is revealed.
  final Duration delay;

  /// How long the skeleton stays visible once it has been revealed.
  final Duration minimumDisplay;

  /// The cross-fade duration. Reduced motion snaps instead of tweening.
  final Duration fadeDuration;

  @override
  State<DelayedSkeletonLoader> createState() => _DelayedSkeletonLoaderState();
}

class _DelayedSkeletonLoaderState extends State<DelayedSkeletonLoader> {
  _LoaderPhase _phase = _LoaderPhase.content;

  Timer? _delayTimer;
  Timer? _minimumTimer;

  /// Whether [DelayedSkeletonLoader.minimumDisplay] has elapsed since reveal.
  /// Tracked with a Timer rather than a Stopwatch so widget tests can advance
  /// the clock with `pump`, exactly like the rest of the app's timers.
  bool _minimumElapsed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      if (widget.delay <= Duration.zero) {
        // No delay: the skeleton is the first thing the slot shows.
        _phase = _LoaderPhase.skeleton;
        _beginMinimumDisplay();
      } else {
        _phase = _LoaderPhase.waiting;
        _delayTimer = Timer(widget.delay, _revealSkeleton);
      }
    }
  }

  @override
  void didUpdateWidget(DelayedSkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    if (widget.isLoading) {
      _startLoading();
    } else {
      _finishLoading();
    }
  }

  /// A load started. If the skeleton is already up (an overlapping refresh),
  /// leave it alone and keep its minimum-display clock running.
  void _startLoading() {
    if (_phase == _LoaderPhase.skeleton) return;

    _delayTimer?.cancel();
    _delayTimer = null;
    _minimumTimer?.cancel();
    _minimumTimer = null;
    _minimumElapsed = false;

    if (widget.delay <= Duration.zero) {
      _beginMinimumDisplay();
      _setPhase(_LoaderPhase.skeleton);
    } else {
      _setPhase(_LoaderPhase.waiting);
      _delayTimer = Timer(widget.delay, _revealSkeleton);
    }
  }

  /// Loading finished. Before the delay, skip the skeleton entirely. Once it
  /// has appeared, wait out the rest of [DelayedSkeletonLoader.minimumDisplay].
  void _finishLoading() {
    _delayTimer?.cancel();
    _delayTimer = null;

    if (_phase == _LoaderPhase.waiting) {
      // The skeleton was never revealed, so there is nothing to hold.
      _minimumTimer?.cancel();
      _minimumTimer = null;
      _setPhase(_LoaderPhase.content);
      return;
    }
    if (_phase == _LoaderPhase.skeleton && _minimumElapsed) {
      _setPhase(_LoaderPhase.content);
    }
    // Otherwise the minimum timer's callback finishes the swap.
  }

  void _revealSkeleton() {
    _delayTimer = null;
    if (!mounted) return;
    if (!widget.isLoading) {
      // Loading ended in the same tick the timer fired; skip the placeholder.
      _setPhase(_LoaderPhase.content);
      return;
    }
    _beginMinimumDisplay();
    _setPhase(_LoaderPhase.skeleton);
  }

  void _beginMinimumDisplay() {
    _minimumTimer?.cancel();
    _minimumTimer = null;
    _minimumElapsed = widget.minimumDisplay <= Duration.zero;
    if (_minimumElapsed) return;
    _minimumTimer = Timer(widget.minimumDisplay, _onMinimumElapsed);
  }

  void _onMinimumElapsed() {
    _minimumTimer = null;
    _minimumElapsed = true;
    if (!mounted) return;
    // If loading already finished during the hold, the skeleton has now served
    // its minimum time and may hand over to the real content.
    if (!widget.isLoading && _phase == _LoaderPhase.skeleton) {
      _setPhase(_LoaderPhase.content);
    }
  }

  void _setPhase(_LoaderPhase next) {
    if (!mounted || _phase == next) return;
    setState(() => _phase = next);
  }

  @override
  void dispose() {
    // A screen that pops mid-load must not wake a disposed State.
    _delayTimer?.cancel();
    _minimumTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : widget.fadeDuration;
    final waiting = _phase == _LoaderPhase.waiting;

    // The loader owns the timing, so nested skeletons skip their own delay.
    // While waiting the skeleton is laid out but invisible: the box is
    // reserved without painting a placeholder.
    Widget skeleton = SkeletonDelayScope(
      managed: true,
      child: TickerMode(enabled: !waiting, child: widget.skeleton),
    );
    if (waiting) {
      skeleton = ExcludeSemantics(child: Opacity(opacity: 0, child: skeleton));
    }

    final body = switch (_phase) {
      _LoaderPhase.waiting || _LoaderPhase.skeleton => skeleton,
      _LoaderPhase.content => widget.child,
    };

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: CScholarCurves.standard,
      switchOutCurve: CScholarCurves.exit,
      // Fade only: the states occupy the same slot, so no rise or slide is
      // added here. Top-align so a taller skeleton cannot recentre the page.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey<_LoaderPhase>(_phase), child: body),
    );
  }
}
