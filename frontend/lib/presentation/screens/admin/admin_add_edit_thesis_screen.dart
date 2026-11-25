import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/common/inline_retry.dart';
import 'package:frontend/presentation/widgets/common/discard_guard.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/duplicate_dialog.dart';
import 'package:frontend/presentation/widgets/common/new_author_dialog.dart';
import 'package:file_picker/file_picker.dart';

class AdminAddEditThesisScreen extends ConsumerStatefulWidget {
  final int? thesisId;
  const AdminAddEditThesisScreen({super.key, this.thesisId});

  @override
  ConsumerState<AdminAddEditThesisScreen> createState() =>
      _AdminAddEditThesisScreenState();
}

class _AdminAddEditThesisScreenState
    extends ConsumerState<AdminAddEditThesisScreen> {
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
  bool _isUploadingPdf = false;

  String? _submitError;
  String? _pdfFileName;
  int? _pdfFileSize;
  String? _pdfUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  /// True when the form holds typed work worth protecting.
  bool get _hasDraftInput =>
      _titleCtrl.text.trim().isNotEmpty ||
      _abstractCtrl.text.trim().isNotEmpty ||
      _keywordsCtrl.text.trim().isNotEmpty ||
      _program != null ||
      _year != null ||
      _researchType != null ||
      _adviser != null ||
      _category != null ||
      _authorIds.isNotEmpty ||
      _pdfUrl != null;

  @override
  void initState() {
    super.initState();
    if (widget.thesisId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadThesis());
    }
  }

  Future<void> _loadThesis() async {
    try {
      final thesisAsync = await ref.read(
        thesisDetailProvider(widget.thesisId!).future,
      );
      if (!mounted || thesisAsync == null) return;
      final thesis = thesisAsync;
      setState(() {
        _titleCtrl.text = thesis.title;
        _abstractCtrl.text = thesis.abstract;
        _keywordsCtrl.text =
            thesis.keywords?.map((k) => k.term).join('; ') ?? '';
        _program = thesis.program;
        _year = thesis.academicYear;
        _researchType = thesis.researchType;
        _adviser = thesis.advisers?.isNotEmpty == true
            ? thesis.advisers!.first
            : null;
        _category = thesis.categories?.isNotEmpty == true
            ? thesis.categories!.first
            : null;
        _authorIds.clear();
        if (thesis.authors != null) {
          _authorIds.addAll(thesis.authors!.map((a) => a.id));
        }
        _pdfUrl = thesis.pdfUrl;
        if (_pdfUrl != null) {
          // Extract filename from pdf_url
          _pdfFileName = _pdfUrl!.split('/').last;
        }
      });
    } catch (e) {
      // Offline, or the id no longer exists. The form stays empty and says so
      // instead of throwing out of a post-frame callback nobody awaits (which
      // is an unhandled async error, not a red banner).
      if (!mounted) return;
      setState(
        () => _submitError = userFacingError(
          e,
          fallback: 'This thesis could not be loaded. It may have been removed, or the connection failed.',
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    if (_program == null ||
        _year == null ||
        _researchType == null ||
        _category == null ||
        _authorIds.isEmpty) {
      setState(
        () => _submitError = 'Please select a program, academic year, research type, category, and at least one author.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final api = ref.read(thesisApiProvider);
    ThesisFormPayload buildPayload({bool confirmDuplicate = false}) =>
        ThesisFormPayload(
          title: _titleCtrl.text.trim(),
          abstract_: _abstractCtrl.text.trim(),
          programId: _program!.id,
          academicYearId: _year!.id,
          researchType: _researchType!,
          authorIds: _authorIds.toList(),
          adviserId: _adviser?.id,
          categoryIds: [_category!.id],
          keywordTerms: _keywordsCtrl.text
              .split(RegExp(r'[,;]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          pdfUrl: _pdfUrl,
          // New records start as drafts, exactly like bulk import. The admin
          // approves and publishes from the management list, so "nothing goes
          // public without review" stays true for every entry path. Edits keep
          // the current status (null = unchanged).
          status: widget.thesisId == null ? 'draft' : null,
          confirmDuplicate: confirmDuplicate,
        );

    try {
      if (widget.thesisId != null) {
        await api.update(widget.thesisId!, buildPayload());
      } else {
        try {
          await api.create(buildPayload());
        } catch (e) {
          final dupes = parseDuplicateCandidates(e);
          if (dupes.isEmpty || !mounted) rethrow;
          final confirmed = await showDuplicateConfirmDialog(context, dupes);
          if (confirmed != true || !mounted) {
            setState(() => _isSubmitting = false);
            return;
          }
          await api.create(buildPayload(confirmDuplicate: true));
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.thesisId == null
                ? 'Saved as a draft — approve and publish it from the list.'
                : 'Thesis updated successfully!',
          ),
        ),
      );
      // Refresh the thesis list so the new one appears
      ref.invalidate(thesisListProvider(const ThesisListParams()));
      context.go('/admin/thesis/management');
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _submitError = userFacingError(
          e,
          fallback: "We couldn't save this thesis. Check your connection and try again.",
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CScholarShell(
      sidebar: const AdminSidebar(currentPath: '/admin/thesis/management'),
      topbar: const AdminTopbar(),
      mobileTitle: widget.thesisId != null ? 'Edit Thesis' : 'Add Thesis',
      backRoute: '/admin/thesis/management',
      maxWidth: 1040,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/admin/thesis/management'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(
                  'Back to list',
                  style: CScholarTextStyles.body(
                    12.5,
                    FontWeight.w600,
                    CScholarColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Instructions Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CScholarColors.primaryGreenVeryLight,
                                  borderRadius: BorderRadius.circular(
                                    CScholarRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  'SUBMISSION PORTAL',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(
                                    10.5,
                                    FontWeight.w700,
                                    CScholarColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '•  CEIT Department',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CScholarTextStyles.body(
                                  12,
                                  FontWeight.w500,
                                  CScholarColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register Academic Manuscript',
                          style: CScholarTextStyles.heading(
                            22,
                            FontWeight.w800,
                            CScholarColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please provide complete and accurate information regarding the academic research manuscript.',
                          style: CScholarTextStyles.body(
                            13,
                            FontWeight.w400,
                            CScholarColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CScholarMaterial.clayDeep,
                        borderRadius: BorderRadius.circular(CScholarRadius.md),
                        border: Border.all(color: CScholarMaterial.rim),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w500,
                            CScholarColors.textMuted,
                          ),
                          children: [
                            TextSpan(text: 'Fields marked with '),
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: CScholarColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' are required'),
                          ],
                        ),
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
                  color: CScholarMaterial.clay,
                  borderRadius: BorderRadius.circular(CScholarRadius.softCard),
                  border: Border.all(color: CScholarMaterial.rim),
                  boxShadow: CScholarShadows.card,
                ),
                // Form sections cascade on the page rhythm.
                child: StaggerColumn(
                  pitch: MotionPitch.page,
                  children: [
                    // Title Input
                    _fieldLabel('TITLE', isRequired: true),
                    const SizedBox(height: 6),
                    NeumorphField(
                      controller: _titleCtrl,
                      hintText:
                          'Enter complete thesis or capstone project title...',
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter thesis title'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Abstract Textarea
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _fieldLabel('ABSTRACT', isRequired: true),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Recommended 150-300 words',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.body(
                              11,
                              FontWeight.w400,
                              CScholarColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    NeumorphField(
                      controller: _abstractCtrl,
                      maxLines: 5,
                      hintText: 'Enter abstract summary, methodology, and primary conclusions...',
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please provide the abstract'
                          : null,
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
                    Row(
                      children: [
                        Expanded(
                          child: _fieldLabel('AUTHORS', isRequired: true),
                        ),
                        // Flexible: at phone width with 200% text the button
                        // would otherwise widen the row past its parent.
                        Flexible(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: CScholarColors.primaryGreen,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: _addAuthor,
                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                            label: const Text(
                              'New author',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              NeumorphField(
                                controller: _keywordsCtrl,
                                hintText:
                                    'comma or semicolon; separated, keywords',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // PDF Upload Section
                    _fieldLabel('PDF MANUSCRIPT', isRequired: false),
                    const SizedBox(height: 6),
                    _pdfUploadSection(),

                    const SizedBox(height: 28),

                    if (_submitError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CScholarColors.errorLight,
                          borderRadius: BorderRadius.circular(
                            CScholarRadius.md,
                          ),
                          border: Border.all(
                            color: CScholarColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _submitError!,
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w500,
                            CScholarColors.error,
                          ),
                        ),
                      ),

                    // Form Submission Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: NeumorphButton(
                            onPressed: () async {
                              if (!await confirmDiscardChanges(
                                context,
                                hasChanges: _hasDraftInput,
                                actionLabel: 'thesis management',
                              )) {
                                return;
                              }
                              if (context.mounted) {
                                context.go('/admin/thesis/management');
                              }
                            },
                            label: 'Cancel',
                            gel: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: NeumorphButton(
                            onPressed: _isSubmitting ? null : _submit,
                            loading: _isSubmitting,
                            icon: _isSubmitting ? null : Icons.check,
                            label: _isSubmitting
                                ? 'Submitting...'
                                : 'Submit Thesis / Capstone',
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
    );
  }

  Widget _fieldLabel(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The label sits inside spaceBetween header rows, so it has to be able
        // to shrink (200% text) rather than widening the row past its parent.
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CScholarTextStyles.body(
              11,
              FontWeight.w700,
              CScholarColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(
              color: CScholarColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _pdfUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
      ),
      child: _pdfUrl != null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CScholarColors.primaryGreenVeryLight,
                    borderRadius: BorderRadius.circular(CScholarRadius.md),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 24,
                    color: CScholarColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfFileName ?? 'PDF uploaded',
                        style: CScholarTextStyles.body(
                          13,
                          FontWeight.w600,
                          CScholarColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pdfFileSize != null
                            ? '${(_pdfFileSize! / 1024).toStringAsFixed(1)} KB'
                            : 'File attached',
                        style: CScholarTextStyles.body(
                          11.5,
                          FontWeight.w400,
                          CScholarColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                NeumorphIconButton(
                  onPressed: () {
                    setState(() {
                      _pdfUrl = null;
                      _pdfFileName = null;
                      _pdfFileSize = null;
                    });
                  },
                  icon: Icons.close,
                  size: 36,
                  tooltip: 'Remove PDF',
                ),
              ],
            )
          : Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 36,
                  color: CScholarColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload PDF manuscript (optional)',
                  style: CScholarTextStyles.body(
                    13,
                    FontWeight.w500,
                    CScholarColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Max 50MB. PDF will be stored and linked to this thesis.',
                  style: CScholarTextStyles.body(
                    11.5,
                    FontWeight.w400,
                    CScholarColors.textHint,
                  ),
                ),
                const SizedBox(height: 12),
                _isUploadingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : NeumorphButton(
                        onPressed: _pickAndUploadPdf,
                        icon: Icons.upload_file,
                        label: 'Choose PDF',
                      ),
              ],
            ),
    );
  }

  Future<void> _pickAndUploadPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isEmpty) return;

    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;

    setState(() => _isUploadingPdf = true);

    try {
      final api = ref.read(uploadApiProvider);
      final response = await api.uploadPdf(
        bytes,
        file.name,
        thesisId: widget.thesisId,
      );
      if (!mounted) return;
      setState(() {
        _pdfUrl = response.pdfUrl;
        _pdfFileName = file.name;
        _pdfFileSize = bytes.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(
              e,
              fallback: "The PDF couldn't be uploaded. Check the file and your connection, then try again.",
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPdf = false);
    }
  }

  Widget _formLoading() {
    // System-owned indeterminate chrome: recessed clay track + gel sweep,
    // with the reduced-motion policy — not a bare Material spinner.
    return const ClayLoader(height: 8);
  }

  Widget _programDropdown() {
    return Consumer(
      builder: (context, ref, _) {
        final programsAsync = ref.watch(programsProvider);
        return programsAsync.when(
          data: (programs) {
            if (programs.isEmpty) return const Text('No programs available');
            return NeumorphSelect<Program>(
              initialValue:
                  _program != null && programs.any((p) => p.id == _program!.id)
                  ? programs.firstWhere((p) => p.id == _program!.id)
                  : null,
              items: programs
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.code})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _program = v),
              validator: (v) => v == null ? 'Select a program' : null,
              hintText: 'Select program',
            );
          },
          loading: _formLoading,
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Programs could not be loaded.',
            ),
            onRetry: () => ref.invalidate(programsProvider),
          ),
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
            return NeumorphSelect<AcademicYear>(
              initialValue: _year != null && years.any((y) => y.id == _year!.id)
                  ? years.firstWhere((y) => y.id == _year!.id)
                  : null,
              items: years
                  .map((y) => DropdownMenuItem(value: y, child: Text(y.label)))
                  .toList(),
              onChanged: (v) => setState(() => _year = v),
              validator: (v) => v == null ? 'Select an academic year' : null,
              hintText: 'Select academic year',
            );
          },
          loading: _formLoading,
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Academic years could not be loaded.',
            ),
            onRetry: () => ref.invalidate(academicYearsProvider),
          ),
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
            return NeumorphSelect<String>(
              initialValue: _researchType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _researchType = v),
              validator: (v) => v == null ? 'Select a research type' : null,
              hintText: 'Select research type',
            );
          },
          loading: _formLoading,
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Research types could not be loaded.',
            ),
            onRetry: () => ref.invalidate(researchTypesProvider),
          ),
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
            return NeumorphSelect<Adviser>(
              initialValue:
                  _adviser != null && advisers.any((a) => a.id == _adviser!.id)
                  ? advisers.firstWhere((a) => a.id == _adviser!.id)
                  : null,
              items: advisers
                  .map(
                    (a) => DropdownMenuItem(value: a, child: Text(a.fullName)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _adviser = v),
              hintText: 'Select adviser (optional)',
            );
          },
          loading: _formLoading,
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Advisers could not be loaded.',
            ),
            onRetry: () => ref.invalidate(advisersProvider),
          ),
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
            if (categories.isEmpty) {
              return const Text('No categories available');
            }
            return NeumorphSelect<Category>(
              initialValue:
                  _category != null &&
                      categories.any((c) => c.id == _category!.id)
                  ? categories.firstWhere((c) => c.id == _category!.id)
                  : null,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Select a category' : null,
              hintText: 'Select category',
            );
          },
          loading: _formLoading,
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Categories could not be loaded.',
            ),
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        );
      },
    );
  }

  Future<void> _addAuthor() async {
    final author = await showNewAuthorDialog(context);
    if (author == null || !mounted) return;
    // Select the new (or reused) author immediately: the reason the librarian
    // opened the dialog is that this study needs them.
    setState(() => _authorIds.add(author.id));
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
          error: (err, _) => InlineRetry(
            message: userFacingError(
              err,
              fallback: 'Authors could not be loaded.',
            ),
            onRetry: () => ref.invalidate(authorsProvider),
          ),
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
            return ClayChip(
              label: a.fullName,
              selected: selected,
              onTap: () => setState(() {
                if (selected) {
                  _authorIds.remove(a.id);
                } else {
                  _authorIds.add(a.id);
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
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
