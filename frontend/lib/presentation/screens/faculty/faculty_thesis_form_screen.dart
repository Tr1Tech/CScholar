import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/common/empty_state.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';
import 'package:frontend/presentation/widgets/faculty_topbar.dart';

/// Faculty: submit a new thesis, or edit your own draft. Creates always save
/// as a draft for admin review (the backend forces `draft` for faculty
/// regardless of what is sent); edits are limited to own drafts.
class FacultyThesisFormScreen extends ConsumerStatefulWidget {
  final int? thesisId;
  const FacultyThesisFormScreen({super.key, this.thesisId});

  @override
  ConsumerState<FacultyThesisFormScreen> createState() => _FacultyThesisFormScreenState();
}

class _FacultyThesisFormScreenState extends ConsumerState<FacultyThesisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  String? _researchType;
  int? _programId;
  int? _yearId;
  final Set<int> _authorIds = {};
  final Set<int> _categoryIds = {};
  bool _submitting = false;
  int? _prefilledFor;
  String? _pdfUrl;
  String? _pdfFileName;
  bool _uploadingPdf = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.thesisId != null;
    final me = ref.watch(currentUserProvider);

    // Edit mode: prefill once the thesis loads. Only own drafts are editable
    // (the backend enforces the same rule).
    Thesis? loaded;
    if (isEdit) {
      final existing = ref.watch(thesisProvider(widget.thesisId!));
      loaded = existing.value;
      if (loaded != null && _prefilledFor != loaded.id) {
        _prefilledFor = loaded.id;
        final t = loaded;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _titleCtrl.text = t.title;
            _abstractCtrl.text = t.abstract;
            _researchType = t.researchType;
            _programId = t.programId;
            _yearId = t.academicYearId;
            _authorIds
              ..clear()
              ..addAll((t.authors ?? []).map((a) => a.id));
            _categoryIds
              ..clear()
              ..addAll((t.categories ?? []).map((c) => c.id));
            _keywordsCtrl.text = (t.keywords ?? []).map((k) => k.term).join(', ');
            _pdfUrl ??= t.pdfUrl;
            _pdfFileName ??= t.pdfUrl != null ? 'Attached manuscript' : null;
          });
        });
      }
    }
    final notMine = isEdit &&
        loaded != null &&
        (loaded.status != 'draft' || (loaded.creatorId != null && loaded.creatorId != me?.id));

    final body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: isEdit ? 'Edit Thesis' : 'New Thesis',
            subtitle: isEdit
                ? 'Only drafts you submitted can be edited — saving keeps it a draft.'
                : 'Submits as a draft — an admin reviews and publishes it.',
          ),
          const SizedBox(height: 20),
          if (notMine)
            const EmptyState(
              icon: Icons.lock_outline,
              title: 'Not editable',
              message: 'Only drafts you submitted can be edited.',
            )
          else
            CScholarCard(
              child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Title *'),
                      NeumorphField(
                        controller: _titleCtrl,
                        hintText: 'Study title',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Abstract *'),
                      NeumorphField(
                        controller: _abstractCtrl,
                        maxLines: 6,
                        hintText: 'Summary of the study',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Abstract is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _researchTypeField(),
                      const SizedBox(height: 16),
                      _programField(),
                      const SizedBox(height: 16),
                      _yearField(),
                      const SizedBox(height: 16),
                      _adviserField(),
                      const SizedBox(height: 16),
                      _authorsField(),
                      const SizedBox(height: 16),
                      _categoriesField(),
                      const SizedBox(height: 16),
                      _label('Keywords (comma-separated)'),
                      NeumorphField(
                        controller: _keywordsCtrl,
                        hintText: 'e.g. machine learning, OCR, summarization',
                      ),
                      const SizedBox(height: 16),
                      _label('Manuscript (PDF, optional)'),
                      _manuscriptRow(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: NeumorphButton(
                              onPressed: _submitting ? null : () => context.go('/faculty/theses'),
                              label: 'Cancel',
                              gel: false,
                              expand: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeumorphButton(
                              onPressed: _submitting ? null : _submit,
                              loading: _submitting,
                              icon: Icons.send_outlined,
                              label: _submitting
                                  ? 'Submitting...'
                                  : (isEdit ? 'Save Changes' : 'Submit Draft'),
                              expand: true,
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
        );

    return CScholarShell(
      sidebar: const FacultySidebar(currentPath: '/faculty/theses'),
      topbar: FacultyTopbar(user: me),
      mobileTitle: isEdit ? 'Edit Thesis' : 'New Thesis',
      backRoute: '/faculty/theses',
      maxWidth: 860,
      child: body,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary)),
    );
  }

  Widget _researchTypeField() {
    final types = ref.watch(researchTypesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Research Type *'),
        types.when(
          data: (list) => NeumorphSelect<String>(
            initialValue: _researchType,
            hintText: 'Select research type',
            items: list.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _researchType = v),
            validator: (v) => v == null ? 'Select a research type' : null,
          ),
          loading: () => const ClayLoader(height: 8),
          error: (e, _) => Text('Could not load types: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _programField() {
    final programs = ref.watch(programsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Program *'),
        programs.when(
          data: (list) => NeumorphSelect<int>(
            initialValue: _programId,
            hintText: 'Select program',
            items: list.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => setState(() => _programId = v),
            validator: (v) => v == null ? 'Select a program' : null,
          ),
          loading: () => const ClayLoader(height: 8),
          error: (e, _) => Text('Could not load programs: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _yearField() {
    final years = ref.watch(academicYearsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Academic Year *'),
        years.when(
          data: (list) => NeumorphSelect<int>(
            initialValue: _yearId,
            hintText: 'Select academic year',
            items: list.map((y) => DropdownMenuItem(value: y.id, child: Text(y.label))).toList(),
            onChanged: (v) => setState(() => _yearId = v),
            validator: (v) => v == null ? 'Select an academic year' : null,
          ),
          loading: () => const ClayLoader(height: 8),
          error: (e, _) => Text('Could not load years: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _adviserField() {
    final me = ref.watch(currentUserProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Adviser'),
        // Fixed: the submitter is always recorded as the adviser.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CScholarColors.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 20, color: CScholarColors.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me?.username ?? 'You',
                        style: CScholarTextStyles.inter(
                            13, FontWeight.w600, CScholarColors.textPrimary)),
                    Text('Adviser (you)',
                        style: CScholarTextStyles.inter(
                            11.5, FontWeight.w400, CScholarColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline, size: 16, color: CScholarColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _authorsField() {
    final authors = ref.watch(authorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Authors (${_authorIds.length} selected)'),
        authors.when(
          data: (list) => NeumorphButton(
            onPressed: () => _pickMany(
              title: 'Select Authors',
              items: {for (final a in list) a.id: a.fullName},
              selected: _authorIds,
            ),
            icon: Icons.people_outline,
            gel: false,
            label: _authorIds.isEmpty ? 'Choose authors' : '${_authorIds.length} chosen',
          ),
          loading: () => const ClayLoader(height: 8),
          error: (e, _) => Text('Could not load authors: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _categoriesField() {
    final categories = ref.watch(categoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Categories (${_categoryIds.length} selected)'),
        categories.when(
          data: (list) => NeumorphButton(
            onPressed: () => _pickMany(
              title: 'Select Categories',
              items: {for (final c in list) c.id: c.name},
              selected: _categoryIds,
            ),
            icon: Icons.category_outlined,
            gel: false,
            label: _categoryIds.isEmpty ? 'Choose categories' : '${_categoryIds.length} chosen',
          ),
          loading: () => const ClayLoader(height: 8),
          error: (e, _) => Text('Could not load categories: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _manuscriptRow() {
    if (_uploadingPdf) {
      return const SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Uploading PDF…', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }
    if (_pdfUrl != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CScholarColors.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CScholarColors.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 20, color: CScholarColors.primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_pdfFileName ?? 'Manuscript attached',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.inter(12.5, FontWeight.w600, CScholarColors.textPrimary)),
            ),
            if (widget.thesisId == null)
              TextButton(
                onPressed: () => setState(() {
                  _pdfUrl = null;
                  _pdfFileName = null;
                }),
                child: const Text('Remove', style: TextStyle(fontSize: 12)),
              )
            else
              const Tooltip(
                message: 'Uploading again replaces the attached file',
                child: Icon(Icons.info_outline, size: 18, color: CScholarColors.textMuted),
              ),
          ],
        ),
      );
    }
    return NeumorphButton(
      onPressed: _pickAndUploadPdf,
      icon: Icons.upload_file_outlined,
      gel: false,
      label: 'Attach PDF manuscript',
    );
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the PDF file — try a smaller file')),
        );
      }
      return;
    }
    setState(() => _uploadingPdf = true);
    try {
      final response = await ref.read(uploadApiProvider).uploadPdf(
            bytes,
            file.name,
            thesisId: widget.thesisId,
          );
      if (!mounted) return;
      setState(() {
        // Edit mode: the server already linked it to the thesis record.
        // Create mode: carried into the submission payload (validated server-side).
        _pdfUrl = response.pdfUrl;
        _pdfFileName = file.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.thesisId == null
                ? 'PDF ready — it attaches when you submit'
                : 'Manuscript replaced')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _pickMany({
    required String title,
    required Map<int, String> items,
    required Set<int> selected,
  }) async {
    final temp = Set<int>.from(selected);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => GlassDialog(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 380,
            height: 380,
            child: ListView(
              children: items.entries
                  // control-exempt: category multi-picker keeps the native
                  // CheckboxListTile row (accessible checked state); the
                  // dialog shell itself is GlassDialog.
                  .map((e) => CheckboxListTile(
                        dense: true,
                        title: Text(e.value, style: const TextStyle(fontSize: 13)),
                        value: temp.contains(e.key),
                        onChanged: (v) => setDialog(
                            () => v == true ? temp.add(e.key) : temp.remove(e.key)),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            NeumorphButton(
                onPressed: () => Navigator.pop(ctx),
                label: 'Cancel',
                gel: false),
            NeumorphButton(
              onPressed: () {
                setState(() {
                  selected
                    ..clear()
                    ..addAll(temp);
                });
                Navigator.pop(ctx);
              },
              label: 'Done',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadingPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for the PDF upload to finish')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final keywords = _keywordsCtrl.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
      if (widget.thesisId != null) {
        await ref.read(thesisApiProvider).update(
              widget.thesisId!,
              ThesisFormPayload(
                title: _titleCtrl.text.trim(),
                abstract_: _abstractCtrl.text.trim(),
                programId: _programId!,
                academicYearId: _yearId!,
                researchType: _researchType!,
                authorIds: _authorIds.toList(),
                categoryIds: _categoryIds.toList(),
                keywordTerms: keywords,
              ),
            );
        ref.invalidate(thesisDetailProvider(widget.thesisId!));
        final fresh = await ref.refresh(facultyThesesProvider.future);
        if (mounted) {
          final ok = fresh.any((t) => t.id == widget.thesisId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok
                  ? 'Draft saved'
                  : 'Saved on server, but the list did not refresh — reload the page'),
              backgroundColor: ok ? CScholarColors.success : null,
            ),
          );
          context.go('/faculty/theses');
        }
      } else {
        await ref.read(thesisApiProvider).create(
              ThesisFormPayload(
                title: _titleCtrl.text.trim(),
                abstract_: _abstractCtrl.text.trim(),
                programId: _programId!,
                academicYearId: _yearId!,
                researchType: _researchType!,
                authorIds: _authorIds.toList(),
                categoryIds: _categoryIds.toList(),
                keywordTerms: keywords,
                pdfUrl: _pdfUrl,
                status: 'draft',
              ),
            );
        ref.invalidate(facultyThesesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Draft submitted — an admin will review it'),
                backgroundColor: CScholarColors.success),
          );
          context.go('/faculty/theses');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
