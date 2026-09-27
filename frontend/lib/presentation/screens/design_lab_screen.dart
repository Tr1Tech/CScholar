import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';

/// DEV ONLY — CScholar design lab (route: `/design-lab`).
///
/// Renders every material (clay / glass), every component state
/// (rest, hover, pressed, focus, disabled) and every accessibility fallback
/// (high contrast, reduced motion, 200% text) in one place, so the look can be
/// judged by feel before it is applied across the app.
///
/// The route is compiled out of release builds — see [kEnableDesignLab] in
/// `core/router/app_router.dart`.
class DesignLabScreen extends StatefulWidget {
  const DesignLabScreen({super.key});

  @override
  State<DesignLabScreen> createState() => _DesignLabScreenState();
}

class _DesignLabScreenState extends State<DesignLabScreen> {
  bool _glassOn = true;
  bool _highContrast = false;
  bool _reduceMotion = false;
  double _textScale = 1;
  int _demoSegment = 0;

  static const List<String> _segmentLabels = ['Keyword', 'Semantic', 'Saved'];

  int get _textScaleIndex => _textScale <= 1 ? 0 : (_textScale < 1.5 ? 1 : 2);

  @override
  void initState() {
    super.initState();
    CScholarMaterial.glassEnabled = _glassOn;
  }

  @override
  void dispose() {
    // Leave the global switch exactly as we found it.
    CScholarMaterial.glassEnabled = true;
    super.dispose();
  }

  void _setGlass(bool on) {
    setState(() => _glassOn = on);
    CScholarMaterial.glassEnabled = on;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: _highContrast,
        disableAnimations: _reduceMotion,
        textScaler: TextScaler.linear(_textScale),
      ),
      child: Scaffold(
        backgroundColor: CScholarMaterial.canvas,
        body: GlassGroup(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _sections(),
                    ),
                  ),
                ),
              ),
              // The bar is glass on purpose: scroll and watch the clay content
              // blur underneath it — that is the real test of the effect.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(bottom: false, child: _controlBar()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClayIconTile(
                    icon: Icons.science_outlined, size: 34, gold: true),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Design Lab',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.poppins(
                            16, FontWeight.w700, CScholarMaterial.textPrimary),
                      ),
                      Text(
                        'clay · glass · DEV ONLY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(
                            11.5, FontWeight.w400, CScholarMaterial.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            NeumorphToggle(
              value: _glassOn,
              onChanged: _setGlass,
              label: 'Glass / blur',
            ),
            NeumorphToggle(
              value: _highContrast,
              onChanged: (v) => setState(() => _highContrast = v),
              label: 'High contrast',
            ),
            NeumorphToggle(
              value: _reduceMotion,
              onChanged: (v) => setState(() => _reduceMotion = v),
              label: 'Reduced motion',
            ),
            SizedBox(
              width: 220,
              child: NeumorphSegmented(
                labels: const ['1.0', '1.3', '2.0'],
                selectedIndex: _textScaleIndex,
                onChanged: (i) => setState(
                    () => _textScale = const [1.0, 1.3, 2.0][i.clamp(0, 2)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections() => [
        _swatchBoard(),
        _contrastBoard(),
        _materialCompare(),
        _clayLadder(),
        _glassBoard(),
        _stateBoard(),
        _identityBoard(),
        _rulesBoard(),
      ];

  Widget _section({
    required String title,
    required String note,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: ClaySurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: CScholarTextStyles.poppins(
                  20, FontWeight.w700, CScholarMaterial.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: CScholarTextStyles.inter(
                  13, FontWeight.w400, CScholarMaterial.textMuted),
            ),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }

  Widget _eyebrow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: CScholarTextStyles.inter(11, FontWeight.w700,
              CScholarMaterial.textMuted,
              letterSpacing: 1),
        ),
      );

  /// Every state of one control, side by side — this is why `previewState`
  /// exists on the clay controls.
  Widget _stateRow(String label, Widget Function(NeumorphState) build) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(label),
          Wrap(
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final state in NeumorphState.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    build(state),
                    const SizedBox(height: 8),
                    Text(
                      state.name,
                      style: CScholarTextStyles.inter(11, FontWeight.w500,
                          CScholarMaterial.textFaint),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swatch(
    String name,
    String hex,
    Color color, {
    bool glow = false,
    double glowStrength = 1,
  }) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
              border: Border.all(
                color: glow ? Colors.transparent : CScholarMaterial.rim,
              ),
              boxShadow: glow
                  ? CScholarMaterial.goldGlow(strength: glowStrength)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            style: CScholarTextStyles.inter(
                12, FontWeight.w600, CScholarMaterial.textPrimary),
          ),
          Text(
            hex,
            style: CScholarTextStyles.inter(
                11, FontWeight.w400, CScholarMaterial.textFaint),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline,
                size: 16, color: CScholarMaterial.textGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: CScholarTextStyles.inter(
                  13, FontWeight.w400, CScholarMaterial.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Row on wide screens, stacked on narrow. The lab must survive 200% text
  /// scale itself, so nothing here uses a fixed height.
  Widget _columns(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: child,
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 18),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _swatchBoard() {
    return _section(
      title: '1 · Tokens',
      note: 'Canvas and clay share a hue family on purpose: a tinted shadow (#C9D6C6, never black) only reads as depth when the surface and the canvas under it come from the same family.',
      child: Wrap(
        spacing: 14,
        runSpacing: 16,
        children: [
          _swatch('canvas', '#E8EFE7', CScholarMaterial.canvas),
          _swatch('clay', '#F1F6F0', CScholarMaterial.clay),
          _swatch('clay deep', '#E3EBE1', CScholarMaterial.clayDeep),
          _swatch('gel top', '#007A14', CScholarMaterial.gelTop),
          _swatch('gel bottom', '#00610F', CScholarMaterial.gelBottom),
          _swatch('gel high · non-text', '#00A31B', CScholarMaterial.gelHigh),
          _swatch('gold · glows', '#F9DC07', CScholarMaterial.goldTop,
              glow: true),
          _swatch('gold core · halo centre', '#FFE066', CScholarMaterial.goldCore,
              glow: true, glowStrength: 1.4),
          _swatch('gold deep', '#CA8A04', CScholarMaterial.goldBottom),
          _swatch('rim · hairline', '#C3D0C0', CScholarMaterial.rim),
          _swatch('rim strong · high contrast', '#475569',
              CScholarMaterial.rimStrong),
          _swatch('glass chrome · 62% white', 'FFFFFF 62%',
              CScholarMaterial.glassChrome),
          _swatch('scrim · overlays', '0F172A 28%', CScholarMaterial.scrim),
        ],
      ),
    );
  }

  Widget _contrastBoard() {
    return _section(
      title: '2 · Measured contrast (WCAG 2.1)',
      note: 'These numbers were measured during the audit and are baked into the tokens. Anything under 4.5:1 is decoration or graphics only — never text.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in CScholarMaterial.ratios.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: CScholarTextStyles.inter(12.5, FontWeight.w500,
                          CScholarMaterial.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ratioPill(entry.value),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ratioPill(double ratio) {
    final pass = ratio >= 4.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pass ? CScholarMaterial.gelTop : CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(
          color: pass ? Colors.transparent : CScholarMaterial.rim,
        ),
      ),
      child: Text(
        '${ratio.toStringAsFixed(2)}:1',
        style: CScholarTextStyles.inter(
          11.5,
          FontWeight.w700,
          pass ? Colors.white : CScholarMaterial.textMuted,
        ),
      ),
    );
  }

  /// One demo card, rendered in three materials below.
  Widget _demoCard(String title, String meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClayIconTile(
                icon: Icons.article_outlined, size: 36, gel: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CScholarTextStyles.inter(
                        14.5, FontWeight.w700, CScholarMaterial.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: CScholarTextStyles.inter(
                        11.5, FontWeight.w400, CScholarMaterial.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const ClayProgressBar(value: 0.86, height: 8),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '86% relevant',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.inter(
                    11.5, FontWeight.w700, CScholarMaterial.textGreen),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '2024 – 2025',
              style: CScholarTextStyles.inter(
                  11, FontWeight.w400, CScholarMaterial.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _materialCompare() {
    return _section(
      title: '3 · Same content, three materials',
      note: 'Clay for content panels, glass for anything that floats, flat for high contrast. The right-hand column is the automatic high-contrast fallback — same layout, no shadows, no blur.',
      child: _columns([
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('clay · content panel'),
            ClaySurface(
              child: _demoCard('OCR-based Hybrid Image Text Summarizer',
                  'BS Computer Science'),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('glass · floating panel'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF003800), Color(0xFF005A1E)],
                ),
              ),
              child: GlassPanel(
                fill: CScholarMaterial.glassOverlay,
                blur: CScholarMaterial.blurOverlay,
                child: _demoCard(
                    'Indoor Positioning System', 'BS Information Technology'),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('high contrast fallback'),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: true),
              child: ClaySurface(
                child: _demoCard('Campus Navigation and Room Locator',
                    'BS Information Technology'),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _clayLadder() {
    return _section(
      title: '4 · Clay depth & radius',
      note: 'Depth controls how far a panel floats. Cards sit at 0.5–1.0; 1.5 is a hero moment and should stay rare. Clay is a fill + ONE soft shadow — compare the rimmed sample to see what a drawn outline adds, and why only high contrast uses one.',
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          _claySample('depth 0.5 · r16', 0.5, 16),
          _claySample('depth 1.0 · r16', 1, 16),
          _claySample('depth 1.5 · r16', 1.5, 16),
          _claySample('depth 1.0 · rimmed', 1, 16, rim: true),
          _claySample('depth 1.0 · r8', 1, 8),
          _claySample('depth 1.0 · r24', 1, 24),
        ],
      ),
    );
  }

  Widget _claySample(String label, double depth, double radius,
      {bool rim = false}) {
    return SizedBox(
      width: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClaySurface(
            depth: depth,
            radius: radius,
            showRim: rim,
            padding: const EdgeInsets.all(18),
            child: const Center(
              child: Icon(Icons.dashboard_outlined,
                  size: 26, color: CScholarMaterial.textGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: CScholarTextStyles.inter(
                11, FontWeight.w500, CScholarMaterial.textFaint),
          ),
        ],
      ),
    );
  }

  Widget _glassBoard() {
    return _section(
      title: '5 · Glass',
      note: 'Glass is for layers that float. Every panel on this page shares one blur pass through BackdropGroup, so Flutter filters the backdrop once instead of once per panel. Scroll and watch the clay blur under the bar above.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('over the clay canvas'),
          _columns([
            GlassPanel(
              child: _glassCopy('chrome · blur 18', 'Topbars, nav rails, sticky search'),
            ),
            GlassPanel(
              fill: CScholarMaterial.glassOverlay,
              blur: CScholarMaterial.blurOverlay,
              child: _glassCopy('overlay · blur 28', 'Dialogs, sheets, toasts'),
            ),
          ]),
          const SizedBox(height: 22),
          _eyebrow('over a hero gradient — the real test'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF003800), Color(0xFF005A1E), Color(0xFF008000)],
              ),
            ),
            child: _columns([
              GlassPanel(
                child: _glassCopy('repository search bar', 'Sticky, above scrolling results'),
              ),
              GlassPanel(
                fill: CScholarMaterial.glassOverlay,
                blur: CScholarMaterial.blurOverlay,
                child: _glassCopy('AI recommendations rail', 'Right-hand panel'),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          _eyebrow('scrim + overlay glass'),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: CScholarMaterial.scrim,
              borderRadius: BorderRadius.circular(CScholarRadius.lg),
            ),
            child: Center(
              child: GlassPanel(
                fill: CScholarMaterial.glassOverlay,
                blur: CScholarMaterial.blurOverlay,
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete this study?',
                        style: CScholarTextStyles.poppins(
                            16, FontWeight.w700, CScholarMaterial.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This cannot be undone.',
                        style: CScholarTextStyles.inter(12.5, FontWeight.w400,
                            CScholarMaterial.textMuted),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          NeumorphButton(
                              label: 'Cancel', gel: false, onPressed: () {}),
                          NeumorphButton(
                              label: 'Delete',
                              icon: Icons.delete_outline,
                              onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCopy(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: CScholarTextStyles.inter(
              13.5, FontWeight.w700, CScholarMaterial.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: CScholarTextStyles.inter(
              12, FontWeight.w400, CScholarMaterial.textMuted),
        ),
      ],
    );
  }

  Widget _stateBoard() {
    return _section(
      title: '6 · Clay controls — all five states',
      note: 'Press and hold anything below: one progress value drives the gradient, the shadow depth and a 1.5px sink, so the states can never de-sync. Tab through them to see the focus ring appear.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stateRow(
            'gel button · primary',
            (state) => NeumorphButton(
              label: 'View Details',
              icon: Icons.arrow_forward,
              previewState: state,
              onPressed: () {},
            ),
          ),
          _stateRow(
            'clay button · secondary',
            (state) => NeumorphButton(
              label: 'Browse',
              icon: Icons.menu_book_outlined,
              gel: false,
              previewState: state,
              onPressed: () {},
            ),
          ),
          _stateRow(
            'icon button',
            (state) => NeumorphIconButton(
              icon: Icons.bookmark_outline,
              tooltip: 'Save study',
              previewState: state,
              onPressed: () {},
            ),
          ),
          _stateRow(
            'toggle',
            (state) => NeumorphToggle(
              value: true,
              label: 'Semantic',
              previewState: state,
              onChanged: (_) {},
            ),
          ),
          _eyebrow('input field · rest, focus, disabled, error'),
          Wrap(
            spacing: 20,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              for (final state in const [
                NeumorphState.rest,
                NeumorphState.focus,
                NeumorphState.disabled,
              ])
                SizedBox(
                  width: 240,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeumorphField(
                        label: 'Keyword',
                        hintText: 'Type to preview',
                        prefixIcon: Icons.search,
                        previewState: state,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.name,
                        style: CScholarTextStyles.inter(11, FontWeight.w500,
                            CScholarMaterial.textFaint),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: 240,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphField(
                      label: 'CSU email',
                      hintText: 'you@csu.edu.ph',
                      errorText: 'Enter a valid CSU email',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'error',
                      style: CScholarTextStyles.inter(
                          11, FontWeight.w500, CScholarMaterial.textFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _eyebrow('segmented — tap to watch the pill glide'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: StatefulBuilder(
              builder: (context, setLocal) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeumorphSegmented(
                    labels: _segmentLabels,
                    selectedIndex: _demoSegment,
                    onChanged: (v) => setLocal(() => _demoSegment = v),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selected: ${_segmentLabels[_demoSegment.clamp(0, _segmentLabels.length - 1)]}',
                    style: CScholarTextStyles.inter(
                        12, FontWeight.w500, CScholarMaterial.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityBoard() {
    return _section(
      title: '7 · Clay identity objects',
      note: 'Gel tiles, avatars, chips and progress fills. Initials are white: gold on green measures 2.75:1, so gold stays on the dark hero surfaces where it reads at 8:1+.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('icon tiles'),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ClayIconTile(icon: Icons.article_outlined, size: 44),
              ClayIconTile(icon: Icons.school_outlined, size: 44),
              ClayIconTile(icon: Icons.science_outlined, size: 44),
              ClayIconTile(icon: Icons.article_outlined, size: 44, gel: false),
              ClayIconTile(icon: Icons.tune, size: 44, gel: false),
            ],
          ),
          const SizedBox(height: 24),
          _eyebrow('avatars'),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GelAvatar(name: 'Juan Dela Cruz', size: 46),
              GelAvatar(name: 'Ralph Martinez', size: 36),
              GelAvatar(name: 'A', size: 28),
            ],
          ),
          const SizedBox(height: 24),
          _eyebrow('chips · selected vs raised'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const ClayChip(label: 'All programs', selected: true),
              const ClayChip(label: 'BSIT', onTap: null),
              const ClayChip(label: 'BSCS'),
              const ClayChip(
                  label: 'Thesis', icon: Icons.check, selected: true),
              const ClayChip(label: 'Capstone', icon: Icons.bookmark_outline),
            ],
          ),
          const SizedBox(height: 24),
          _eyebrow('gold · the only coloured shadow'),
          Wrap(
            spacing: 22,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _glowSample('0.6 · hint', 0.6),
              _glowSample('1.0 · default', 1.0),
              _glowSample('1.5 · lamp', 1.5),
              _glowSample('high contrast · flat', 1.0, highContrast: true),
            ],
          ),
          const SizedBox(height: 24),
          _eyebrow('progress · painted, not laid out · last fills on a timer'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: const Column(
              children: [
                ClayProgressBar(value: 0.96),
                SizedBox(height: 12),
                ClayProgressBar(value: 0.62, height: 8),
                SizedBox(height: 12),
                ClayProgressBar(value: 0.24, height: 8),
                SizedBox(height: 12),
                ClayLoader(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rulesBoard() {
    return _section(
      title: '8 · Rules this system obeys',
      note: 'The guardrails that stop clay + glass from turning into mush — and where not to use them at all.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bullet(
              'One style per structural role: clay = content and pressable, glass = floating, gel = identity. Never two on one element.'),
          _bullet(
              'Lightest text on clay or glass is #475569 (6.92:1). #64748B is 4.35:1 on clay — white surfaces only.'),
          _bullet(
              'Green text is #007A14 (5.06:1). #009900 is graphics only: it is 3.23:1 as text.'),
          _bullet(
              'Gold glows: the halo is the only coloured shadow in the system. 1.26:1 on clay as a colour, so it is light or a gradient — never body text — and at most 3 glowing objects per screen.'),
          _bullet(
              'Gold objects carry a DARK glyph: #0F172A is 12.98:1 on the top stop and 6.08:1 on the bottom. White on gold is 1.38:1 — never.'),
          _bullet(
              'Controls draw NO rim at rest — the fill plus one soft shadow is the edge. Focus, error and high contrast draw a 1.5px rim, because shadow alone is not an affordance.'),
          _bullet(
              'No glass inside scrolling list items, and never more than two glass layers per screen — wrap them in one BackdropGroup.'),
          _bullet(
              'Admin tables, long abstracts and dense forms stay flat: clay on the wrapper, 1px separators in the rows.'),
          _bullet(
              'Clay covers under ~25% of a viewport. It is seasoning, not the meal.'),
          _bullet(
              '200% text must grow the panels, never clip them — no fixed heights on clay surfaces.'),
        ],
      ),
    );
  }

  /// The gold halo at three strengths, plus the high-contrast fallback.
  /// Padded so the wide falloff layer has room to bloom rather than clip.
  Widget _glowSample(
    String label,
    double strength, {
    bool highContrast = false,
  }) {
    final tile = ClayIconTile(
      icon: Icons.workspace_premium_outlined,
      size: 46,
      gold: true,
      glowStrength: strength,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: highContrast
              ? MediaQuery(
                  data: MediaQuery.of(context).copyWith(highContrast: true),
                  child: tile,
                )
              : tile,
        ),
        Text(
          label,
          style: CScholarTextStyles.inter(
              11, FontWeight.w500, CScholarMaterial.textFaint),
        ),
      ],
    );
  }






}
