// Admin Dashboard — Stitch design v2
// Left sidebar + topbar + KPI cards + activity feed + quick actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context, ref, user, stats);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          // Left sidebar
          const AdminSidebar(currentPath: '/admin/dashboard'),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _topBar(context, ref, user),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page title + actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Admin Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                                const SizedBox(height: 4),
                                const Text('Manage repository entries, user submissions, and access activity.', style: TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                              ],
                            ),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: () => context.go('/admin/thesis/new'),
                                  style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add New Thesis'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(foregroundColor: CScholarColors.textPrimary, side: BorderSide(color: CScholarColors.dividerLight)),
                                  icon: const Icon(Icons.download_outlined, size: 18),
                                  label: const Text('Export Report'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // KPI cards
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _kpiCard('${stats.value?['studies'] ?? '128'}', 'Studies', '+4 this week', Icons.menu_book_outlined, CScholarColors.primaryGreen),
                            _kpiCard('${stats.value?['authors'] ?? '246'}', 'Authors', '+12 this mo.', Icons.people_outline, CScholarColors.orange),
                            _kpiCard('${stats.value?['programs'] ?? '3'}', 'Programs', 'BSIT, BSCS, BSIS', Icons.account_balance_outlined, CScholarColors.gold),
                            _kpiCard('${stats.value?['searches'] ?? '1,284'}', 'Searches', '+18% high', Icons.search_outlined, CScholarColors.info),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Two-column: Activity + Quick Actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Activity (2/3)
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: CScholarColors.dividerLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: CScholarColors.primaryGreen.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text('Live audit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CScholarColors.primaryGreen)),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text('View full logs →', style: TextStyle(fontSize: 12, color: CScholarColors.primaryGreen)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _activityItem(Icons.add_circle_outline, CScholarColors.primaryGreen, 'New thesis added:', 'Campus Navigation and Room Locator', 'Author: Juan Dela Cruz • BS Information Technology', '2 hours ago'),
                                    const Divider(height: 24),
                                    _activityItem(Icons.person_add_outlined, CScholarColors.orange, 'User registered:', 'maria.santos@csu.edu.ph', 'Role: Student Researcher • Department of Computer Science', '4 hours ago'),
                                    const Divider(height: 24),
                                    _activityItem(Icons.edit_outlined, CScholarColors.info, 'Thesis updated:', 'AI-Based Attendance Monitoring', 'Metadata & abstract updated by adviser', '6 hours ago'),
                                    const Divider(height: 24),
                                    _activityItem(Icons.search_outlined, CScholarColors.facultyColor, 'New search:', '“machine learning”', 'Matched 14 published capstone records', '8 hours ago'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Quick Actions (1/3)
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: CScholarColors.dividerLight),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Quick Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                                        const SizedBox(height: 16),
                                        _quickAction(Icons.add_circle_outline, CScholarColors.primaryGreen, 'Add New Thesis', 'Upload PDF & register metadata', () => context.go('/admin/thesis/new')),
                                        const SizedBox(height: 8),
                                        _quickAction(Icons.people_outline, CScholarColors.orange, 'Manage Users', 'Review student approvals', () => context.go('/admin/users')),
                                        const SizedBox(height: 8),
                                        _quickAction(Icons.assessment_outlined, CScholarColors.gold, 'Export Reports', 'Download CSV/Excel data', () {}),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Repository status box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [CScholarColors.sidebarDeep, CScholarColors.adminSidebar],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('CEIT Archive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CScholarColors.gold, letterSpacing: 1)),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: CScholarColors.gold,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('CSU CEIT Repository is Online', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        const Text('All services operational. Automated weekly indexing completed.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, WidgetRef ref, User? user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search thesis, authors, or keywords...',
                  hintStyle: const TextStyle(color: CScholarColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20, color: CScholarColors.textHint),
                  filled: true,
                  fillColor: CScholarColors.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: CScholarColors.dividerLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: CScholarColors.dividerLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CScholarColors.primaryGreen)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Stack(
              children: const [
                Icon(Icons.notifications_outlined, size: 22, color: CScholarColors.textSecondary),
                Positioned(top: 2, right: 2, child: CircleAvatar(radius: 4, backgroundColor: CScholarColors.orange)),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: CScholarColors.primaryGreenVeryLight,
                child: Text(
                  (user?.username ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: CScholarColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(user?.username ?? 'Admin', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                  Text('Engr. Adviser', style: const TextStyle(fontSize: 11, color: CScholarColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String value, String label, String change, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
          Text(change, style: const TextStyle(fontSize: 11, color: CScholarColors.primaryGreen, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _activityItem(IconData icon, Color color, String action, String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary),
                  children: [
                    TextSpan(text: '$action '),
                    TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: CScholarColors.textHint)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 11, color: CScholarColors.textHint)),
      ],
    );
  }

  Widget _quickAction(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CScholarColors.dividerLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CScholarColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: CScholarColors.textHint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: CScholarColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref, User? user, AsyncValue<Map<String, int>> stats) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: const Text('Admin Dashboard', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _kpiCard('128', 'Studies', '+4 this week', Icons.menu_book_outlined, CScholarColors.primaryGreen),
                _kpiCard('246', 'Authors', '+12 this mo.', Icons.people_outline, CScholarColors.orange),
                _kpiCard('3', 'Programs', 'BSIT, BSCS, BSIS', Icons.account_balance_outlined, CScholarColors.gold),
                _kpiCard('1,284', 'Searches', '+18% high', Icons.search_outlined, CScholarColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
