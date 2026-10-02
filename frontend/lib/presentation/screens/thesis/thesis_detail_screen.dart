import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/loading_skeleton.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class ThesisDetailScreen extends ConsumerWidget {
  final int thesisId;
  const ThesisDetailScreen({super.key, required this.thesisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thesisAsync = ref.watch(thesisDetailProvider(thesisId));
    final recommendedAsync = ref.watch(recommendedThesesProvider(thesisId));
    final savedIds = ref.watch(savedThesisIdsProvider);
    final isSaved = savedIds.contains(thesisId);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
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
                  const Icon(Icons.error_outline, size: 48, color: CScholarColors.textHint),
                  const SizedBox(height: 16),
                  Text('Thesis not found', style: CScholarTextStyles.poppins(18, FontWeight.w600, CScholarColors.textPrimary)),
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
          final adviserStr = thesis.advisers != null && thesis.advisers!.isNotEmpty
              ? thesis.advisers!.first.fullName
              : '';

          return SingleChildScrollView(
            // Header-first on the page rhythm: breadcrumbs at 0, the card
            // settling right behind. Inner blocks below cascade on their own
            // rhythms — the banner stays static on purpose (Phase 7 flies it
            // as a Hero, and a hero that fades while flying is doubled).
            child: StaggerColumn(
              pitch: MotionPitch.page,
              children: [
                // 1. Breadcrumbs Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: const BoxDecoration(
                    color: CScholarMaterial.clay,
                    border: Border(bottom: BorderSide(color: CScholarMaterial.rim)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go(homeRoute),
                        child: Row(
                          children: [
                            const Icon(Icons.home_outlined, size: 16, color: CScholarColors.textMuted),
                            const SizedBox(width: 4),
                            Text('Home', style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.textMuted)),
                          ],
                        ),
                      ),
                      Text('  /  ', style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textHint)),
                      InkWell(
                        onTap: () => context.go(listRoute),
                        child: Text(listLabel, style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.primaryGreen)),
                      ),
                      Text('  /  ', style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textHint)),
                      Expanded(
                        child: Text(
                          thesis.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary),
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
                        borderRadius: BorderRadius.circular(CScholarRadius.xxl),
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
                          const Divider(color: CScholarColors.borderLight),
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
                                    style: CScholarTextStyles.inter(
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
                                          _displayAbstract(
                                              thesis.abstract),
                                          textAlign: TextAlign.justify,
                                          style: CScholarTextStyles.inter(
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
                          if (thesis.keywords != null && thesis.keywords!.isNotEmpty) ...[
                            if (thesis.abstract.isNotEmpty) const SizedBox(height: 28),
                            Text(
                              'KEYWORDS',
                              style: CScholarTextStyles.inter(
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
                          const Divider(color: CScholarColors.borderLight),
                          const SizedBox(height: 24),

                          // Recommended Studies Section ("Because you viewed this study")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended Studies',
                                style: CScholarTextStyles.poppins(18, FontWeight.w700, CScholarColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Because you viewed this study',
                                style: CScholarTextStyles.inter(12.5, FontWeight.w400, CScholarColors.textMuted),
                              ),
                              const SizedBox(height: 18),
                              asyncSlot(
                                recommendedAsync,
                                skeleton: const SkeletonList(
                                    count: 3, cardHeight: 56),
                                data: (recs) {
                                  if (recs.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Text(
                                          'No recommendations yet',
                                          style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                                        ),
                                      ),
                                    );
                                  }
                                  final displayList = recs.map((r) => {
                                    'title': r.thesis.title,
                                    'sim': '${(r.similarity * 100).round()}% similar',
                                    'id': r.thesis.id,
                                  }).toList();

                                  return Column(
                                    // Related studies step on the result
                                    // pitch: the same walk as every thesis
                                    // result list in the app.
                                    children: displayList
                                        .asMap()
                                        .entries
                                        .map((entry) {
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
                                              bottom: 10),
                                          child: InkWell(
                                          borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                          onTap: () => context.go('/thesis/$targetId'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: CScholarMaterial.clayDeep,
                                              borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                            ),
                                            child: Row(
                                              children: [
                                                ClayIconTile(
                                                  icon: Icons.article_outlined,
                                                  size: 36,
                                                  gel: false,
                                                  background: CScholarColors.primaryGreenLight,
                                                  tint: CScholarColors.primaryGreen,
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: CScholarTextStyles.inter(13.5, FontWeight.w600, CScholarColors.textPrimary),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: CScholarColors.primaryGreenVeryLight,
                                                    borderRadius: BorderRadius.circular(CScholarRadius.full),
                                                  ),
                                                  child: Text(
                                                    sim,
                                                    style: CScholarTextStyles.inter(11.5, FontWeight.w700, CScholarColors.primaryGreen),
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
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Text(
                                      'Unable to load recommendations: $err',
                                      style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
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
          );
        },
        error: (err, _) => Center(child: Text('Error: $err')),
      );

    if (isStudent) {
      return StudentLayout(
        currentIndex: 1,
        child: content,
      );
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
            icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
            onPressed: () => context.go(listRoute),
          ),
          title: const Text('Thesis Details',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
    // Only fields that exist in the database record are rendered.
    final metaItems = <Widget>[
      if (authorsStr.isNotEmpty) _metaItem(Icons.people_outline, 'AUTHORS', authorsStr),
      if (programStr.isNotEmpty) _metaItem(Icons.school_outlined, 'PROGRAM', programStr),
      if (yearStr.isNotEmpty) _metaItem(Icons.calendar_today_outlined, 'ACADEMIC YEAR', yearStr),
      if (adviserStr.isNotEmpty) _metaItem(Icons.person_outline, 'ADVISER', adviserStr),
      if (thesis.categoriesString.isNotEmpty)
        _metaItem(Icons.category_outlined, 'CATEGORY', thesis.categoriesString),
      if (thesis.researchType.isNotEmpty)
        _metaItem(Icons.science_outlined, 'RESEARCH TYPE', thesis.researchType),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category / Type Badge
        if (thesis.researchType.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CScholarColors.primaryGreenVeryLight,
              borderRadius: BorderRadius.circular(CScholarRadius.sm),
              border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.25)),
            ),
            child: Text(
              thesis.researchType.toUpperCase(),
              style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.primaryGreen, letterSpacing: 0.5),
            ),
          ),

        const SizedBox(height: 14),

        // Title rises just behind the card (+60): close enough to read as
        // one arrival, late enough to read after it.
        Stagger(
          index: 1,
          step: MotionPitch.page.step,
          max: MotionPitch.page.max,
          rise: MotionPitch.page.rise,
          child: Text(
            thesis.title,
            style: CScholarTextStyles.poppins(
              26,
              FontWeight.w800,
              CScholarColors.textPrimary,
              height: 1.25,
            ),
          ),
        ),

        if (metaItems.isNotEmpty) ...[
          const SizedBox(height: 20),

          // Content-sized metadata rows. A fixed GridView aspect ratio made
          // these rows disproportionately tall on wide displays.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: CScholarColors.borderLight)),
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
                  // Metadata rows step on the tight rhythm with a gentle
                  // horizontal entry — staggering a dense block vertically
                  // would make it unreadable.
                  children: metaItems
                      .asMap()
                      .entries
                      .map((entry) => SizedBox(
                            width: itemWidth,
                            child: Stagger(
                              index: entry.key,
                              step: MotionPitch.tight.step,
                              max: MotionPitch.tight.max,
                              rise: MotionPitch.tight.rise,
                              origin: const Offset(0.02, 0),
                              child: entry.value,
                            ),
                          ))
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
          children: [
            NeumorphButton(
              onPressed: thesis.pdfUrl == null
                  ? null
                  : () {
                      final pdfUrl = '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}/pdf';
                      _openPdfInNewTab(context, ref, pdfUrl);
                    },
              icon: Icons.remove_red_eye_outlined,
              label: thesis.pdfUrl == null ? 'No PDF' : 'View PDF',
            ),
            if (showSave)
              NeumorphButton(
                onPressed: () => ref.read(savedThesisIdsProvider.notifier).toggle(thesis.id),
                gel: isSaved,
                icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                label: isSaved ? 'Saved' : 'Save',
              ),
            NeumorphButton(
              onPressed: () async {
                final link = '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}';
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study share link copied to clipboard!')),
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
                    const SnackBar(content: Text('APA citation copied to clipboard!')),
                  );
                }
              },
              gel: false,
              icon: Icons.format_quote_outlined,
              label: 'Cite',
            ),
          ],
        ),
      ],
    );
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
              Text(label, style: CScholarTextStyles.inter(10, FontWeight.w700, CScholarColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary)),
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
        border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Text(
        term,
        style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.primaryGreen),
      ),
    );
  }

  /// APA-style citation for the repository (Phase 2 addition).
  /// "Last, F., & Last2, F. (Year). Title. Program, CSU CEIT Repository."
  String _citation(Thesis thesis) {
    final authors = thesis.authors ?? [];
    String names;
    if (authors.isEmpty) {
      names = thesis.authorsString.isNotEmpty ? thesis.authorsString : 'Anonymous';
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
        names = '${parts.sublist(0, parts.length - 1).join(', ')}, & ${parts.last}';
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
          const SnackBar(content: Text('PDF link copied — paste it in your browser to view.')),
        );
      }
    }
  }
}
