import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedIds = ref.watch(savedThesisIdsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return StudentLayout(
      currentIndex: 4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with "Edit Profile" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account details and review your repository activity',
                          style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile edit mode enabled.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CScholarColors.textPrimary,
                        side: const BorderSide(color: CScholarColors.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('Edit Profile', style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary)),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Main Layout Grid
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _leftColumn(user)),
                          const SizedBox(width: 24),
                          Expanded(flex: 4, child: _rightColumn(context, savedIds)),
                        ],
                      )
                    : Column(
                        children: [
                          _leftColumn(user),
                          const SizedBox(height: 24),
                          _rightColumn(context, savedIds),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leftColumn(dynamic user) {
    return Column(
      children: [
        // 1. User Identity Profile Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CScholarRadius.xxl),
            border: Border.all(color: CScholarColors.borderLight),
            boxShadow: CScholarShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Gradient Accent Bar at Top
              Container(
                height: 7,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CScholarColors.primaryGreen,
                      Color(0xFF34D399),
                      CScholarColors.gold,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with active checkmark
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFFD1FAE5),
                          child: Text(
                            _initials(user?.username ?? 'Juan Dela Cruz'),
                            style: CScholarTextStyles.poppins(
                              28,
                              FontWeight.w800,
                              const Color(0xFF065F46),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: CScholarColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(Icons.check, size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // General Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.username ?? 'Juan Dela Cruz',
                                style: CScholarTextStyles.poppins(20, FontWeight.w700, CScholarColors.textPrimary),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CScholarColors.primaryGreenVeryLight,
                                  borderRadius: BorderRadius.circular(CScholarRadius.full),
                                  border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'Enrolled',
                                  style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.primaryGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'juan.delacruz@csu.edu.ph',
                            style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          // Student Metadata Badge Pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoPill(Icons.badge_outlined, 'Student ID: 2021-00384', const Color(0xFFF1F5F9), CScholarColors.textSecondary),
                              _infoPill(Icons.account_balance_outlined, 'CEIT Department', CScholarColors.primaryGreenVeryLight, const Color(0xFF065F46)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Academic & Department Details Card
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CScholarRadius.xxl),
            border: Border.all(color: CScholarColors.borderLight),
            boxShadow: CScholarShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Information',
                style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
              ),
              const SizedBox(height: 16),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Program', 'BS Information Technology', hasDot: true),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Role', user?.role == 'admin' ? 'Administrator' : 'Student Researcher'),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('College', 'College of Engineering & Information Technology (CEIT)'),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Academic Standing', '4th Year (Senior Candidate)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context, Set<int> savedIds) {
    return Column(
      children: [
        // Saved Studies Widget
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CScholarRadius.xl),
            border: Border.all(color: CScholarColors.borderLight),
            boxShadow: CScholarShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Studies',
                    style: CScholarTextStyles.poppins(15, FontWeight.w700, CScholarColors.textPrimary),
                  ),
                  Text(
                    '${savedIds.isNotEmpty ? savedIds.length : 12} saved',
                    style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _savedMiniItem('Campus Navigation and Room Locator', 'BSIT', () => context.go('/thesis/1')),
              const SizedBox(height: 8),
              _savedMiniItem('Indoor Positioning System', 'BSCS', () => context.go('/thesis/2')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/saved'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CScholarColors.primaryGreen,
                    side: const BorderSide(color: CScholarColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('View All Saved', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Search Activity
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CScholarRadius.xl),
            border: Border.all(color: CScholarColors.borderLight),
            boxShadow: CScholarShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Searches',
                style: CScholarTextStyles.poppins(15, FontWeight.w700, CScholarColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _searchHistoryItem('campus navigation', '14 matches'),
              const SizedBox(height: 8),
              _searchHistoryItem('machine learning face detection', '8 matches'),
              const SizedBox(height: 8),
              _searchHistoryItem('IoT smart agriculture', '19 matches'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CScholarRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(text, style: CScholarTextStyles.inter(12, FontWeight.w600, textColor)),
        ],
      ),
    );
  }

  Widget _academicRow(String label, String value, {bool hasDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.textMuted)),
          Row(
            children: [
              if (hasDot) ...[
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: CScholarColors.primaryGreen, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(value, style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savedMiniItem(String title, String tag, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CScholarRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(CScholarRadius.md),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(tag, style: CScholarTextStyles.inter(10, FontWeight.w700, const Color(0xFF0284C7))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: CScholarColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _searchHistoryItem(String query, String resultCount) {
    return Row(
      children: [
        const Icon(Icons.history, size: 16, color: CScholarColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text('“$query”', style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textPrimary)),
        ),
        Text(resultCount, style: CScholarTextStyles.inter(11, FontWeight.w400, CScholarColors.textMuted)),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
