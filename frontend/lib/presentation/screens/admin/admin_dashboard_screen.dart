// Admin Dashboard — overview stats and quick actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';


class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    final screen = Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu, color: CScholarColors.textPrimary),
                onPressed: () {},
              ),
        title: const Text('CScholar Admin', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: CScholarColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Welcome back, Admin',
              style: TextStyle(fontSize: isWide ? 28 : 22, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage theses, users, and system settings for the CEIT repository.',
              style: TextStyle(fontSize: 15, color: CScholarColors.textSecondary),
            ),
            const SizedBox(height: 28),

            // Stat cards
            isWide
                ? Row(
                    children: [
                      Expanded(child: _statCard(Icons.library_books, '248', 'Total Theses', CScholarColors.primaryGreen)),
                      const SizedBox(width: 16),
                      Expanded(child: _statCard(Icons.pending, '12', 'Pending Review', CScholarColors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _statCard(Icons.people, '86', 'Researchers', CScholarColors.info)),
                      const SizedBox(width: 16),
                      Expanded(child: _statCard(Icons.search, '1.2K', 'Searches/mo', const Color(0xFF7B1FA2))),
                    ],
                  )
                : Column(
                    children: [
                      Row(children: [
                        Expanded(child: _statCard(Icons.library_books, '248', 'Total Theses', CScholarColors.primaryGreen)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(Icons.pending, '12', 'Pending Review', CScholarColors.orange)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _statCard(Icons.people, '86', 'Researchers', CScholarColors.info)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(Icons.search, '1.2K', 'Searches/mo', const Color(0xFF7B1FA2))),
                      ]),
                    ],
                  ),
            const SizedBox(height: 28),

            // Quick actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
            const SizedBox(height: 16),
            isWide
                ? Row(
                    children: [
                      Expanded(child: _actionCard(Icons.upload_file, 'Upload Thesis', 'Add a new study to the repository', CScholarColors.primaryGreen, () => context.go('/admin/thesis/new'))),
                      const SizedBox(width: 16),
                      Expanded(child: _actionCard(Icons.list_alt, 'Manage Theses', 'Edit, approve, or remove entries', CScholarColors.info, () => context.go('/admin/thesis/management'))),
                      const SizedBox(width: 16),
                      Expanded(child: _actionCard(Icons.analytics, 'Analytics', 'View search trends and top studies', CScholarColors.orange, () {})),
                      const SizedBox(width: 16),
                      Expanded(child: _actionCard(Icons.settings, 'Settings', 'System configuration', CScholarColors.textSecondary, () {})),
                    ],
                  )
                : Column(
                    children: [
                      Row(children: [
                        Expanded(child: _actionCard(Icons.upload_file, 'Upload', 'New study', CScholarColors.primaryGreen, () => context.go('/admin/thesis/new'))),
                        const SizedBox(width: 12),
                        Expanded(child: _actionCard(Icons.list_alt, 'Manage', 'Edit/approve', CScholarColors.info, () => context.go('/admin/thesis/management'))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _actionCard(Icons.search, 'Analytics', 'Trends', const Color(0xFF7B1FA2), () {})),
                        const SizedBox(width: 12),
                        Expanded(child: _actionCard(Icons.settings, 'Settings', 'Config', CScholarColors.textSecondary, () {})),
                      ]),
                    ],
                  ),
            const SizedBox(height: 28),

            // Recent theses table (desktop)
            if (isWide) ...[
              Container(
                padding: const EdgeInsets.all(24),
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
                        const Text('Recent Submissions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => context.go('/admin/thesis/management'),
                          child: const Text('View all', style: TextStyle(color: CScholarColors.primaryGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
                          ),
                          children: [
                            _tableHeader('Title'),
                            _tableHeader('Program'),
                            _tableHeader('Submitted'),
                            _tableHeader('Status'),
                            _tableHeader('Action'),
                          ],
                        ),
                        ...[
                          ['A IoT-Based Smart Irrigation System for Agricultural Fields', 'BSIT', 'Aug 28', 'Published', 'Active'],
                          ['Predictive Analytics for Student Performance Using Machine Learning', 'BSIT', 'Aug 25', 'Pending', 'Active'],
                          ['Blockchain-Based Supply Chain Tracking System', 'BSCS', 'Aug 22', 'Published', 'Active'],
                          ['Automated Fish Tank Monitoring with Mobile App', 'BSIT', 'Aug 19', 'Rejected', 'Inactive'],
                        ].map((row) => TableRow(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: CScholarColors.dividerLight.withValues(alpha: 0.5))),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(row[0], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(row[1], style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(row[2], style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: row[3] == 'Published'
                                      ? CScholarColors.success.withValues(alpha: 0.1)
                                      : row[3] == 'Pending'
                                          ? CScholarColors.orange.withValues(alpha: 0.1)
                                          : CScholarColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(row[3], style: TextStyle(fontSize: 12, color: row[3] == 'Published' ? CScholarColors.success : row[3] == 'Pending' ? CScholarColors.orange : CScholarColors.error, fontWeight: FontWeight.w500)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Edit', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Mobile: simple list
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
                    const Text('Recent Submissions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    ...[
                      ['Smart Irrigation System', 'BSIT', 'Published'],
                      ['Student Performance Analytics', 'BSIT', 'Pending'],
                      ['Supply Chain Blockchain', 'BSCS', 'Published'],
                    ].map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(row[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(row[1], style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: row[2] == 'Published'
                                  ? CScholarColors.success.withValues(alpha: 0.1)
                                  : CScholarColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(row[2], style: TextStyle(fontSize: 12, color: row[2] == 'Published' ? CScholarColors.success : CScholarColors.orange, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isWide) return screen;

    return Row(
      children: [
        const AdminSidebar(currentPath: '/admin/dashboard'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: screen),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: CScholarColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CScholarColors.textSecondary)),
    );
  }
}
