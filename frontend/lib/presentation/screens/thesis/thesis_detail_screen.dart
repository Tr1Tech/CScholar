import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

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

    return StudentLayout(
      currentIndex: 1,
      child: thesisAsync.when(
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
                  FilledButton(
                    onPressed: () => context.go('/repository'),
                    child: const Text('Back to Repository'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Breadcrumbs Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: CScholarColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/student/dashboard'),
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
                        onTap: () => context.go('/repository'),
                        child: Text('Repository', style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.primaryGreen)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(CScholarRadius.xxl),
                        border: Border.all(color: CScholarColors.borderLight),
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
                            authorsStr: authorsStr,
                            programStr: programStr,
                            yearStr: yearStr,
                            adviserStr: adviserStr,
                          ),

                          const SizedBox(height: 36),
                          const Divider(color: CScholarColors.borderLight),
                          const SizedBox(height: 24),

                          // Abstract Section (only when the database has one)
                          if (thesis.abstract.isNotEmpty) ...[
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
                                    _displayAbstract(thesis.abstract),
                                    textAlign: TextAlign.justify,
                                    style: CScholarTextStyles.inter(
                                      14.5,
                                      FontWeight.w400,
                                      const Color(0xFF334155),
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

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
                              recommendedAsync.when(
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
                                    children: displayList.map((item) {
                                      final title = item['title'] as String;
                                      final sim = item['sim'] as String;
                                      final targetId = item['id'] as int;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                          onTap: () => context.go('/thesis/$targetId'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                              border: Border.all(color: CScholarColors.borderLight),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: CScholarColors.primaryGreenVeryLight,
                                                    borderRadius: BorderRadius.circular(CScholarRadius.md),
                                                  ),
                                                  child: const Icon(Icons.article_outlined, size: 18, color: CScholarColors.primaryGreen),
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
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
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
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMetadataAndActions(
    BuildContext context,
    WidgetRef ref, {
    required Thesis thesis,
    required bool isSaved,
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

        // Title
        Text(
          thesis.title,
          style: CScholarTextStyles.poppins(
            26,
            FontWeight.w800,
            CScholarColors.textPrimary,
            height: 1.25,
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
                  children: metaItems
                      .map((item) => SizedBox(width: itemWidth, child: item))
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
            FilledButton.icon(
              onPressed: thesis.pdfUrl == null
                  ? null
                  : () {
                      final pdfUrl = '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}/pdf';
                      _openPdfInNewTab(context, ref, pdfUrl);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: CScholarColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
              ),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              label: Text(
                thesis.pdfUrl == null ? 'No PDF' : 'View PDF',
                style: CScholarTextStyles.inter(13.5, FontWeight.w600, Colors.white),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => ref.read(savedThesisIdsProvider.notifier).toggle(thesis.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: isSaved ? CScholarColors.primaryGreen : CScholarColors.textPrimary,
                side: BorderSide(color: isSaved ? CScholarColors.primaryGreen : CScholarColors.borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
              ),
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline, size: 18),
              label: Text(isSaved ? 'Saved' : 'Save', style: CScholarTextStyles.inter(13.5, FontWeight.w600, isSaved ? CScholarColors.primaryGreen : CScholarColors.textPrimary)),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final link = '${AppConfig.apiBaseUrl}/api/theses/${thesis.id}';
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study share link copied to clipboard!')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: CScholarColors.textPrimary,
                side: const BorderSide(color: CScholarColors.borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text('Share', style: CScholarTextStyles.inter(13.5, FontWeight.w600, CScholarColors.textPrimary)),
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
