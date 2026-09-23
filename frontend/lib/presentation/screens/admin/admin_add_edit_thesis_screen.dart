import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/thesis.dart';
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
  final _keywordsCtrl = TextEditingController();

  // All option lists are loaded from the database; IDs submitted are real DB IDs.
  Program? _program;
  AcademicYear? _year;
  String? _researchType;
  Adviser? _adviser;
  Category? _category;
  final Set<int> _authorIds = {};
  bool _isSubmitting = false;

  String? _submitError;

  // PDF upload + preview state
  PlatformFile? _selectedPdf;
  bool _isExtracting = false;
  String _extractedText = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    if (_program == null ||
        _year == null ||
        _researchType == null ||
        _category == null ||
        _authorIds.isEmpty) {
      setState(() => _submitError =
          'Please select a program, academic year, research type, category, and at least one author.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final api = ref.read(thesisApiProvider);
    final payload = ThesisFormPayload(
      title: _titleCtrl.text.trim(),
      abstract_: _abstractCtrl.text.trim(),
      programId: _program!.id,
      academicYearId: _year!.id,
      researchType: _researchType!,
      authorIds: _authorIds.toList(),
      adviserId: _adviser?.id,
      categoryIds: [_category!.id],
      keywordTerms: _keywordsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    try {
      if (widget.thesisId != null) {
        await api.update(widget.thesisId!, payload);
      } else {
        await api.create(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thesis registered successfully!')),
      );
      context.go('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

                              // PDF Upload + Preview Section
                              _pdfUploadSection(),

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

                                    // Grid 1: Academic Classification (options from the database)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('ACADEMIC PROGRAM', isRequired: true),
                                              const SizedBox(height: 6),
                                              _programDropdown(),
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
                                              _academicYearDropdown(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Grid 2: Research Type & Adviser (options from the database)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('RESEARCH TYPE', isRequired: true),
                                              const SizedBox(height: 6),
                                              _researchTypeDropdown(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('ADVISER', isRequired: false),
                                              const SizedBox(height: 6),
                                              _adviserDropdown(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Authors (selected from the database)
                                    _fieldLabel('AUTHORS', isRequired: true),
                                    const SizedBox(height: 6),
                                    _authorsPicker(),

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
                                              _categoryDropdown(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _fieldLabel('KEYWORDS / TAGS', isRequired: false),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _keywordsCtrl,
                                                decoration: const InputDecoration(
                                                  hintText: 'comma, separated, keywords',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 28),

                                    if (_submitError != null)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CScholarColors.errorLight,
                                          borderRadius: BorderRadius.circular(CScholarRadius.md),
                                          border: Border.all(
                                            color: CScholarColors.error.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _submitError!,
                                          style: CScholarTextStyles.inter(
                                              12, FontWeight.w500, CScholarColors.error),
                                        ),
                                      ),

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

  // ─── PDF Upload + Preview ───────────────────────────────────────────────────

  Future<void> _pickAndParsePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _selectedPdf = file;
      _isExtracting = true;
      _extractedText = '';
    });

    try {
      final api = ref.read(uploadApiProvider);
      final preview = await api.uploadPdf(file.bytes!, file.name);
      if (!mounted) return;
      setState(() {
        _extractedText = preview.extractedText;
        _isExtracting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extractedText = 'Failed to extract text: $e';
        _isExtracting = false;
      });
    }
  }

  Widget _pdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CScholarRadius.xxl),
        border: Border.all(color: CScholarColors.borderLight),
        boxShadow: CScholarShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('UPLOAD PDF (OPTIONAL)', isRequired: false),
          const SizedBox(height: 4),
          Text(
            'Upload a PDF to extract its text. The extracted text is shown below for you to read and manually copy into the form fields.',
            style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isExtracting ? null : _pickAndParsePdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CScholarColors.primaryGreen,
                  side: const BorderSide(color: CScholarColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.md)),
                ),
                icon: _isExtracting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CScholarColors.primaryGreen),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(
                  _isExtracting ? 'Extracting...' : 'Choose PDF',
                  style: CScholarTextStyles.inter(13, FontWeight.w600, CScholarColors.primaryGreen),
                ),
              ),
              if (_selectedPdf != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.insert_drive_file, size: 18, color: CScholarColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedPdf!.name,
                    style: CScholarTextStyles.inter(12.5, FontWeight.w500, CScholarColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (_extractedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Extracted Text Preview',
              style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CScholarColors.inputBg,
                borderRadius: BorderRadius.circular(CScholarRadius.md),
                border: Border.all(color: CScholarColors.borderLight),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _extractedText,
                  style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formLoading() {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _programDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final programsAsync = ref.watch(programsProvider);
        return programsAsync.when(
          data: (programs) {
            if (programs.isEmpty) return const Text('No programs available');
            return DropdownButtonFormField<Program>(
              initialValue: _program != null && programs.any((p) => p.id == _program!.id)
                  ? programs.firstWhere((p) => p.id == _program!.id)
                  : null,
              items: programs
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} (${p.code})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _program = v),
              validator: (v) => v == null ? 'Select a program' : null,
              hint: const Text('Select program'),
            );
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load programs: $err'),
        );
      },
    );
  }

  Widget _academicYearDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final yearsAsync = ref.watch(academicYearsProvider);
        return yearsAsync.when(
          data: (years) {
            if (years.isEmpty) return const Text('No academic years available');
            return DropdownButtonFormField<AcademicYear>(
              initialValue: _year != null && years.any((y) => y.id == _year!.id)
                  ? years.firstWhere((y) => y.id == _year!.id)
                  : null,
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _year = v),
              validator: (v) => v == null ? 'Select an academic year' : null,
              hint: const Text('Select academic year'),
            );
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load academic years: $err'),
        );
      },
    );
  }

  Widget _researchTypeDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final typesAsync = ref.watch(researchTypesProvider);
        return typesAsync.when(
          data: (types) {
            if (types.isEmpty) return const Text('No research types available');
            return DropdownButtonFormField<String>(
              initialValue: _researchType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _researchType = v),
              validator: (v) => v == null ? 'Select a research type' : null,
              hint: const Text('Select research type'),
            );
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load research types: $err'),
        );
      },
    );
  }

  Widget _adviserDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final advisersAsync = ref.watch(advisersProvider);
        return advisersAsync.when(
          data: (advisers) {
            if (advisers.isEmpty) return const Text('No advisers available');
            return DropdownButtonFormField<Adviser>(
              initialValue: _adviser != null && advisers.any((a) => a.id == _adviser!.id)
                  ? advisers.firstWhere((a) => a.id == _adviser!.id)
                  : null,
              items: advisers
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.fullName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _adviser = v),
              hint: const Text('Select adviser (optional)'),
            );
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load advisers: $err'),
        );
      },
    );
  }

  Widget _categoryDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final categoriesAsync = ref.watch(categoriesProvider);
        return categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) return const Text('No categories available');
            return DropdownButtonFormField<Category>(
              initialValue: _category != null &&
                      categories.any((c) => c.id == _category!.id)
                  ? categories.firstWhere((c) => c.id == _category!.id)
                  : null,
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Select a category' : null,
              hint: const Text('Select category'),
            );
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load categories here: $err'),
        );
      },
    );
  }

  Widget _authorsPicker() {
    return Consumer(
      builder: (context, ref, _) {
        final authorsAsync = ref.watch(authorsProvider);
        return authorsAsync.when(
          data: (authors) {
            if (authors.isEmpty) return const Text('No authors available');
            return _authorChips(authors);
          },
          loading: _formLoading,
          error: (err, _) => Text('Could not load authors: $err'),
        );
      },
    );
  }

  Widget _authorChips(List<Author> authors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: authors.map((a) {
            final selected = _authorIds.contains(a.id);
            return FilterChip(
              label: Text(a.fullName),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _authorIds.add(a.id);
                } else {
                  _authorIds.remove(a.id);
                }
              }),
            );
          }).toList(),
        ),
        if (_authorIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No authors selected yet',
              style: CScholarTextStyles.inter(
                  12, FontWeight.w500, CScholarColors.textMuted),
            ),
          ),
      ],
    );
  }
}
