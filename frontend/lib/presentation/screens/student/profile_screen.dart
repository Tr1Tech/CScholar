import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedTheses = ref.watch(savedThesesProvider);
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
                          Expanded(flex: 4, child: _rightColumn(context, savedTheses)),
                        ],
                      )
                    : Column(
                        children: [
                          _leftColumn(user),
                          const SizedBox(height: 24),
                          _rightColumn(context, savedTheses),
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
                    // Avatar
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFD1FAE5),
                      child: Text(
                        _initials(user?.username ?? ''),
                        style: CScholarTextStyles.poppins(
                          28,
                          FontWeight.w800,
                          const Color(0xFF065F46),
                        ),
                      ),
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
                                user?.username ?? '',
                                style: CScholarTextStyles.poppins(20, FontWeight.w700, CScholarColors.textPrimary),
                              ),
                              if ((user?.role ?? '').isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CScholarColors.primaryGreenVeryLight,
                                    borderRadius: BorderRadius.circular(CScholarRadius.full),
                                    border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    _roleLabel(user?.role),
                                    style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.primaryGreen),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textSecondary),
                          ),
                          if (user != null) ...[
                            const SizedBox(height: 16),
                            // Account metadata coming from the database
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoPill(
                                  Icons.event_outlined,
                                  'Member since ${_formatDate(user.createdAt)}',
                                  const Color(0xFFF1F5F9),
                                  CScholarColors.textSecondary,
                                ),
                                _infoPill(
                                  Icons.verified_user_outlined,
                                  user.isActive ? 'Account active' : 'Account inactive',
                                  CScholarColors.primaryGreenVeryLight,
                                  const Color(0xFF065F46),
                                ),
                              ],
                            ),
                          ],
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
                'Account Information',
                style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
              ),
              const SizedBox(height: 16),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Username', user?.username ?? '', hasDot: true),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Role', _roleLabel(user?.role)),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Email', user?.email ?? ''),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Status', user == null ? '' : (user.isActive ? 'Active' : 'Inactive')),
              const Divider(color: CScholarColors.borderLight, height: 1),
              _academicRow('Member Since', user == null ? '' : _formatDate(user.createdAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context, AsyncValue<List<Thesis>> savedTheses) {
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
          child: _savedStudiesList(savedTheses, context),
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
              const Text(
                'No recent searches',
                style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _savedStudiesList(AsyncValue<List<Thesis>> savedTheses, BuildContext context) {
    final saved = savedTheses.value ?? const <Thesis>[];
    return Column(
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
              '${saved.length} saved',
              style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (savedTheses.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (savedTheses.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Unable to load saved studies: ${savedTheses.error}',
              style: const TextStyle(color: CScholarColors.error, fontSize: 13),
            ),
          )
        else if (saved.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No saved studies',
              style: TextStyle(color: CScholarColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...saved.take(3).map<Widget>((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _savedMiniItem(t.title, t.program?.code ?? '', () => context.go('/thesis/${t.id}')),
          )),
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

  /// Human readable label for the role stored in the database.
  String _roleLabel(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'faculty':
        return 'Faculty';
      case 'student':
        return 'Student Researcher';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
