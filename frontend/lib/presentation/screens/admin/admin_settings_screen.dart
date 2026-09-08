// Admin: System Settings — site config, repository info, contact

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _siteNameCtrl = TextEditingController(text: 'CScholar');
  final _siteDescCtrl = TextEditingController(
    text: 'Semantic Search and AI-Powered Recommendation System for the CEIT Thesis and Capstone Repository',
  );
  final _contactEmailCtrl = TextEditingController(text: 'ceit@csu.edu.ph');
  final _contactNameCtrl = TextEditingController(text: 'CEIT Office');
  final _maxResultsCtrl = TextEditingController(text: '20');
  final _allowPublicSearchCtrl = TextEditingController(text: 'true');

  String _selectedTheme = 'Light';
  bool _semanticEnabled = true;
  bool _recommendationsEnabled = true;
  bool _autoArchive = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _siteNameCtrl.dispose();
    _siteDescCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactNameCtrl.dispose();
    _maxResultsCtrl.dispose();
    _allowPublicSearchCtrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: CScholarColors.success,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    Widget body() => Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
                onPressed: () => context.go('/admin/dashboard'),
              ),
        title: const Text('System Settings', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: CScholarColors.dividerLight, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _sectionCard(
              title: 'General',
              icon: Icons.settings,
              children: [
                _textField(label: 'Repository Name', hint: 'e.g., CScholar CEIT Repository', controller: _siteNameCtrl),
                const SizedBox(height: 16),
                _textField(label: 'Description', hint: 'Brief description of the repository', controller: _siteDescCtrl, maxLines: 3),
              ],
            ),
            const SizedBox(height: 20),

            // AI & Search Settings
            _sectionCard(
              title: 'AI & Search',
              icon: Icons.auto_awesome,
              children: [
                _toggleRow('Semantic Search', 'Enable AI-powered semantic search', _semanticEnabled, (v) => setState(() => _semanticEnabled = v)),
                const Divider(height: 24),
                _toggleRow('Recommendations', 'Show AI recommendations on thesis detail', _recommendationsEnabled, (v) => setState(() => _recommendationsEnabled = v)),
                const Divider(height: 24),
                _textField(label: 'Max Search Results', hint: 'e.g., 20', controller: _maxResultsCtrl),
              ],
            ),
            const SizedBox(height: 20),

            // Content Settings
            _sectionCard(
              title: 'Content & Access',
              icon: Icons.content_paste,
              children: [
                _toggleRow('Auto-Archive', 'Automatically archive theses older than 3 years', _autoArchive, (v) => setState(() => _autoArchive = v)),
                const Divider(height: 24),
                _toggleRow('Public Search', 'Allow non-logged-in users to search', _allowPublicSearchCtrl.text == 'true', (v) => setState(() => _allowPublicSearchCtrl.text = v.toString())),
              ],
            ),
            const SizedBox(height: 20),

            // Contact Info
            _sectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail,
              children: [
                _textField(label: 'Contact Name', hint: 'e.g., CEIT Office', controller: _contactNameCtrl),
                const SizedBox(height: 16),
                _textField(label: 'Contact Email', hint: 'e.g., ceit@csu.edu.ph', controller: _contactEmailCtrl),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: CScholarColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),

            // Version info
            Center(
              child: Text(
                'CScholar v1.0.0 — CEIT Thesis & Capstone Repository',
                style: TextStyle(fontSize: 12, color: CScholarColors.textSecondary.withValues(alpha: 0.6)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    if (!isWide) return body();

    return Row(
      children: [
        const AdminSidebar(currentPath: '/admin/settings'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: body()),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CScholarColors.dividerLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CScholarColors.backgroundLight,
              border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: CScholarColors.primaryGreen),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: CScholarColors.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.primaryGreen)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CScholarColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: CScholarColors.textSecondary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: CScholarColors.primaryGreen,
        ),
      ],
    );
  }
}
