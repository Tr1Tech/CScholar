import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/change_password_dialog.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/cscholar_footer.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/clay_surface.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_scaffold.dart';
import 'package:frontend/presentation/widgets/student_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final savedTheses = ref.watch(savedThesesProvider);

    if (MobileStudentScaffold.useMobileShell(context)) {
      return StudentLayout(
        currentIndex: 3,
        heroAvatar: false,
        child: _mobileBody(context, ref, user, savedTheses),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > CScholarBreakpoints.wide;

    return StudentLayout(
      currentIndex: 3,
      // The card below owns the hero TARGET for the avatar, so the shell's pill
      // must not offer a second source under the same tag on this route.
      heroAvatar: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1140),
            // PART 7: the avatar is the Hero target (owned by the shell opt-out
            // above), everything else cascades on the page rhythm.
            child: StaggerColumn(
              pitch: MotionPitch.page,
              children: [
                // Account details are provisioned by an admin; there is no
                // self-service update endpoint, so the header carries no edit
                // action rather than a button that only shows a snackbar.
                const PageHeader(
                  title: 'Profile',
                  subtitle:
                      'Review your account details and repository activity',
                ),

                const SizedBox(height: 28),

                // Main Layout Grid
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _leftColumn(context, user),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: _rightColumn(context, ref, savedTheses),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _leftColumn(context, user),
                          const SizedBox(height: 24),
                          _rightColumn(context, ref, savedTheses),
                        ],
                      ),
                const CScholarFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Profile (`cscholar-mobile-ui/src/App.tsx:905-953`): hero and
  /// stats. Account details are read-only, so there is no menu list of
  /// editing actions to render.
  Widget _mobileBody(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<Thesis>> savedTheses,
  ) {
    final t = CScholarMobileTheme.of(context);
    final saved = savedTheses.value ?? const <Thesis>[];
    String initials = 'AS';
    final name = (user?.username ?? '').toString().trim();
    if (name.isNotEmpty) {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        initials = parts.first
            .substring(0, parts.first.length >= 2 ? 2 : 1)
            .toUpperCase();
      } else {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 106),
      child: StaggerColumn(
        pitch: MotionPitch.page,
        // Stretch every block to the page width. Without this the identity
        // block shrink-wraps to the widest line and hugs the left edge while
        // the stats and menu rows below span the full column.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Hero(
                tag: userAvatarHeroTag,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: CScholarMobileColors.green,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: CScholarMaterial.gelDrop(depth: 0.9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: t.manrope(20, FontWeight.w800, CScholarColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                name.isEmpty ? 'Alex Santos' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.manrope(21, FontWeight.w700, t.ink),
              ),
              const SizedBox(height: 3),
              Text(
                (user?.email ?? '').toString().isEmpty
                    ? 'BS Computer Science · 4th year'
                    : (user?.email ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.dmSans(10, FontWeight.w400, t.muted),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: t.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Student',
                  style: t.dmSans(
                    8,
                    FontWeight.w800,
                    t.green,
                    height: 1.2,
                    letterSpacing: 0.64,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _profileStat(context, '${saved.length}', 'Saved'),
                ),
                _profileDivider(context),
                Expanded(child: _profileStat(context, '12', 'Viewed')),
                _profileDivider(context),
                Expanded(child: _profileStat(context, '3', 'Topics')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _mobileSecurityCard(context),
          const SizedBox(height: 10),
          _mobileLogoutCard(context, ref),
        ],
      ),
    );
  }

  /// The mobile profile has no settings tab, so the password action sits at the
  /// bottom of the identity column, matching the menu-row shape of the shell.
  Widget _mobileSecurityCard(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => showChangePasswordDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_reset_outlined, size: 20, color: t.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Change password',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.dmSans(12, FontWeight.w700, t.ink),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile has no sidebar, so the Profile tab owns sign-out.
  Widget _mobileLogoutCard(BuildContext context, WidgetRef ref) {
    final t = CScholarMobileTheme.of(context);
    final ink = t.dangerInk;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log out',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.dmSans(12, FontWeight.w700, ink),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileStat(BuildContext context, String value, String label) {
    final t = CScholarMobileTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.manrope(15, FontWeight.w700, t.ink),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.dmSans(9, FontWeight.w400, t.muted),
          ),
        ],
      ),
    );
  }

  Widget _profileDivider(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return Container(width: 1, height: 40, color: t.line);
  }

  Widget _leftColumn(BuildContext context, dynamic user) {
    return Column(
      children: [
        // 1. User Identity Profile Card
        ClaySurface(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CScholarRadius.softCard),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar — the target of the shell avatar's hero, so the
                      // identity appears to travel from the top bar into the
                      // card when the profile opens. Mobile treatment: green
                      // rounded square with white initials.
                      Hero(
                        tag: userAvatarHeroTag,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: CScholarColors.primaryGreen,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: CScholarMaterial.gelDrop(depth: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initialsOf(user?.username ?? ''),
                            style: CScholarTextStyles.heading(
                              26,
                              FontWeight.w800,
                              CScholarColors.white,
                            ),
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
                                // The role chip is a non-flex sibling, so the
                                // name must be allowed to ellipsize; otherwise
                                // a long name at 200% text overflows the row.
                                Flexible(
                                  child: Text(
                                    user?.username ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CScholarTextStyles.heading(
                                      20,
                                      FontWeight.w700,
                                      CScholarColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if ((user?.role ?? '').isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          CScholarColors.primaryGreenVeryLight,
                                      borderRadius: BorderRadius.circular(
                                        CScholarRadius.full,
                                      ),
                                      border: Border.all(
                                        color: CScholarMaterial.rimPublished,
                                      ),
                                    ),
                                    child: Text(
                                      _roleLabel(user?.role),
                                      style: CScholarTextStyles.body(
                                        11,
                                        FontWeight.w700,
                                        CScholarColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: CScholarTextStyles.body(
                                13.5,
                                FontWeight.w400,
                                CScholarColors.textSecondary,
                              ),
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
                                    CScholarMaterial.clayDeep,
                                    CScholarColors.textSecondary,
                                  ),
                                  _infoPill(
                                    Icons.verified_user_outlined,
                                    user.isActive
                                        ? 'Account active'
                                        : 'Account inactive',
                                    CScholarColors.primaryGreenVeryLight,
                                    CScholarMaterial.textGreen,
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
        ),

        const SizedBox(height: 20),

        // 2. Academic & Department Details Card
        CScholarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Information',
                style: CScholarTextStyles.heading(
                  16,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: CScholarMaterial.rim, height: 1),
              _academicRow('Username', user?.username ?? '', hasDot: true),
              Divider(color: CScholarMaterial.rim, height: 1),
              _academicRow('Role', _roleLabel(user?.role)),
              Divider(color: CScholarMaterial.rim, height: 1),
              _academicRow('Email', user?.email ?? ''),
              Divider(color: CScholarMaterial.rim, height: 1),
              _academicRow(
                'Status',
                user == null ? '' : (user.isActive ? 'Active' : 'Inactive'),
              ),
              Divider(color: CScholarMaterial.rim, height: 1),
              _academicRow(
                'Member Since',
                user == null ? '' : _formatDate(user.createdAt),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Security — the one account action a student owns.
        CScholarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security',
                style: CScholarTextStyles.heading(
                  16,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Change the password used to sign in to this account.',
                style: CScholarTextStyles.body(
                  13,
                  FontWeight.w400,
                  CScholarColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: NeumorphButton(
                  onPressed: () => showChangePasswordDialog(context),
                  icon: Icons.lock_reset_outlined,
                  label: 'Change password',
                  expand: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Thesis>> savedTheses,
  ) {
    return Column(
      children: [
        // Saved Studies Widget
        CScholarCard(child: _savedStudiesList(savedTheses, context)),

        const SizedBox(height: 20),

        // Recent Search Activity
        _recentSearchesCard(context, ref),
      ],
    );
  }

  /// The queries the reader actually ran on this device. Live search records
  /// them after a short pause, so the card fills without anyone pressing Enter.
  Widget _recentSearchesCard(BuildContext context, WidgetRef ref) {
    final queries = ref.watch(recentSearchesProvider);
    return CScholarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Searches',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.heading(
                    15,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
              if (queries.isNotEmpty)
                GestureDetector(
                  onTap: () =>
                      ref.read(recentSearchesProvider.notifier).clear(),
                  child: Text(
                    'Clear',
                    style: CScholarTextStyles.body(
                      12,
                      FontWeight.w600,
                      CScholarColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (queries.isEmpty)
            const EmptyState(
              compact: true,
              icon: Icons.search,
              title: 'No recent searches',
              message: 'Your latest queries will appear here.',
            )
          else
            for (var i = 0; i < queries.length; i++) ...[
              _recentSearchRow(context, ref, queries[i]),
              if (i != queries.length - 1)
                Divider(color: CScholarMaterial.rim, height: 1),
            ],
        ],
      ),
    );
  }

  Widget _recentSearchRow(BuildContext context, WidgetRef ref, String query) {
    return InkWell(
      borderRadius: BorderRadius.circular(CScholarRadius.sm),
      onTap: () =>
          context.go('/repository?q=${Uri.encodeQueryComponent(query)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: CScholarColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  13,
                  FontWeight.w500,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Remove "$query"',
              child: GestureDetector(
                onTap: () =>
                    ref.read(recentSearchesProvider.notifier).remove(query),
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 15,
                    color: CScholarColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedStudiesList(
    AsyncValue<List<Thesis>> savedTheses,
    BuildContext context,
  ) {
    final saved = savedTheses.value ?? const <Thesis>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Saved Studies',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.heading(
                  15,
                  FontWeight.w700,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                '${saved.length} saved',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w500,
                  CScholarColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // One slot for loader / error / empty / rows: they cross-fade in place
        // instead of the panel snapping between three shapes. A refresh keeps
        // the rows — the loader is only shown when there is nothing to show.
        asyncSlot<List<Thesis>>(
          savedTheses,
          skeleton: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ClayLoader(height: 8),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Unable to load saved studies: $err',
              style: TextStyle(color: CScholarColors.error, fontSize: 13),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                compact: true,
                icon: Icons.bookmark_border,
                title: 'No saved studies',
                message: 'Bookmark a study to keep it here.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in list.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _savedMiniItem(
                      t.title,
                      t.program?.code ?? '',
                      () => context.go('/thesis/${t.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: NeumorphButton(
            onPressed: () => context.go('/saved'),
            label: 'View All Saved',
            gel: false,
            expand: true,
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
        // Every pill carries a rim: on a tinted canvas a borderless pill reads
        // as a colour smudge rather than a token (see common/status_chips.dart).
        border: Border.all(color: CScholarMaterial.rim),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          // The pill sits in a Wrap with no intrinsic cap of its own. Let the
          // label ellipsize instead of making the row wider than the card at
          // 200% text.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(12, FontWeight.w600, textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _academicRow(String label, String value, {bool hasDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Same rule as [PageHeader]: the label owns the remaining width and
          // the value is a plain trailing child. Two flexible children with the
          // default flex both took half the row, so the value only reached the
          // trailing edge as a side effect of `spaceBetween`. Cap the value at
          // two thirds so a long email at 200% text ellipsizes itself instead
          // of squeezing the label to nothing.
          final maxValueWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 2 / 3
              : double.infinity;
          return Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    12.5,
                    FontWeight.w500,
                    CScholarColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxValueWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDot) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: CScholarColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: CScholarTextStyles.body(
                          13,
                          FontWeight.w600,
                          CScholarColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
          color: CScholarMaterial.clayDeep,
          borderRadius: BorderRadius.circular(CScholarRadius.md),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CScholarColors.skyTint,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: CScholarTextStyles.body(
                  10,
                  FontWeight.w700,
                  CScholarColors.skyInk,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w600,
                  CScholarColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: CScholarColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  /// Human readable label for the role stored in the database.
  String _initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
