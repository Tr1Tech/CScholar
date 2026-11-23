import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

/// One row of a [ClayNavList].
class ClayNavLink {
  const ClayNavLink({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;
}

/// Sidebar navigation whose active pill SLIDES between rows.
///
/// The three role sidebars (admin, faculty, student) each hand-rolled the same
/// item — an [AnimatedContainer] whose fill cross-faded in place. That reads as
/// a highlight blinking on and off; the row the user came from is never linked
/// to the row they arrived at. This is that item once, with the motion the rest
/// of the system uses:
///
///   * the active pill is one [AnimatedPositioned] gel pill painted behind the
///     rows, so a route change moves it — it snaps under reduced motion,
///     because [motionDuration] is [Duration.zero];
///   * every row is a [PressableSurface], so a press sinks the row (the ripple
///     is deliberately gone: clay's press is a sink, not a splash);
///   * the row is focusable, Enter/Space activate it and focus draws the same
///     ring the button primitive draws — a web app driven by Tab + Enter must
///     not lose its keyboard path to a restyle.
///
/// Rows are a fixed height (which grows with the text scale). That is what lets
/// the pill be positioned without measuring: every row is exactly one
/// ellipsised line.
class ClayNavList extends StatefulWidget {
  const ClayNavList({
    super.key,
    required this.links,
    required this.selectedIndex,
    required this.rail,
  });

  final List<ClayNavLink> links;

  /// Index of the active row, or -1 when the current route matches no row
  /// (for example the admin thesis editor under `/admin/thesis/...`): the pill
  /// then fades out rather than highlighting the wrong item.
  final int selectedIndex;

  /// Identifies this rail, so the roles do not share a remembered row.
  final String rail;

  /// The row each rail last landed on, kept outside the widget tree.
  ///
  /// Every screen owns its own shell, so a route change disposes this widget
  /// and the next page mounts a fresh one. Without this the pill would be born
  /// already sitting on the new row — a pop, not a slide. It is a plain static
  /// map rather than a provider so the list still renders standalone (the
  /// design lab shows it without the app's provider scope).
  static final Map<String, int> _landed = <String, int>{};

  /// Row height at 100% text: the 20px glyph plus 11px breathing room above and
  /// below, which is what the three sidebars were sized around.
  static const double rowHeight = 42;

  /// Gap between rows.
  static const double gap = 4;

  /// Corner radius, shared with the pill.
  static const double radius = CScholarRadius.navPill;

  @override
  State<ClayNavList> createState() => _ClayNavListState();
}

class _ClayNavListState extends State<ClayNavList> {
  late List<FocusNode> _nodes = _buildNodes(widget.links.length);
  int _focused = -1;

  /// True when the focused row got focus from a click/tap. Rows keep the ring
  /// for keyboard navigation only; a pointer click should not leave an outline
  /// behind on the row it just selected.
  bool _focusFromPointer = false;

  /// Row the pill is currently drawn on. It starts on the row the same rail
  /// had on the previous page, then glides to this page's selection.
  late int _pillIndex = _initialPillIndex();

  int _initialPillIndex() {
    final landed = ClayNavList._landed[widget.rail];
    // No remembered row on first load: start already landed, no fly-in.
    return landed ?? widget.selectedIndex;
  }

  @override
  void initState() {
    super.initState();
    // After the first paint, glide from the remembered row to this one. The
    // write has to leave the build phase before it can be read again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectedIndex >= 0 && _pillIndex != widget.selectedIndex) {
        setState(() => _pillIndex = widget.selectedIndex);
      }
      _remember();
    });
  }

  void _remember() {
    if (widget.selectedIndex >= 0) {
      ClayNavList._landed[widget.rail] = widget.selectedIndex;
    }
  }

  List<FocusNode> _buildNodes(int count) =>
      List<FocusNode>.generate(count, (index) {
        final node = FocusNode(debugLabel: 'nav-${widget.links[index].label}');
        node.addListener(_onFocusChange);
        return node;
      });

  void _onFocusChange() {
    if (!mounted) return;
    final index = _nodes.indexWhere((node) => node.hasFocus);
    if (index == -1) _focusFromPointer = false;
    if (index != _focused) setState(() => _focused = index);
  }

  @override
  void didUpdateWidget(covariant ClayNavList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.links.length != _nodes.length) {
      _disposeNodes(_nodes);
      _nodes = _buildNodes(widget.links.length);
      _focused = -1;
    }
    // Same widget, new page (a rail that survives the route): the pill glides
    // from wherever it is now.
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      if (widget.selectedIndex >= 0) _pillIndex = widget.selectedIndex;
      _remember();
    }
  }

  @override
  void dispose() {
    _disposeNodes(_nodes);
    super.dispose();
  }

  void _disposeNodes(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.removeListener(_onFocusChange);
      node.dispose();
    }
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // A key press means the focus ring is being used for navigation again.
    if (_focusFromPointer) {
      _focusFromPointer = false;
      if (mounted) setState(() {});
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      widget.links[index].onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // The rows have to grow with the text or the pill would sit on the wrong
    // row at 200% (one ellipsised line still gets taller).
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.2);
    final height = ClayNavList.rowHeight * scale;
    final stride = height + ClayNavList.gap;
    final radius = BorderRadius.circular(ClayNavList.radius);
    final selected = widget.selectedIndex;

    return Stack(
      // The pill's glow must not be cut off at the first and last row.
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: motionDuration(context, CScholarDurations.fast),
          curve: CScholarCurves.standard,
          left: 0,
          right: 0,
          top: (_pillIndex < 0 ? 0 : _pillIndex) * stride,
          height: height,
          child: AnimatedOpacity(
            duration: motionDuration(context, CScholarDurations.fast),
            opacity: selected < 0 ? 0 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: CScholarColors.primaryGreenLight,
                borderRadius: radius,
                boxShadow: CScholarMaterial.softShadow(depth: 0.35),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.links.length; i++) ...[
              if (i > 0) const SizedBox(height: ClayNavList.gap),
              _row(i, height, radius),
            ],
          ],
        ),
      ],
    );
  }

  /// One row: glyph + ellipsised label, sunk while pressed, ringed on focus.
  Widget _row(int index, double height, BorderRadius radius) {
    final link = widget.links[index];
    final isSelected = widget.selectedIndex == index;
    final foreground = isSelected
        ? CScholarColors.primaryGreen
        : CScholarColors.textSecondary;

    final body = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // Static glyph: on navigation only the pill moves. The outline <->
            // filled morph used to fade and pop here, which read as a second,
            // competing motion next to the travelling pill. Both glyphs share
            // the fixed 20px box, so the instant swap cannot nudge the label.
            Icon(
              isSelected ? link.selectedIcon : link.icon,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                link.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  13,
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Focus(
      focusNode: _nodes[index],
      onKeyEvent: (_, event) => _onKey(index, event),
      child: PressableSurface(
        semanticLabel: link.label,
        radius: ClayNavList.radius,
        // The sink is small here: a nav row that scaled much would read as a
        // button.
        sink: 1.5,
        scale: 0.99,
        onTap: () {
          _focusFromPointer = true;
          setState(() {});
          _nodes[index].requestFocus();
          link.onTap();
        },
        child: Stack(
          children: [
            body,
            // Painted OVER the row, never around it: a ring built from padding
            // would make one row taller than the others and de-sync the pill.
            // Always present with an animated border ALPHA (not a colour
            // tween between two hues — that passes through low-contrast
            // midpoints), so focus fades in over micro and ends at the ring's
            // full 0.45 gel strength.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: motionDuration(context, CScholarMotion.micro),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: CScholarMaterial.gelTop.withValues(
                        alpha: _focused == index && !_focusFromPointer
                            ? 0.45
                            : 0,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
