// User Profile — Stitch design v2
// Uses shared StudentLayout (sidebar + topbar)

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

    return StudentLayout(
      currentIndex: 3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
            const SizedBox(height: 24),
            // Profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CScholarColors.dividerLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: CScholarColors.primaryGreen,
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: CScholarColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.username ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: CScholarColors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Student', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CScholarColors.primaryGreen)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CScholarColors.dividerLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.bookmark_outline, size: 28, color: CScholarColors.primaryGreen),
                        const SizedBox(height: 8),
                        Text('${savedIds.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                        const Text('Saved Studies', style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CScholarColors.dividerLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_outlined, size: 28, color: CScholarColors.info),
                        const SizedBox(height: 8),
                        const Text('47', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                        const Text('Searches', style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: CScholarColors.error,
                  side: const BorderSide(color: CScholarColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
