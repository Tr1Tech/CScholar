import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/thesis_card.dart';

class ThesisDetailScreen extends ConsumerStatefulWidget {
  final int thesisId;

  /// Query-relative semantic match (0..1), handed through the route's `extra`
  /// by semantic entry points. Null on direct loads and keyword entries —
  /// the meter stays off rather than metering a number nobody computed.
  final double? similarity;

  const ThesisDetailScreen({
    super.key,
    required this.thesisId,
    this.similarity,
  });

  @override
  ConsumerState<ThesisDetailScreen> createState() => _ThesisDetailScreenState();
}

class _ThesisDetailScreenState extends ConsumerState<ThesisDetailScreen> {
  int get thesisId => widget.thesisId;
  double? get similarity => widget.similarity;

  @override
  void initState() {
    super.initState();
    _scheduleViewRecord();
  }

  @override
  void didUpdateWidget(covariant ThesisDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Moving from /thesis/59 to /thesis/46 can reuse this State; without this
    // the second study would never enter the history.
    if (oldWidget.thesisId != widget.thesisId) _scheduleViewRecord();
  }

  void _scheduleViewRecord() {
    // The last-opened study becomes the dashboard feed's anchor. Local-only
    // (SharedPreferences); the id is sent to the server only when the
    // dashboard asks for recommendations. Deferred to after the frame because
    // Riverpod forbids state writes during initState/build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(recommendationAnchorProvider.notifier)
          .setAnchor(thesisId, 'viewed');
    });
  }

  @override
  Widget build(BuildContext context) => _build(context, ref);

  Widget _build(BuildContext context, WidgetRef ref) {
    final thesisAsync = ref.watch(thesisDetailProvider(thesisId));
    final recommendedAsync = ref.watch(recommendedThesesProvider(thesisId));
    final savedIds = ref.watch(savedThesisIdsProvider);
    final isSaved = savedIds.contains(thesisId);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > CScholarBreakpoints.mobile;
    final user = ref.watch(currentUserProvider);
    final isFaculty = user?.role == 'faculty';
    final isAdmin = user?.role == 'admin';
    final isStudent = !isFaculty && !isAdmin;
    final homeRoute = isFaculty
        ? '/faculty/dashboard'
        : isAdmin
        ? '/admin/dashboard'
        : '/student/dashboard';
    final listRoute = isFaculty
        ? '/faculty/theses'
        : isAdmin
        ? '/admin/thesis/management'
        : '/repository';
    final listLabel = isFaculty
        ? 'My Theses'
        : isAdmin
        ? 'Thesis Management'
        : 'Repository';

    final content = asyncSlot(
      thesisAsync,
      // One page, one height: the skeleton the switcher cross-fades from is
      // the loader this branch used to return.
      skeleton: const SkeletonList(count: 3, cardHeight: 96),
      data: (thesis) {
        if (thesis == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: CScholarColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thesis not found',
                  style: CScholarTextStyles.heading(
                    18,
                    FontWeight.w600,
                    CScholarColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphButton(
                  onPressed: () => context.go(listRoute),
                  label: 'Back to List',
                ),
              ],
            ),
          );
        }

        // Every value below comes straight from the database record.
        final authorsStr = thesis.authorsString;
        final programStr = thesis.program?.name ?? '';
        final yearStr = thesis.academicYear?.label ?? '';
        final adviserStr =
            thesis.advisers != null && thesis.advisers!.isNotEmpty
            ? thesis.advisers!.first.fullName
            : '';

        return SingleChildScrollView(
          // The banner flies in as a Hero target, so it sits OUTSIDE the
          // stagger and never fades — a hero that fades while flying is
          // doubled. Breadcrumbs and card cascade beneath it, header-first.
          child: Column(
            children: [
              _heroBanner(thesis),
              StaggerColumn(
                pitch: MotionPitch.page,
                children: [
                  // 1. Breadcrumbs Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: CScholarMaterial.clay,
                      border: Border(
                        bottom: BorderSide(color: CScholarMaterial.rim),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.go(homeRoute),
                          child: Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 16,
                                color: CScholarColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Home',
                                style: CScholarTextStyles.body(
                                  12.5,
                                  FontWeight.w500,
                                  CScholarColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '  /  ',
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w400,
                            CScholarColors.textHint,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go(listRoute),
                          child: Text(
                            listLabel,
                            style: CScholarTextStyles.body(
                              12.5,
                              FontWeight.w500,
                              CScholarColors.primaryGreen,
                            ),
                          ),
                        ),
                        Text(
                          '  /  ',
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w400,
                            CScholarColors.textHint,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            thesis.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              12.5,
                              FontWeight.w600,
                              CScholarColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Main Content Card Container
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40 : 20,
                      vertical: 32,
                    ),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 1120),
                        padding: EdgeInsets.all(isDesktop ? 36 : 22),
                        decoration: BoxDecoration(
                          color: CScholarMaterial.clay,
                          borderRadius: BorderRadius.circular(
                            CScholarRadius.softCard,
                          ),
                          border: Border.all(color: CScholarMaterial.rim),
                          boxShadow: CScholarShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Overview: metadata and actions
                            _buildMetadataAndActions(
                              context,
                              ref,
                              thesis: thesis,
                              isSaved: isSaved,
                              showSave: isStudent,
                              authorsStr: authorsStr,
                              programStr: programStr,
                              yearStr: yearStr,
                              adviserStr: adviserStr,
                            ),

                            const SizedBox(height: 36),
                            Divider(color: CScholarColors.borderLight),
                            const SizedBox(height: 24),

                            // Abstract Section (only when the database has one).
                            // One beat behind the title (+100): the eye finishes
                            // the title, then the abstract arrives. The wrapper
                            // is a stretch column so justification and the
                            // full-width row lay out exactly as before.
                            if (thesis.abstract.isNotEmpty)
                              Stagger(
                                index: 2,
                                step: MotionPitch.page.step,
                                max: MotionPitch.page.max,
                                rise: MotionPitch.page.rise,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'ABSTRACT',
                                      style: CScholarTextStyles.body(
                                        12,
                                        FontWeight.w700,
                                        CScholarColors.textSecondary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _displayAbstract(thesis.abstract),
                                            textAlign: TextAlign.justify,
                                            style: CScholarTextStyles.body(
                                              14.5,
                                              FontWeight.w400,
                                              CScholarMaterial.textBody,
                                              height: 1.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // Keywords Section (only when the database has them)
                            if (thesis.keywords != null &&
                                thesis.keywords!.isNotEmpty) ...[
                              if (thesis.abstract.isNotEmpty)
                                const SizedBox(height: 28),
                              Text(
                                'KEYWORDS',
                                style: CScholarTextStyles.body(
                                  11.5,
                                  FontWeight.w700,
                                  CScholarColors.textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: thesis.keywords!
                                    .map((k) => _keywordChip(k.term))
                                    .toList(),
                              ),
                            ],

                            const SizedBox(height: 40),
                            Divider(color: CScholarColors.borderLight),
                            const SizedBox(height: 24),

                            // Related research: nearest neighbours of THIS
                            // study by embedding distance. Not personalized.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Related research',
                                  style: CScholarTextStyles.heading(
                                    18,
                                    FontWeight.w700,
                                    CScholarColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Closest matches by meaning, not keywords',
                                  style: CScholarTextStyles.body(
                                    12.5,
                                    FontWeight.w400,
                                    CScholarColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                asyncSlot(
                                  recommendedAsync,
                                  skeleton: const SkeletonList(
                                    count: 3,
                                    cardHeight: 56,
                                  ),
                                  data: (recs) {
                                    if (recs.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: Text(
                                            'No recommendations yet',
                                            style: CScholarTextStyles.body(
                                              12,
                                              FontWeight.w500,
                                              CScholarColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final displayList = recs
                                        .map(
                                          (r) => {
                                            'title': r.thesis.title,
                                            'sim':
                                                '${(r.similarity * 100).round()}% similar',
                                            'id': r.thesis.id,
                                          },
                                        )
                                        .toList();

                                    return Column(
                                      // Related studies step on the result
                                      // pitch: the same walk as every thesis
                                      // result list in the app.
                                      children: displayList.asMap().entries.map((
                                        entry,
                                      ) {
                                        final item = entry.value;
                                        final title = item['title'] as String;
                                        final sim = item['sim'] as String;
                                        final targetId = item['id'] as int;

                                        return Stagger(
                                          index: entry.key,
                                          step: MotionPitch.result.step,
                                          max: MotionPitch.result.max,
                                          rise: MotionPitch.result.rise,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    CScholarRadius.lg,
                                                  ),
                                              onTap: () => context.go(
                                                '/thesis/$targetId',
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      CScholarMaterial.clayDeep,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        CScholarRadius.lg,
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClayIconTile(
                                                      icon: Icons
                                                          .article_outlined,
                                                      size: 36,
                                                      gel: false,
                                                      background: CScholarColors
                                                          .primaryGreenLight,
                                                      tint: CScholarColors
                                                          .primaryGreen,
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style:
                                                            CScholarTextStyles.body(
                                                              13.5,
                                                              FontWeight.w600,
                                                              CScholarColors
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                    ),
                                                    Tooltip(
                                                      message:
                                                          'Semantic similarity — $sim to the study you are viewing.',
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: CScholarColors
                                                              .primaryGreenLight,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                CScholarRadius
                                                                    .full,
                                                              ),
                                                          border: Border.all(
                                                            color: CScholarColors
                                                                .primaryGreen
                                                                .withValues(
                                                                  alpha: 0.25,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .auto_awesome,
                                                              size: 11,
                                                              color:
                                                                  CScholarColors
                                                                      .primaryGreen,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              sim,
                                                              style: CScholarTextStyles.body(
                                                                11.5,
                                                                FontWeight.w700,
                                                                CScholarColors
                                                                    .primaryGreen,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                  error: (err, _) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Text(
                                        'Unable to load recommendations: $err',
                                        style: CScholarTextStyles.body(
                                          12,
                                          FontWeight.w500,
                                          CScholarColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      error: (err, _) => Center(child: Text('Error: $err')),
    );

    if (isStudent) {
      if (MobileStudentScaffold.useMobileShell(context)) {
        return StudentLayout(
          currentIndex: 1,
          // Prototype depth state: no bottom nav, back action + focused title.
          isDepth: true,
          depthTitle: 'Thesis details',
          depthBackRoute: listRoute,
          child: _mobileDetail(
            context,
            ref,
            thesisAsync: thesisAsync,
            recommendedAsync: recommendedAsync,
            isSaved: isSaved,
            thesisId: thesisId,
          ),
        );
      }
      return StudentLayout(currentIndex: 1, child: content);
    }

    final sidebar = isAdmin
        ? const AdminSidebar(currentPath: '/admin/thesis/management')
        : const FacultySidebar(currentPath: '/faculty/theses');

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: CScholarMaterial.canvas,
        appBar: AppBar(
          backgroundColor: CScholarMaterial.clay,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: CScholarColors.textPrimary,
            ),
            onPressed: () => context.go(listRoute),
          ),
          title: Text(
            'Thesis Details',
            style: TextStyle(
              color: CScholarColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: CScholarMaterial.canvas,
      body: Row(
        children: [
          sidebar,
          Expanded(child: content),
        ],
      ),
    );
  }

  /// Mobile Detail (`cscholar-mobile-ui/src/App.tsx:749-837`): eyebrow,
  /// title, author line, Read PDF + Save, abstract, collapsed details,
  /// Related capped at 3. Same providers and `?token=` PDF flow — only
  /// the layout is prototype-skinned.
  Widget _mobileDetail(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<Thesis?> thesisAsync,
    required AsyncValue<List<SemanticResult>> recommendedAsync,
    required bool isSaved,
    required int thesisId,
  }) {
    final t = CScholarMobileTheme.of(context);
    return asyncSlot<Thesis?>(
      thesisAsync,
      // Inset to the page gutter: the loaded content is padded, so a full-bleed
      // skeleton would jump sideways the moment the record lands.
      skeleton: const Padding(
        padding: EdgeInsets.fromLTRB(20, 9, 20, 0),
        child: SkeletonList(count: 3, cardHeight: 96),
      ),
      data: (thesis) {
        if (thesis == null) {
          return Center(child: Text('Thesis not found', style: t.body));
        }
        final authorsStr = thesis.authorsString;
        final programStr = thesis.program?.name ?? '';
        // The mobile eyebrow is a scannable code ("BSIT"), not the full
        // "Bachelor of Science in Information Technology" — the full name
        // still lives under Research details.
        final programCode = (thesis.program?.code ?? '').trim();
        final programLabel = programCode.isNotEmpty
            ? programCode.toUpperCase()
            : programStr;
        final yearStr = thesis.academicYear?.label ?? '';
        final adviserStr =
            thesis.advisers != null && thesis.advisers!.isNotEmpty
            ? thesis.advisers!.first.fullName
            : '';

        String initials = '';
        if (authorsStr.isNotEmpty) {
          final parts = authorsStr
              .split(',')
              .first
              .trim()
              .split(RegExp(r'\s+'));
          if (parts.length == 1) {
            initials = parts.first
                .substring(0, parts.first.length >= 2 ? 2 : 1)
                .toUpperCase();
          } else {
            initials = (parts[0][0] + parts[1][0]).toUpperCase();
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 106),
          child: StaggerColumn(
            pitch: MotionPitch.page,
            children: [
              // Research type at a glance, so the header identifies the work
              // even when the title itself runs long.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$programLabel · $yearStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.eyebrow,
                    ),
                  ),
                  if (thesis.researchType.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: t.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        thesis.researchType.toUpperCase(),
                        style: t.dmSans(
                          8,
                          FontWeight.w800,
                          t.green,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // It is metadata, not a headline: 27px turned a normal thesis
              // title into six lines of shouting on a phone. 21px with a
              // tighter lead keeps the full title readable (no truncation —
              // students need the exact title for citations).
              Text(
                thesis.title,
                style: t.manrope(
                  21,
                  FontWeight.w700,
                  t.ink,
                  height: 1.28,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // tile-exempt: author initials avatar.
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: t.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: t.dmSans(10, FontWeight.w800, t.green),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // The author list is data, so it can be any length. Without
                  // the flex the row overflowed horizontally on long bylines
                  // (the yellow/black strip in the mobile detail).
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorsStr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.dmSans(11, FontWeight.w700, t.ink),
                        ),
                        Text(
                          'Undergraduate researcher',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.dmSans(9, FontWeight.w400, t.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    // Flat solid green pill, like the reference button: the gel
                    // surface (gradient + gloss) read as a chip, not a button.
                    // With no manuscript the pill falls back to the same
                    // disabled "No PDF" state as the web action row.
                    child: _MobileActionPill(
                      icon: Icons.remove_red_eye_outlined,
                      label: thesis.pdfUrl == null ? 'No PDF' : 'Read PDF',
                      // Same pill shape and white label, but the no-manuscript
                      // state sits on the lighter green so it reads as
                      // inactive next to the full "Read PDF" action.
                      fill: thesis.pdfUrl == null
                          ? CScholarMobileColors.green2
                          : CScholarMobileColors.green,
                      ink: CScholarColors.white,
                      onTap: thesis.pdfUrl == null
                          ? null
                          : () => _openPdf(context, ref, thesisId: thesis.id),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 2,
                    // Same pill, secondary weight: a real fill at rest (the old
                    // surfaceSoft wash read as a transparent hole) and mint once
                    // saved — flat colours, no gradient.
                    child: _MobileActionPill(
                      icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      label: isSaved ? 'Saved' : 'Save',
                      // Theme-aware so the secondary pill does not stay a
                      // white slab on the dark mobile canvas.
                      fill: isSaved ? t.mint : t.surfaceSoft,
                      ink: isSaved ? t.green : t.ink,
                      border: isSaved ? null : t.line,
                      onTap: () {
                        ref
                            .read(savedThesisIdsProvider.notifier)
                            .toggle(thesis.id);
                        MobileToast.show(
                          context,
                          isSaved
                              ? 'Removed from saved'
                              : 'Saved to your library',
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (thesis.abstract.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(top: 28),
                  padding: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Abstract', style: t.eyebrow),
                      const SizedBox(height: 9),
                      Text(
                        _displayAbstract(thesis.abstract),
                        textAlign: TextAlign.justify,
                        style: t.dmSans(
                          12,
                          FontWeight.w400,
                          t.ink,
                          height: 1.72,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                margin: const EdgeInsets.only(top: 28),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: t.line),
                    bottom: BorderSide(color: t.line),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(
                    'Research details',
                    style: t.dmSans(11, FontWeight.w800, t.ink),
                  ),
                  trailing: Icon(Icons.chevron_right, size: 18, color: t.muted),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: t.surfaceSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        children: [
                          // Parity with the web metadata block: the eyebrow
                          // shows the short course code + year, the full
                          // program name and the rest of the record live here.
                          if (programStr.isNotEmpty)
                            _detailRow(context, 'Program', programStr),
                          if (yearStr.isNotEmpty)
                            _detailRow(context, 'Academic year', yearStr),
                          if (thesis.researchType.isNotEmpty)
                            _detailRow(context, 'Type', thesis.researchType),
                          if (thesis.categoriesString.isNotEmpty)
                            _detailRow(
                              context,
                              'Category',
                              thesis.categoriesString,
                            ),
                          if (adviserStr.isNotEmpty)
                            _detailRow(context, 'Adviser', adviserStr),
                          if (thesis.status.isNotEmpty)
                            _detailRow(
                              context,
                              'Status',
                              '${thesis.status[0].toUpperCase()}'
                                  '${thesis.status.substring(1)}',
                            ),
                          if (thesis.keywords != null &&
                              thesis.keywords!.isNotEmpty)
                            _detailRow(
                              context,
                              'Keywords',
                              thesis.keywords!.map((k) => k.term).join(', '),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Keep exploring', style: t.eyebrow),
              const SizedBox(height: 3),
              Text('Related research', style: t.sectionTitle),
              const SizedBox(height: 12),
              asyncSlot<List<SemanticResult>>(
                recommendedAsync,
                skeleton: const SkeletonList(count: 3, cardHeight: 56),
                data: (recs) {
                  if (recs.isEmpty) {
                    return Text('No related research yet', style: t.bodyMuted);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.line)),
                    ),
                    child: Column(
                      children: [
                        for (final r in recs.take(3))
                          GestureDetector(
                            onTap: () => context.go('/thesis/${r.thesis.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: t.line),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.thesis.title,
                                      style: t.manrope(
                                        11,
                                        FontWeight.w600,
                                        t.ink,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 17,
                                    color: t.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                error: (_, _) =>
                    Text('Unable to load related research', style: t.bodyMuted),
              ),
            ],
          ),
        );
      },
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final t = CScholarMobileTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(label, style: t.dmSans(9, FontWeight.w400, t.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: t.dmSans(9, FontWeight.w600, t.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner Hero TARGET: the coloured slab the card banner flies into.
  ///
  /// Static by construction — it sits outside the stagger, so no fade can
  /// double the flight. The shuttle carries the slab colour only, never the
  /// pill text: flying a text block produces smeared, illegible type
  /// mid-flight. The match badge deliberately gets no hero (a second flying
  /// pill would read as a competing motion).
  Widget _heroBanner(Thesis thesis) {
    final gradient = ThesisCard.gradientFor(thesis.id);
    final icon = ThesisCard.iconFor(thesis.id);
    return Hero(
      tag: thesisBannerTag(thesis.id),
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) =>
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
      child: Container(
        width: double.infinity,
        height: 148,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(
                icon,
                size: 120,
                color: CScholarMaterial.shadowLight.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 18,
              child: Icon(
                icon,
                size: 34,
                color: CScholarMaterial.shadowLight.withValues(alpha: 0.92),
              ),
            ),
            Positioned(
              left: 32,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CScholarMaterial.shadowLight,
                  borderRadius: BorderRadius.circular(CScholarRadius.sm),
                ),
                child: Text(
                  thesis.researchType.toUpperCase(),
                  style: CScholarTextStyles.body(
                    10,
                    FontWeight.w700,
                    CScholarMaterial.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataAndActions(
    BuildContext context,
    WidgetRef ref, {
    required Thesis thesis,
    required bool isSaved,
    required bool showSave,
    required String authorsStr,
    required String programStr,
    required String yearStr,
    required String adviserStr,
  }) {
    // Staff see the full approval trail; everyone else who can open the
    // record only learns that it was approved.
    final role = ref.watch(currentUserProvider)?.role;
    final isStaff = role == 'admin' || role == 'faculty';

    // Every return note, newest first. On a current draft the newest note is
    // already in the banner below, so it is not repeated in the history.
    final noteHistory = (thesis.reviews ?? [])
        .where((r) => (r.notes ?? '').trim().isNotEmpty)
        .toList();
    final isReturnedDraft =
        thesis.status == 'draft' &&
        (thesis.reviewNotes ?? '').trim().isNotEmpty;
    final earlierNotes = isReturnedDraft && noteHistory.isNotEmpty
        ? noteHistory.sublist(1)
        : noteHistory;

    // Only fields that exist in the database record are rendered.
    final metaItems = <Widget>[
      if (authorsStr.isNotEmpty)
        _metaItem(Icons.people_outline, 'AUTHORS', authorsStr),
      if (programStr.isNotEmpty)
        _metaItem(Icons.school_outlined, 'PROGRAM', programStr),
      if (yearStr.isNotEmpty)
        _metaItem(Icons.calendar_today_outlined, 'ACADEMIC YEAR', yearStr),
      if (adviserStr.isNotEmpty)
        _metaItem(Icons.person_outline, 'ADVISER', adviserStr),
      if (thesis.categoriesString.isNotEmpty)
        _metaItem(Icons.category_outlined, 'CATEGORY', thesis.categoriesString),
      if (thesis.researchType.isNotEmpty)
        _metaItem(Icons.science_outlined, 'RESEARCH TYPE', thesis.researchType),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category / Type Badge + lifecycle state. The status chip is not
        // decoration: `approved` is internal, so whoever can open this record
        // needs to see what it currently is.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (thesis.researchType.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CScholarColors.primaryGreenVeryLight,
                  borderRadius: BorderRadius.circular(CScholarRadius.sm),
                  border: Border.all(
                    color: CScholarColors.primaryGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  thesis.researchType.toUpperCase(),
                  style: CScholarTextStyles.body(
                    11,
                    FontWeight.w700,
                    CScholarColors.primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ThesisStatusChip(thesis.status),
            if (thesis.approvedAt != null)
              Text(
                _approvalLine(thesis, isStaff: isStaff),
                style: CScholarTextStyles.body(
                  11.5,
                  FontWeight.w500,
                  CScholarColors.textMuted,
                ),
              ),
          ],
        ),

        // A returned study must say why, otherwise the revert is silent.
        if (isReturnedDraft) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CScholarColors.errorLight,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
              border: Border.all(
                color: CScholarColors.warningFg.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 18,
                  color: CScholarColors.warningFg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RETURNED FOR REVISION',
                        style: CScholarTextStyles.body(
                          11,
                          FontWeight.w700,
                          CScholarColors.warningFg,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thesis.reviewNotes!.trim(),
                        style: CScholarTextStyles.body(
                          13,
                          FontWeight.w400,
                          CScholarColors.warningFg,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Older return notes stay readable after a re-approval, so the reason
        // for a past return is never lost.
        if (earlierNotes.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'REVIEW HISTORY',
            style: CScholarTextStyles.body(
              11,
              FontWeight.w700,
              CScholarColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final review in earlierNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: CScholarColors.warningFg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatDate(review.createdAt)} · '
                          '${review.reviewerName ?? 'an administrator'}',
                          style: CScholarTextStyles.body(
                            11,
                            FontWeight.w600,
                            CScholarColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.notes!.trim(),
                          style: CScholarTextStyles.body(
                            12.5,
                            FontWeight.w400,
                            CScholarColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 14),

        // Title rises just behind the card (+60): close enough to read as
        // one arrival, late enough to read after it. The title is also the
        // Hero source's target — it flies here from the card while rising,
        // which reads as landing rather than doubling (unlike a fading slab).
        Stagger(
          index: 1,
          step: MotionPitch.page.step,
          max: MotionPitch.page.max,
          rise: MotionPitch.page.rise,
          child: Hero(
            tag: thesisTitleTag(thesis.id),
            child: Text(
              thesis.title,
              style: CScholarTextStyles.heading(
                26,
                FontWeight.w800,
                CScholarColors.textPrimary,
                height: 1.25,
              ),
            ),
          ),
        ),

        if (metaItems.isNotEmpty) ...[
          const SizedBox(height: 20),

          // Content-sized metadata rows. A fixed GridView aspect ratio made
          // these rows disproportionately tall on wide displays.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: CScholarColors.borderLight),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                final itemWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 2;

                return Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  // Metadata rows step on the tight rhythm with the same
                  // fade + rise as every other block — one entrance
                  // language for the whole page.
                  children: metaItems
                      .asMap()
                      .entries
                      .map(
                        (entry) => SizedBox(
                          width: itemWidth,
                          child: Stagger(
                            index: entry.key,
                            step: MotionPitch.tight.step,
                            max: MotionPitch.tight.max,
                            rise: MotionPitch.tight.rise,
                            child: entry.value,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons: View PDF, Save, Share
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            NeumorphButton(
              onPressed: thesis.pdfUrl == null
                  ? null
                  : () {
                      final pdfUrl =
                          '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}/pdf';
                      _openPdfInNewTab(context, ref, pdfUrl);
                    },
              icon: Icons.remove_red_eye_outlined,
              label: thesis.pdfUrl == null ? 'No PDF' : 'View PDF',
            ),
            // The save control is a TactileToggle: sinks on press, springs
            // on release, one-shot gold ring on save. The tooltip keeps the
            // affordance hint the old 'Save' label carried.
            if (showSave)
              Tooltip(
                message: isSaved ? 'Saved — tap to remove' : 'Save study',
                // The toggle carries its own semantic label.
                excludeFromSemantics: true,
                // Seat the glyph on the same clay circle as its neighbours,
                // so the action row reads as three controls, not a stray icon.
                child: Container(
                  // tile-exempt: circular seat for the tactile save toggle.
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CScholarMaterial.clay,
                    shape: BoxShape.circle,
                    border: Border.all(color: CScholarMaterial.rim),
                  ),
                  child: TactileToggle(
                    selected: isSaved,
                    onChanged: () => ref
                        .read(savedThesisIdsProvider.notifier)
                        .toggle(thesis.id),
                    icon: Icons.bookmark_outline,
                    selectedIcon: Icons.bookmark,
                    semanticLabel: isSaved ? 'Saved' : 'Save study',
                  ),
                ),
              ),
            NeumorphButton(
              onPressed: () async {
                final link = '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}';
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study share link copied to clipboard!'),
                    ),
                  );
                }
              },
              gel: false,
              icon: Icons.share_outlined,
              label: 'Share',
            ),
            NeumorphButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _citation(thesis)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('APA citation copied to clipboard!'),
                    ),
                  );
                }
              },
              gel: false,
              icon: Icons.format_quote_outlined,
              label: 'Cite',
            ),
          ],
        ),
        // Semantic match meter, when the entry point computed one: the bar
        // fills and the number counts up together over the page budget, so
        // neither can land before the other and read as a bug. Absent on
        // direct loads and keyword entries — no score, no meter.
        if (similarity != null) ...[
          const SizedBox(height: 24),
          Text(
            'SEMANTIC MATCH',
            style: CScholarTextStyles.body(
              12,
              FontWeight.w700,
              CScholarColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          EntranceReveal(
            delay: const Duration(milliseconds: 140),
            rise: 0,
            child: ScoreMeter(score: similarity!),
          ),
        ],
      ],
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime at) =>
      '${_months[at.month - 1]} ${at.day}, ${at.year}';

  /// "Approved by X on date" for staff, "Approved on date" for everyone else.
  String _approvalLine(Thesis thesis, {required bool isStaff}) {
    final at = thesis.approvedAt;
    if (at == null) return '';
    final date = _formatDate(at);
    if (!isStaff) return 'Approved on $date';
    final by = (thesis.approvedByName ?? '').trim();
    return 'Approved by ${by.isEmpty ? 'an administrator' : by} on $date';
  }

  Widget _metaItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: CScholarColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CScholarTextStyles.body(
                  10,
                  FontWeight.w700,
                  CScholarColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  12.5,
                  FontWeight.w600,
                  CScholarColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keywordChip(String term) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreenVeryLight,
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(
          color: CScholarColors.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        term,
        style: CScholarTextStyles.body(
          12,
          FontWeight.w500,
          CScholarColors.primaryGreen,
        ),
      ),
    );
  }

  /// APA-style citation for the repository (Phase 2 addition).
  /// "Last, F., & Last2, F. (Year). Title. Program, CSU CEIT Repository."
  String _citation(Thesis thesis) {
    final authors = thesis.authors ?? [];
    String names;
    if (authors.isEmpty) {
      names = thesis.authorsString.isNotEmpty
          ? thesis.authorsString
          : 'Anonymous';
    } else {
      final parts = authors.map((a) {
        final initial = a.firstName.isNotEmpty ? '${a.firstName[0]}.' : '';
        return '${a.lastName}, $initial'.trim();
      }).toList();
      if (parts.length == 1) {
        names = parts.first;
      } else if (parts.length == 2) {
        names = '${parts[0]}, & ${parts[1]}';
      } else {
        names =
            '${parts.sublist(0, parts.length - 1).join(', ')}, & ${parts.last}';
      }
    }
    final year = thesis.academicYear?.endYear ?? thesis.createdAt.year;
    final program = thesis.program?.name ?? 'CEIT';
    return '$names ($year). ${thesis.title}. $program, Caraga State University Repository.';
  }

  /// Stored abstracts often contain hard line-breaks (PDF extraction /
  /// manual wraps). A lone `\n` renders as an early break, so justified
  /// text looks like a narrow column with a big empty right side.
  /// Collapse single newlines to spaces, keep real paragraph breaks.
  String _displayAbstract(String raw) {
    return raw
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  void _openPdf(BuildContext context, WidgetRef ref, {required int thesisId}) {
    final pdfUrl = '${AppConfig.apiBaseUrl}/api/theses/$thesisId/pdf';
    _openPdfInNewTab(context, ref, pdfUrl);
  }

  void _openPdfInNewTab(BuildContext context, WidgetRef ref, String url) async {
    // Browsers can't set Authorization headers, so the token travels as
    // ?token= (backend validates it exactly like the Bearer header).
    final token = ref.read(apiServiceProvider).token;
    final base = Uri.parse(url);
    final uri = token == null
        ? base
        : base.replace(queryParameters: {'token': token});
    // Cross-platform open (web: new tab; desktop/mobile: browser/PDF viewer).
    // Falls back to copying the link if nothing can handle it.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF link copied — paste it in your browser to view.',
            ),
          ),
        );
      }
    }
  }
}

/// Flat mobile action pill: one solid fill, full radius, no gel surface.
///
/// The web pill is a gel object with a gradient and a gloss highlight. On
/// mobile the same treatment read as a glossy chip rather than a button, so
/// these stay flat coloured and keep the press sink for feedback.
class _MobileActionPill extends StatelessWidget {
  const _MobileActionPill({
    required this.icon,
    required this.label,
    required this.fill,
    required this.ink,
    required this.onTap,
    this.border,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color ink;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return PressableSurface(
      onTap: onTap,
      radius: CScholarRadius.full,
      // Small sink: a wide pill that scaled much would read as a card.
      sink: 1.5,
      scale: 0.99,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(CScholarRadius.full),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: ink),
            const SizedBox(width: 7),
            Text(label, style: t.dmSans(12, FontWeight.w800, ink)),
          ],
        ),
      ),
    );
  }
}
