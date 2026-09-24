import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/presentation/widgets/faculty_sidebar.dart';

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
  int? _adviserId;
  final Set<int> _authorIds = {};
  final Set<int> _categoryIds = {};
  bool _submitting = false;
  bool _adviserPreselected = false;
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Thesis' : 'New Thesis',
                  style: CScholarTextStyles.poppins(24, FontWeight.w800, CScholarColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                  isEdit
                      ? 'Only drafts you submitted can be edited — saving keeps it a draft.'
                      : 'Submits as a draft — an admin reviews and publishes it.',
                  style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted)),
              const SizedBox(height: 20),
              if (notMine)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(CScholarRadius.xl),
                    border: Border.all(color: CScholarColors.borderLight),
                  ),
                  child: Text(
                    'Only drafts you submitted can be edited.',
                    style: CScholarTextStyles.inter(13, FontWeight.w500, CScholarColors.textMuted),
                  ),
                )
              else
              Container(
                padding: EdgeInsets.all(isDesktop ? 28 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CScholarRadius.xl),
                  border: Border.all(color: CScholarColors.borderLight),
                  boxShadow: CScholarShadows.card,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Title *'),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Study title', border: OutlineInputBorder()),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Abstract *'),
                      TextFormField(
                        controller: _abstractCtrl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                            hintText: 'Summary of the study', border: OutlineInputBorder()),
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
                      if (!isEdit) _adviserField(),
                      if (!isEdit) const SizedBox(height: 16),
                      _authorsField(),
                      const SizedBox(height: 16),
                      _categoriesField(),
                      const SizedBox(height: 16),
                      _label('Keywords (comma-separated)'),
                      TextFormField(
                        controller: _keywordsCtrl,
                        decoration: const InputDecoration(
                            hintText: 'e.g. machine learning, OCR, summarization',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      _label('Manuscript (PDF, optional)'),
                      _manuscriptRow(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : () => context.go('/faculty/theses'),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                  backgroundColor: CScholarColors.primaryGreen),
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_outlined,
                                      size: 18, color: Colors.white),
                              label: Text(
                                  _submitting
                                      ? 'Submitting…'
                                      : (isEdit ? 'Save Changes' : 'Submit Draft'),
                                  style: const TextStyle(color: Colors.white)),
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
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
            onPressed: () => context.go('/faculty/theses'),
          ),
          title: Text(isEdit ? 'Edit Thesis' : 'New Thesis',
              style: TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Row(
        children: [
          const FacultySidebar(currentPath: '/faculty/thesis/new'),
          Expanded(child: body),
        ],
      ),
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
          data: (list) => DropdownButtonFormField<String>(
            initialValue: _researchType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: list.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _researchType = v),
            validator: (v) => v == null ? 'Select a research type' : null,
          ),
          loading: () => const LinearProgressIndicator(),
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
          data: (list) => DropdownButtonFormField<int>(
            initialValue: _programId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: list.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => setState(() => _programId = v),
            validator: (v) => v == null ? 'Select a program' : null,
          ),
          loading: () => const LinearProgressIndicator(),
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
          data: (list) => DropdownButtonFormField<int>(
            initialValue: _yearId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: list.map((y) => DropdownMenuItem(value: y.id, child: Text(y.label))).toList(),
            onChanged: (v) => setState(() => _yearId = v),
            validator: (v) => v == null ? 'Select an academic year' : null,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Could not load years: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _adviserField() {
    final advisers = ref.watch(advisersProvider);
    final me = ref.watch(currentUserProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Adviser (optional)'),
        advisers.when(
          data: (list) {
            if (!_adviserPreselected && me != null) {
              _adviserPreselected = true;
              for (final a in list) {
                if ((a.email ?? '').toLowerCase() == me.email.toLowerCase()) {
                  _adviserId = a.id;
                  break;
                }
              }
            }
            return DropdownButtonFormField<int>(
              initialValue: _adviserId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'Optional — you are recorded as submitter and will see the draft in My Theses either way.',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ...list.map((a) => DropdownMenuItem(value: a.id, child: Text(a.fullName))),
              ],
              onChanged: (v) => setState(() => _adviserId = v),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Could not load advisers: $e',
              style: const TextStyle(color: CScholarColors.error, fontSize: 12)),
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
          data: (list) => OutlinedButton.icon(
            onPressed: () => _pickMany(
              title: 'Select Authors',
              items: {for (final a in list) a.id: a.fullName},
              selected: _authorIds,
            ),
            icon: const Icon(Icons.people_outline, size: 18),
            label: Text(_authorIds.isEmpty ? 'Choose authors' : '${_authorIds.length} chosen'),
          ),
          loading: () => const LinearProgressIndicator(),
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
          data: (list) => OutlinedButton.icon(
            onPressed: () => _pickMany(
              title: 'Select Categories',
              items: {for (final c in list) c.id: c.name},
              selected: _categoryIds,
            ),
            icon: const Icon(Icons.category_outlined, size: 18),
            label: Text(_categoryIds.isEmpty ? 'Choose categories' : '${_categoryIds.length} chosen'),
          ),
          loading: () => const LinearProgressIndicator(),
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
    return OutlinedButton.icon(
      onPressed: _pickAndUploadPdf,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Attach PDF manuscript'),
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
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 380,
            height: 380,
            child: ListView(
              children: items.entries
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  selected
                    ..clear()
                    ..addAll(temp);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Done'),
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
                adviserId: _adviserId,
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
