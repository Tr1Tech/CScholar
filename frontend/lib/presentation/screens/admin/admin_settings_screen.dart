// Admin: System Settings — Stitch design v2
// Sidebar + topbar + settings cards

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _siteNameCtrl = TextEditingController(text: 'CScholar');
  final _siteDescCtrl = TextEditingController(text: 'Semantic Search and AI-Powered Recommendation System for the CEIT Thesis and Capstone Repository');
  final _contactEmailCtrl = TextEditingController(text: 'ceit@csu.edu.ph');
  final _contactNameCtrl = TextEditingController(text: 'CEIT Office');
  final _maxResultsCtrl = TextEditingController(text: '20');

  bool _semanticEnabled = true;
  bool _recommendationsEnabled = true;
  bool _autoArchive = false;
  bool _publicSearch = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _siteNameCtrl.dispose();
    _siteDescCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactNameCtrl.dispose();
    _maxResultsCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Settings persist on this device (SharedPreferences) — the Save button
  /// is real: values survive restarts. There is no server settings store.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _siteNameCtrl.text = prefs.getString('settings_site_name') ?? _siteNameCtrl.text;
      _siteDescCtrl.text = prefs.getString('settings_site_desc') ?? _siteDescCtrl.text;
      _contactEmailCtrl.text = prefs.getString('settings_contact_email') ?? _contactEmailCtrl.text;
      _contactNameCtrl.text = prefs.getString('settings_contact_name') ?? _contactNameCtrl.text;
      _maxResultsCtrl.text = prefs.getString('settings_max_results') ?? _maxResultsCtrl.text;
      _semanticEnabled = prefs.getBool('settings_semantic') ?? true;
      _recommendationsEnabled = prefs.getBool('settings_recommendations') ?? true;
      _autoArchive = prefs.getBool('settings_auto_archive') ?? false;
      _publicSearch = prefs.getBool('settings_public_search') ?? true;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings_site_name', _siteNameCtrl.text.trim());
      await prefs.setString('settings_site_desc', _siteDescCtrl.text.trim());
      await prefs.setString('settings_contact_email', _contactEmailCtrl.text.trim());
      await prefs.setString('settings_contact_name', _contactNameCtrl.text.trim());
      await prefs.setString('settings_max_results', _maxResultsCtrl.text.trim());
      await prefs.setBool('settings_semantic', _semanticEnabled);
      await prefs.setBool('settings_recommendations', _recommendationsEnabled);
      await prefs.setBool('settings_auto_archive', _autoArchive);
      await prefs.setBool('settings_public_search', _publicSearch);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved on this device'), backgroundColor: CScholarColors.success));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context);
    }

    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/settings'),
      topbar: const AdminTopbar(),
      mobileTitle: 'System Settings',
      backRoute: '/admin/dashboard',
      maxWidth: 860,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'System Settings',
              subtitle: 'Stored on this device.',
              action: NeumorphButton(
                onPressed: _isSaving ? null : _save,
                label: 'Save Settings',
                loading: _isSaving,
              ),
            ),
            const SizedBox(height: 20),
                        // General settings
                        _sectionCard('General', Icons.settings, [
                          _textField('Repository Name', 'e.g., CScholar CEIT Repository', _siteNameCtrl),
                          const SizedBox(height: 16),
                          _textField('Description', 'Brief description of the repository', _siteDescCtrl, maxLines: 3),
                        ]),
                        const SizedBox(height: 20),
                        // AI & Search
                        _sectionCard('AI & Search', Icons.auto_awesome, [
                          _toggleRow('Semantic Search', 'Enable AI-powered semantic search', _semanticEnabled, (v) => setState(() => _semanticEnabled = v)),
                          const Divider(color: CScholarMaterial.rim, height: 24),
                          _toggleRow('Recommendations', 'Show AI recommendations on thesis detail', _recommendationsEnabled, (v) => setState(() => _recommendationsEnabled = v)),
                          const Divider(color: CScholarMaterial.rim, height: 24),
                          _textField('Max Search Results', 'e.g., 20', _maxResultsCtrl),
                        ]),
                        const SizedBox(height: 20),
                        // Content & Access
                        _sectionCard('Content & Access', Icons.content_paste, [
                          _toggleRow('Auto-Archive', 'Automatically archive theses older than 3 years', _autoArchive, (v) => setState(() => _autoArchive = v)),
                          const Divider(color: CScholarMaterial.rim, height: 24),
                          _toggleRow('Public Search', 'Allow non-logged-in users to search', _publicSearch, (v) => setState(() => _publicSearch = v)),
                        ]),
                        const SizedBox(height: 20),
                        // Contact
                        _sectionCard('Contact Information', Icons.contact_mail, [
                          _textField('Contact Name', 'e.g., CEIT Office', _contactNameCtrl),
                          const SizedBox(height: 16),
                          _textField('Contact Email', 'e.g., ceit@csu.edu.ph', _contactEmailCtrl),
                        ]),
                        const SizedBox(height: 32),
                        // Version info
                        Center(
                          child: Text(
                            'CScholar v1.0.0 — CEIT Thesis & Capstone Repository',
                            style: TextStyle(fontSize: 12, color: CScholarColors.textSecondary.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return CScholarCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CScholarMaterial.rim),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: CScholarColors.primaryGreen),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _textField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return NeumorphField(
      controller: controller,
      label: label,
      hintText: hint,
      maxLines: maxLines,
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
        NeumorphToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: CScholarMaterial.clay,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: const Text('System Settings', style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const Center(child: Text('Mobile view - Settings')),
    );
  }
}
