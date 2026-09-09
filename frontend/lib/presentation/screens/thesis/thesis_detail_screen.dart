import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
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

          final authorsStr = thesis.authors != null && thesis.authors!.isNotEmpty
              ? thesis.authors!.map((a) => '${a.firstName} ${a.lastName}').join(', ')
              : 'Juan Dela Cruz, Maria Santos';
          final programStr = thesis.program?.name ?? 'BS Information Technology';
          final yearStr = thesis.academicYear?.label ?? '2024 - 2025';
          final adviserStr = thesis.advisers != null && thesis.advisers!.isNotEmpty
              ? thesis.advisers!.first.fullName
              : 'Engr. Roberto Garcia';

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
                          // Top Overview: Left Smartphone Mockup & Right Metadata
                          isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPhoneMockup(),
                                    const SizedBox(width: 40),
                                    Expanded(
                                      child: _buildMetadataAndActions(
                                        context,
                                        ref,
                                        thesis: thesis,
                                        isSaved: isSaved,
                                        authorsStr: authorsStr,
                                        programStr: programStr,
                                        yearStr: yearStr,
                                        adviserStr: adviserStr,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
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
                                    const SizedBox(height: 28),
                                    _buildPhoneMockup(),
                                  ],
                                ),

                          const SizedBox(height: 36),
                          const Divider(color: CScholarColors.borderLight),
                          const SizedBox(height: 24),

                          // Abstract Section
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
                          Text(
                            thesis.abstract.isNotEmpty
                                ? thesis.abstract
                                : 'This study presents a mobile application that helps students find classrooms and navigate within the campus using indoor positioning and interactive maps. The system utilizes GPS, Wi-Fi, and Bluetooth low-energy (BLE) beacons to provide accurate location tracking and real-time step-by-step navigation to various buildings, laboratories, and rooms across the university campus.',
                            textAlign: TextAlign.justify,
                            style: CScholarTextStyles.inter(
                              14.5,
                              FontWeight.w400,
                              const Color(0xFF334155),
                              height: 1.7,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Keywords Section
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
                            children: (thesis.keywords != null && thesis.keywords!.isNotEmpty)
                                ? thesis.keywords!
                                    .map((k) => _keywordChip(k.term))
                                    .toList()
                                : [
                                    _keywordChip('campus navigation'),
                                    _keywordChip('indoor positioning'),
                                    _keywordChip('mobile application'),
                                    _keywordChip('GPS'),
                                  ],
                          ),

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
                                  final displayList = recs.isNotEmpty
                                      ? recs.map((r) => {'title': r.title, 'sim': '78% similar', 'id': r.id}).toList()
                                      : <Map<String, dynamic>>[
                                          {'title': 'Indoor Positioning System for University Buildings', 'sim': '82% similar', 'id': 2},
                                          {'title': 'Student Location Assistance System', 'sim': '70% similar', 'id': 3},
                                          {'title': 'Campus Map and Directory Application', 'sim': '63% similar', 'id': 4},
                                        ];

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
                                error: (_, _) => const SizedBox.shrink(),
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

  Widget _buildPhoneMockup() {
    return Column(
      children: [
        Container(
          width: 250,
          height: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF1E293B), width: 7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Notch
              Container(
                height: 18,
                color: const Color(0xFF1E293B),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 50,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                ),
              ),
              // App Screen UI inside Phone Mockup
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Header inside phone
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: CScholarShadows.subtle,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.navigation, size: 14, color: CScholarColors.primaryGreen),
                            const SizedBox(width: 6),
                            Text('Campus Navigator', style: CScholarTextStyles.inter(10, FontWeight.bold, CScholarColors.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Map View Simulation
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Grid/Road lines
                              Positioned(
                                top: 40,
                                left: 0,
                                right: 0,
                                child: Container(height: 6, color: Colors.white),
                              ),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 60,
                                child: Container(width: 6, color: Colors.white),
                              ),
                              // User Pin ("You")
                              Positioned(
                                bottom: 30,
                                left: 24,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: CScholarColors.info,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                      child: Text('You', style: CScholarTextStyles.inter(7, FontWeight.bold, CScholarColors.textPrimary)),
                                    ),
                                  ],
                                ),
                              ),
                              // Destination Pin (Room 304)
                              Positioned(
                                top: 20,
                                right: 30,
                                child: Column(
                                  children: [
                                    const Icon(Icons.location_on, size: 22, color: Colors.red),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                      child: Text('Room 304', style: CScholarTextStyles.inter(7, FontWeight.bold, CScholarColors.textPrimary)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Navigation turn card inside phone
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: CScholarShadows.subtle,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Turn left at St. Joseph Hall', style: CScholarTextStyles.inter(8, FontWeight.w700, CScholarColors.textPrimary)),
                                Text('45m', style: CScholarTextStyles.inter(8, FontWeight.w800, CScholarColors.primaryGreen)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: 0.65,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: CScholarColors.primaryGreen,
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Home Indicator bar
              Container(
                height: 14,
                color: Colors.white,
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Interactive Mobile Interface Preview',
          style: CScholarTextStyles.inter(11, FontWeight.w500, CScholarColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildMetadataAndActions(
    BuildContext context,
    WidgetRef ref, {
    required dynamic thesis,
    required bool isSaved,
    required String authorsStr,
    required String programStr,
    required String yearStr,
    required String adviserStr,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category / Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CScholarColors.primaryGreenVeryLight,
            borderRadius: BorderRadius.circular(CScholarRadius.sm),
            border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.25)),
          ),
          child: Text(
            (thesis.researchType ?? 'Thesis').toString().toUpperCase(),
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

        const SizedBox(height: 20),

        // Metadata Grid (2 cols)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: CScholarColors.borderLight)),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            childAspectRatio: 3.2,
            children: [
              _metaItem(Icons.people_outline, 'AUTHORS', authorsStr),
              _metaItem(Icons.school_outlined, 'PROGRAM', programStr),
              _metaItem(Icons.calendar_today_outlined, 'ACADEMIC YEAR', yearStr),
              _metaItem(Icons.person_outline, 'ADVISER', adviserStr),
              _metaItem(Icons.category_outlined, 'CATEGORY', 'Mobile Application'),
              _metaItem(Icons.science_outlined, 'RESEARCH TYPE', 'Applied Research'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: View PDF, Save, Share
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening thesis manuscript PDF viewer...')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: CScholarColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
              ),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              label: Text('View PDF', style: CScholarTextStyles.inter(13.5, FontWeight.w600, Colors.white)),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Study share link copied to clipboard!')),
                );
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
}
