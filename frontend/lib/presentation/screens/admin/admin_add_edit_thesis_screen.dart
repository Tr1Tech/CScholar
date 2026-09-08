// Admin: Add / Edit Thesis form

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';

class AdminAddEditThesisScreen extends ConsumerStatefulWidget {
  final int? thesisId; // null = add mode, non-null = edit mode

  const AdminAddEditThesisScreen({super.key, this.thesisId});

  @override
  ConsumerState<AdminAddEditThesisScreen> createState() => _AdminAddEditThesisScreenState();
}

class _AdminAddEditThesisScreenState extends ConsumerState<AdminAddEditThesisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();

  String? _selectedProgramId;
  String? _selectedYearId;
  String _researchType = 'Thesis';
  String _status = 'published';
  String _adviserFirstName = '';
  String _adviserLastName = '';
  String _adviserTitle = '';
  String _categoryName = '';
  String _keywords = '';

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    super.dispose();
  }

  void _initializeForm(Thesis thesis) {
    if (_isInitialized) return;
    _isInitialized = true;
    _titleCtrl.text = thesis.title;
    _abstractCtrl.text = thesis.abstract;
    _selectedProgramId = thesis.program?.id.toString();
    _selectedYearId = thesis.academicYear?.id.toString();
    _researchType = thesis.researchType;
    _status = thesis.status.isNotEmpty ? thesis.status : 'published';
    if (thesis.advisers?.isNotEmpty == true) {
      final adv = thesis.advisers!.first;
      _adviserFirstName = adv.firstName;
      _adviserLastName = adv.lastName;
      _adviserTitle = adv.designation ?? '';
    }
    if (thesis.categories?.isNotEmpty == true) {
      _categoryName = thesis.categories!.first.name;
    }
    if (thesis.keywords?.isNotEmpty == true) {
      _keywords = thesis.keywords!.map((k) => k.term).join(', ');
    }
  }

  Future<void> _saveThesis() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      ref.invalidate(thesisListProvider(const ThesisListParams()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.thesisId != null ? 'Thesis updated successfully' : 'Thesis added successfully'),
            backgroundColor: CScholarColors.success,
          ),
        );
        context.go('/admin/thesis/management');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: CScholarColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider);
    final years = ref.watch(academicYearsProvider);
    final isEdit = widget.thesisId != null;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (isEdit && !_isInitialized) {
      final thesisAsync = ref.watch(thesisDetailProvider(widget.thesisId!));
      thesisAsync.whenData((thesis) {
        if (thesis != null) _initializeForm(thesis);
      });
    }

    final screen = Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: CScholarColors.textPrimary),
                onPressed: () => context.go('/admin/thesis/management'),
              ),
        title: Text(
          isEdit ? 'Edit Thesis' : 'Add New Thesis',
          style: const TextStyle(color: CScholarColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CScholarColors.dividerLight, height: 1),
        ),
      ),
      body: isEdit
          ? ref.watch(thesisDetailProvider(widget.thesisId!)).when(
              data: (thesis) {
                if (thesis != null) _initializeForm(thesis);
                return _buildForm(programs, years, isWide);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading thesis: $e')),
            )
          : _buildForm(programs, years, isWide),
    );

    if (!isWide) return screen;

    return Row(
      children: [
        AdminSidebar(currentPath: widget.thesisId != null ? '/admin/thesis/${widget.thesisId}/edit' : '/admin/thesis/new'),
        Container(width: 1, color: CScholarColors.dividerLight),
        Expanded(child: screen),
      ],
    );
  }

  Widget _buildForm(AsyncValue<List<Program>> programs, AsyncValue<List<AcademicYear>> years, bool isWide) {
    return Form(
      key: _formKey,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Basic Information'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _titleCtrl,
                          label: 'Title',
                          hint: 'e.g., AI-Based Student Attendance Monitoring System',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _abstractCtrl,
                          label: 'Abstract',
                          hint: 'Enter the research abstract...',
                          maxLines: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Metadata'),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Program',
                          value: _selectedProgramId,
                          items: programs.whenOrNull(data: (list) => list.map((p) => DropdownMenuItem(value: p.id.toString(), child: Text(p.name))).toList()) ?? [],
                          onChanged: (v) => setState(() => _selectedProgramId = v),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Academic Year',
                          value: _selectedYearId,
                          items: years.whenOrNull(data: (list) => list.map((y) => DropdownMenuItem(value: y.id.toString(), child: Text(y.label))).toList()) ?? [],
                          onChanged: (v) => setState(() => _selectedYearId = v),
                        ),
                        const SizedBox(height: 16),
                        _buildSegmented('Research Type', _researchType, {'Thesis': 'Thesis', 'Capstone': 'Capstone'}, (v) => setState(() => _researchType = v)),
                        const SizedBox(height: 16),
                        _buildSegmented('Status', _status, {'published': 'Published', 'draft': 'Draft'}, (v) => setState(() => _status = v)),
                        const SizedBox(height: 24),
                        _sectionTitle('Adviser'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(controller: TextEditingController(text: _adviserFirstName), label: 'First Name', hint: 'Juan', onChanged: (v) => _adviserFirstName = v)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField(controller: TextEditingController(text: _adviserLastName), label: 'Last Name', hint: 'Dela Cruz', onChanged: (v) => _adviserLastName = v)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(controller: TextEditingController(text: _adviserTitle), label: 'Title', hint: 'PhD, MIT', onChanged: (v) => _adviserTitle = v),
                        const SizedBox(height: 24),
                        _sectionTitle('Classification'),
                        const SizedBox(height: 16),
                        _buildTextField(controller: TextEditingController(text: _categoryName), label: 'Category', hint: 'e.g., Machine Learning', onChanged: (v) => _categoryName = v),
                        const SizedBox(height: 12),
                        _buildTextField(controller: TextEditingController(text: _keywords), label: 'Keywords', hint: 'Separate with commas: AI, ML, IoT', onChanged: (v) => _keywords = v),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.go('/admin/thesis/management'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: CScholarColors.dividerLight),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _isLoading ? null : _saveThesis,
                                style: FilledButton.styleFrom(
                                  backgroundColor: CScholarColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(widget.thesisId != null ? 'Update Thesis' : 'Publish Thesis'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _titleCtrl, label: 'Title', hint: 'e.g., AI-Based...', validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _abstractCtrl, label: 'Abstract', hint: 'Enter the research abstract...', maxLines: 5),
                  const SizedBox(height: 24),
                  _sectionTitle('Metadata'),
                  const SizedBox(height: 16),
                  _buildDropdown(label: 'Program', value: _selectedProgramId, items: programs.whenOrNull(data: (list) => list.map((p) => DropdownMenuItem(value: p.id.toString(), child: Text(p.name))).toList()) ?? [], onChanged: (v) => setState(() => _selectedProgramId = v)),
                  const SizedBox(height: 16),
                  _buildDropdown(label: 'Academic Year', value: _selectedYearId, items: years.whenOrNull(data: (list) => list.map((y) => DropdownMenuItem(value: y.id.toString(), child: Text(y.label))).toList()) ?? [], onChanged: (v) => setState(() => _selectedYearId = v)),
                  const SizedBox(height: 16),
                  _buildSegmented('Research Type', _researchType, {'Thesis': 'Thesis', 'Capstone': 'Capstone'}, (v) => setState(() => _researchType = v)),
                  const SizedBox(height: 16),
                  _buildSegmented('Status', _status, {'published': 'Published', 'draft': 'Draft'}, (v) => setState(() => _status = v)),
                  const SizedBox(height: 24),
                  _sectionTitle('Adviser'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: TextEditingController(text: _adviserFirstName), label: 'First Name', hint: 'Juan', onChanged: (v) => _adviserFirstName = v),
                  const SizedBox(height: 12),
                  _buildTextField(controller: TextEditingController(text: _adviserLastName), label: 'Last Name', hint: 'Dela Cruz', onChanged: (v) => _adviserLastName = v),
                  const SizedBox(height: 12),
                  _buildTextField(controller: TextEditingController(text: _adviserTitle), label: 'Title', hint: 'PhD, MIT', onChanged: (v) => _adviserTitle = v),
                  const SizedBox(height: 24),
                  _sectionTitle('Classification'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: TextEditingController(text: _categoryName), label: 'Category', hint: 'e.g., Machine Learning', onChanged: (v) => _categoryName = v),
                  const SizedBox(height: 12),
                  _buildTextField(controller: TextEditingController(text: _keywords), label: 'Keywords', hint: 'Separate with commas', onChanged: (v) => _keywords = v),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveThesis,
                      style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.thesisId != null ? 'Update Thesis' : 'Publish Thesis'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CScholarColors.textPrimary));

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: CScholarColors.textHint),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.dividerLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.dividerLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.primaryGreen, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.error)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.dividerLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CScholarColors.dividerLight)),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmented(String label, String value, Map<String, String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CScholarColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: options.entries.map((e) => ButtonSegment(value: e.key, label: Text(e.value))).toList(),
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return CScholarColors.primaryGreen.withValues(alpha: 0.12);
              return Colors.white;
            }),
          ),
        ),
      ],
    );
  }
}
