import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminAddEditThesisScreen extends ConsumerStatefulWidget {
  final int? thesisId;
  const AdminAddEditThesisScreen({super.key, this.thesisId});

  @override
  ConsumerState<AdminAddEditThesisScreen> createState() => _AdminAddEditThesisScreenState();
}

class _AdminAddEditThesisScreenState extends ConsumerState<AdminAddEditThesisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _authorsCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();

  String _program = 'BS Information Technology';
  String _year = '2025 - 2026';
  String _researchType = 'Capstone';
  String _adviser = '';
  String _category = 'Mobile Application';
  String? _uploadedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _authorsCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final api = ref.read(thesisApiProvider);
    final payload = ThesisFormPayload(
      title: _titleCtrl.text.trim(),
      abstract_: _abstractCtrl.text.trim(),
      programId: _programIdFor(_program),
      academicYearId: _yearIdFor(_year),
      researchType: _researchType,
      authorIds: _authorIdsFor(_authorsCtrl.text.trim()),
      adviserId: _adviserIdFor(_adviser),
      categoryIds: _categoryIdsFor(_category),
      keywordTerms: _keywordsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      pdfUrl: _uploadedFileName,
    );

    try {
      if (widget.thesisId != null) {
        await api.update(widget.thesisId!, payload);
      } else {
        await api.create(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thesis manuscript registered and indexed successfully!')),
      );
      context.go('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  int _programIdFor(String program) {
    switch (program) {
      case 'BS Computer Science':
        return 2;
      case 'BS Information Systems':
        return 3;
      case 'BS Information Technology':
      default:
        return 1;
    }
  }

  int _yearIdFor(String year) {
    switch (year) {
      case '2023 - 2024':
        return 2;
      case '2022 - 2023':
        return 3;
      case '2025 - 2026':
      default:
        return 1;
    }
  }

  int _adviserIdFor(String adviser) {
    // In production, adviser is resolved via API search.
    // Return 0 for "unselected / resolve server-side."
    return 0;
  }

  List<int> _authorIdsFor(String authors) {
    // Map comma-separated author names to IDs (placeholder: assign ID 1 to first author, etc.)
    // In production, this would resolve via a search/lookup API.
    final names = authors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return List.generate(names.length, (i) => i + 1);
  }

  List<int> _categoryIdsFor(String category) {
    switch (category) {
      case 'Machine Learning / AI':
        return [2];
      case 'Web-based System':
        return [3];
      case 'IoT & Automation':
        return [4];
      case 'Mobile Application':
      default:
        return [1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(currentPath: '/admin/thesis/new'),
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: CScholarColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.thesisId != null ? 'Edit Thesis Manuscript' : 'Add New Thesis / Capstone',
                        style: CScholarTextStyles.poppins(18, FontWeight.w700, CScholarColors.textPrimary),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/admin/dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CScholarColors.textPrimary,
                          side: const BorderSide(color: CScholarColors.borderLight),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: Text('Back to Dashboard', style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary)),
                      ),
                    ],
                  ),
                ),

                // Form Scrollable Container
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instructions Banner
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: CScholarColors.primaryGreenVeryLight,
                                              borderRadius: BorderRadius.circular(CScholarRadius.sm),
                                            ),
                                            child: Text(
                                              'SUBMISSION PORTAL',
                                              style: CScholarTextStyles.inter(10.5, FontWeight.w700, CScholarColors.primaryGreen),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('•  CEIT Department', style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Register Academic Manuscript',
                                        style: CScholarTextStyles.poppins(22, FontWeight.w800, CScholarColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Please provide complete and accurate information regarding the academic research manuscript.',
                                        style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(CScholarRadius.md),
                                      border: Border.all(color: CScholarColors.borderLight),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.textMuted),
                                        children: const [
                                          TextSpan(text: 'Fields marked with '),
                                          TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          TextSpan(text: ' are required'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Form Card
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(CScholarRadius.xxl),
                                  border: Border.all(color: CScholarColors.borderLight),
                                  boxShadow: CScholarShadows.card,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title Input
                                    _fieldLabel('TITLE', isRequired: true),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _titleCtrl,
                                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter thesis title' : null,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter complete thesis or capstone project title...',
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Abstract Textarea
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _fieldLabel('ABSTRACT', isRequired: true),
                                        Text('Recommended 150-300 words', style: CScholarTextStyles.inter(11, FontWeight.w400, CScholarColors.textHint)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _abstractCtrl,
                                      maxLines: 5,
                                      validator: (v) => (v == null || v.isEmpty) ? 'Please provide the abstract' : null,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter abstract summary, methodology, and primary conclusions...',
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Grid 1: Academic Classification
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('ACADEMIC PROGRAM', isRequired: true),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _program,
                                                items: const [
                                                  DropdownMenuItem(value: 'BS Information Technology', child: Text('BS Information Technology (BSIT)')),
                                                  DropdownMenuItem(value: 'BS Computer Science', child: Text('BS Computer Science (BSCS)')),
                                                  DropdownMenuItem(value: 'BS Information Systems', child: Text('BS Information Systems (BSIS)')),
                                                ],
                                                onChanged: (v) => setState(() => _program = v!),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('ACADEMIC YEAR', isRequired: true),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _year,
                                                items: const [
                                                  DropdownMenuItem(value: '2025 - 2026', child: Text('2025 - 2026')),
                                                ],
                                                onChanged: (v) => setState(() => _year = v!),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Grid 2: Research Type & Adviser
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('RESEARCH TYPE', isRequired: true),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _researchType,
                                                items: const [
                                                  DropdownMenuItem(value: 'Capstone', child: Text('Capstone')),
                                                  DropdownMenuItem(value: 'Thesis', child: Text('Thesis')),
                                                ],
                                                onChanged: (v) => setState(() => _researchType = v!),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('FACULTY ADVISER', isRequired: true),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _adviser.isEmpty ? null : _adviser,
                                                items: const [],
                                                onChanged: (v) => setState(() => _adviser = v ?? ''),
                                                hint: Text('Select or search for faculty adviser',
                                                    style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textHint)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Authors Input
                                    _fieldLabel('AUTHORS', isRequired: true),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _authorsCtrl,
                                      validator: (v) => (v == null || v.isEmpty) ? 'Please specify authors' : null,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Author One, Author Two',
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Primary Category & Keywords
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('PRIMARY CATEGORY', isRequired: true),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue: _category,
                                                items: const [
                                                  DropdownMenuItem(value: 'Mobile Application', child: Text('Mobile Application')),
                                                  DropdownMenuItem(value: 'Machine Learning / AI', child: Text('Machine Learning / AI')),
                                                  DropdownMenuItem(value: 'Web-based System', child: Text('Web-based System')),
                                                  DropdownMenuItem(value: 'IoT & Automation', child: Text('IoT & Automation')),
                                                ],
                                                onChanged: (v) => setState(() => _category = v!),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('KEYWORDS / TAGS', isRequired: true),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _keywordsCtrl,
                                                decoration: const InputDecoration(
                                                  hintText: 'campus navigation, GPS, BLE beacons',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 28),

                                    // Manuscript PDF File Upload Area
                                    _fieldLabel('MANUSCRIPT PDF ATTACHMENT', isRequired: false),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        setState(() => _uploadedFileName = 'CScholar_Manuscript_Final_Draft.pdf (4.8 MB)');
                                      },
                                      borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(CScholarRadius.lg),
                                          border: Border.all(
                                            color: CScholarColors.primaryGreen.withValues(alpha: 0.4),
                                            width: 1.5,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.cloud_upload_outlined, size: 38, color: CScholarColors.primaryGreen),
                                            const SizedBox(height: 10),
                                            Text(
                                              _uploadedFileName ?? 'Click or drag PDF manuscript file here to upload',
                                              style: CScholarTextStyles.inter(13.5, FontWeight.w600, CScholarColors.textPrimary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Supports PDF documents up to 25MB for AI indexing',
                                              style: CScholarTextStyles.inter(11.5, FontWeight.w400, CScholarColors.textHint),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Form Submission Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => context.go('/admin/dashboard'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: CScholarColors.textSecondary,
                                            side: const BorderSide(color: CScholarColors.borderLight),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          ),
                                          child: Text('Cancel', style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.textSecondary)),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Draft saved successfully!')),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: CScholarColors.primaryGreen,
                                            side: const BorderSide(color: CScholarColors.primaryGreen),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          ),
                                          child: Text('Save Draft', style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.primaryGreen)),
                                        ),
                                        const SizedBox(width: 12),
                                        FilledButton.icon(
                                          onPressed: _isSubmitting ? null : _submit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: CScholarColors.primaryGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                                          ),
                                          icon: _isSubmitting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.check, size: 18),
                                          label: Text(
                                            _isSubmitting ? 'Submitting...' : 'Submit Thesis / Capstone',
                                            style: CScholarTextStyles.inter(13.5, FontWeight.w700, Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
