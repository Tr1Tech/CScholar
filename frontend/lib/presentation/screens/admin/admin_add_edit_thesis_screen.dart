// Admin: Add/Edit Thesis — Stitch design v2
// Sidebar + topbar + form

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminAddEditThesisScreen extends ConsumerStatefulWidget {
  final int? thesisId;
  const AdminAddEditThesisScreen({super.key, this.thesisId});

  @override
  ConsumerState<AdminAddEditThesisScreen> createState() => _AdminAddEditThesisScreenState();
}

class _AdminAddEditThesisScreenState extends ConsumerState<AdminAddEditThesisScreen> {
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _status = 'published';
  String _researchType = 'thesis';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (!isWide) {
      return _mobileLayout(context);
    }

    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          const AdminSidebar(currentPath: '/admin/thesis/new'),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: CScholarColors.dividerLight)),
                  ),
                  child: Row(
                    children: [
                      Text(widget.thesisId != null ? 'Edit Thesis' : 'Add New Thesis', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/admin/thesis/management'),
                        style: OutlinedButton.styleFrom(foregroundColor: CScholarColors.textPrimary, side: BorderSide(color: CScholarColors.dividerLight)),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to List'),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CScholarColors.dividerLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thesis Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary)),
                          const SizedBox(height: 20),
                          _textField('Title', 'Enter thesis title', _titleCtrl),
                          const SizedBox(height: 16),
                          _textField('Abstract', 'Enter abstract', _abstractCtrl, maxLines: 5),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _dropdownField('Research Type', ['thesis', 'capstone'], _researchType, (v) => setState(() => _researchType = v!))),
                              const SizedBox(width: 16),
                              Expanded(child: _dropdownField('Status', ['published', 'pending', 'rejected'], _status, (v) => setState(() => _status = v!))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _textField('Year', 'e.g., 2024', _yearCtrl),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.go('/admin/thesis/management'),
                                style: OutlinedButton.styleFrom(foregroundColor: CScholarColors.textPrimary, side: BorderSide(color: CScholarColors.dividerLight)),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thesis saved'), backgroundColor: CScholarColors.success));
                                  context.go('/admin/thesis/management');
                                },
                                style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, foregroundColor: Colors.white),
                                child: const Text('Save Thesis'),
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
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
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
            fillColor: CScholarColors.backgroundLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.primaryGreen)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, List<String> options, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o.toUpperCase()))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: CScholarColors.backgroundLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: CScholarColors.dividerLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.primaryGreen)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
          onPressed: () => context.go('/admin/thesis/management'),
        ),
        title: Text(widget.thesisId != null ? 'Edit Thesis' : 'Add New Thesis', style: const TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const Center(child: Text('Mobile view - Add/Edit Thesis')),
    );
  }
}
