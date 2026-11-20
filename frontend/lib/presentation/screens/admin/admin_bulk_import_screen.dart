// Admin: Bulk Import — CSV + PDFs -> validation preview -> draft import.
//
// The screen is deliberately step-shaped: a librarian should always know what
// to do next. Nothing is written until "Import" is pressed, and imported
// studies arrive as drafts so a bad batch is invisible to students.

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/presentation/widgets/admin_topbar.dart';
import 'package:frontend/presentation/widgets/common/app_shell.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/services/api_service.dart';

class AdminBulkImportScreen extends ConsumerStatefulWidget {
  const AdminBulkImportScreen({super.key});

  @override
  ConsumerState<AdminBulkImportScreen> createState() =>
      _AdminBulkImportScreenState();
}

class _AdminBulkImportScreenState extends ConsumerState<AdminBulkImportScreen> {
  PlatformFile? _csv;
  final List<PlatformFile> _pdfs = [];
  ImportJob? _preview;
  ImportJob? _job;
  Timer? _poll;
  bool _checking = false;
  bool _starting = false;
  bool _polling = false;
  bool _downloading = false;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose the metadata CSV',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null || !mounted) return;
    setState(() {
      _csv = file;
      _preview = null;
      _job = null;
      _error = null;
    });
  }

  Future<void> _pickPdfs() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Choose the PDF manuscripts',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isEmpty || !mounted) return;
    setState(() {
      _pdfs
        ..clear()
        ..addAll(files);
      _preview = null;
      _job = null;
      _error = null;
    });
  }

  Future<void> _checkBatch() async {
    if (_csv == null || _pdfs.isEmpty || _checking) return;
    // Re-checking replaces the previous preview; drop its staged files so a
    // librarian refining a CSV does not leave old batches on disk.
    final previous = _preview;
    if (previous != null && previous.isPreview) {
      try {
        await ref.read(importApiProvider).discard(previous.id);
      } catch (_) {
        // Non-fatal: the new preview is what matters.
      }
    }
    if (!mounted) return;
    setState(() {
      _checking = true;
      _error = null;
      _preview = null;
      _job = null;
    });
    try {
      final preview = await ref
          .read(importApiProvider)
          .preview(_csv!, _pdfs);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _startImport() async {
    final preview = _preview;
    if (preview == null || _starting) return;
    final count = preview.readyCount + preview.updateCount;
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: const Text('Import this batch?'),
        content: Text(
          'Import $count studies as drafts. They will not appear in the public '
          'repository until you review and publish them.',
        ),
        actions: [
          NeumorphButton(
            label: 'Cancel',
            gel: false,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          NeumorphButton(
            label: 'Import as drafts',
            icon: Icons.library_add_outlined,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await ref.read(importApiProvider).run(preview.id);
      if (!mounted) return;
      setState(() => _job = job);
      _startPolling(job.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _startPolling(int jobId) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_polling) return;
      _polling = true;
      try {
        final job = await ref.read(importApiProvider).status(jobId);
        if (!mounted) return;
        setState(() => _job = job);
        if (job.isFinished) _poll?.cancel();
      } catch (_) {
        // A transient poll failure should not kill the screen; the next tick
        // tries again.
      } finally {
        _polling = false;
      }
    });
  }

  Future<void> _downloadReport() async {
    final job = _job ?? _preview;
    if (job == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(importApiProvider).reportBytes(job.id);
      await FilePicker.saveFile(
        fileName: 'import_report_${job.id}.csv',
        bytes: bytes,
        mimeType: 'text/csv',
        dialogTitle: 'Save the import report',
      );
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final bytes = await ref.read(importApiProvider).templateBytes();
      await FilePicker.saveFile(
        fileName: 'cscholar_import_template.csv',
        bytes: bytes,
        mimeType: 'text/csv',
        dialogTitle: 'Save the CSV template',
      );
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _discardPreview() async {
    final preview = _preview;
    if (preview == null) return;
    try {
      await ref.read(importApiProvider).discard(preview.id);
    } catch (_) {
      // The preview is local state; a failed cleanup must not trap the user.
    }
    if (!mounted) return;
    setState(() {
      _preview = null;
      _job = null;
      _error = null;
    });
  }

  Future<void> _retry(int jobId) async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await ref.read(importApiProvider).run(jobId);
      if (!mounted) return;
      setState(() => _job = job);
      _startPolling(job.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _reset() async {
    // A previewed or failed job still owns a staging folder. A completed job
    // has already had its files removed and is kept as history.
    final staleId = (_job == null)
        ? _preview?.id
        : (_job!.status == 'failed' ? _job!.id : null);
    if (staleId != null) {
      try {
        await ref.read(importApiProvider).discard(staleId);
      } catch (_) {
        // Non-fatal: the next batch can proceed regardless.
      }
    }
    _poll?.cancel();
    if (!mounted) return;
    setState(() {
      _csv = null;
      _pdfs.clear();
      _preview = null;
      _job = null;
      _error = null;
    });
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      try {
        final decoded = jsonDecode(error.message);
        if (decoded is Map && decoded['detail'] is String) {
          return decoded['detail'] as String;
        }
      } catch (_) {
        // Fall through to the raw exception.
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return CScholarShell(
      // Bulk Import is a sub-flow of the thesis collection, not a peer
      // destination: keep "Theses / Capstone" highlighted while it runs.
      sidebar: const AdminSidebar(currentPath: '/admin/thesis/management'),
      topbar: const AdminTopbar(),
      mobileTitle: 'Bulk Import',
      backRoute: '/admin/thesis/management',
      maxWidth: 1120,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntranceReveal(
              child: PageHeader(
                title: 'Bulk Import',
                subtitle:
                    'Add a batch of studies from a spreadsheet and a folder of PDFs. '
                    'Nothing goes live until you publish it.',
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              _ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
              const SizedBox(height: 16),
            ],
            _introCard(),
            const SizedBox(height: 16),
            _filesCard(),
            if (_preview != null && job == null) ...[
              const SizedBox(height: 16),
              _previewCard(_preview!),
            ],
            if (job != null) ...[
              const SizedBox(height: 16),
              _jobCard(job),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return CScholarCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Prepare the batch'),
          const SizedBox(height: 6),
          Text(
            'One row per study in the CSV. The value in pdf_filename must match '
            'the PDF you upload. Authors use Last, First M. (for example: Dela Cruz, Juan P.).',
            style: CScholarTextStyles.body(
              13,
              FontWeight.w400,
              CScholarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              NeumorphButton(
                label: 'Download CSV template',
                icon: Icons.download_outlined,
                gel: false,
                onPressed: _downloadTemplate,
              ),
              Text(
                'Works in Excel or Google Sheets.',
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w400,
                  CScholarColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filesCard() {
    final pdfLabel = _pdfs.isEmpty
        ? 'No PDFs selected'
        : '${_pdfs.length} PDF${_pdfs.length == 1 ? '' : 's'} selected';
    return CScholarCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('2. Choose the files'),
          const SizedBox(height: 6),
          Text(
            'Select the CSV first, then all PDFs that belong to that batch.',
            style: CScholarTextStyles.body(
              13,
              FontWeight.w400,
              CScholarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _fileSlot(
            icon: Icons.description_outlined,
            label: _csv?.name ?? 'No CSV selected',
            detail: _csv == null ? 'The spreadsheet with one row per study' : 'CSV ready',
            buttonLabel: _csv == null ? 'Choose CSV' : 'Change CSV',
            onPressed: _pickCsv,
          ),
          const SizedBox(height: 12),
          _fileSlot(
            icon: Icons.picture_as_pdf_outlined,
            label: pdfLabel,
            detail: _pdfs.isEmpty
                ? 'Select all manuscripts for this batch'
                : _pdfs.take(4).map((f) => f.name).join(', ') +
                      (_pdfs.length > 4 ? ' and ${_pdfs.length - 4} more' : ''),
            buttonLabel: _pdfs.isEmpty ? 'Choose PDFs' : 'Change PDFs',
            onPressed: _pickPdfs,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              NeumorphButton(
                label: _checking ? 'Checking…' : 'Check batch',
                icon: _checking ? null : Icons.fact_check_outlined,
                loading: _checking,
                onPressed: (_csv == null || _pdfs.isEmpty || _checking)
                    ? null
                    : _checkBatch,
              ),
              if (_preview != null) ...[
                const SizedBox(width: 10),
                NeumorphButton(
                  label: 'Discard preview',
                  gel: false,
                  onPressed: _discardPreview,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fileSlot({
    required IconData icon,
    required String label,
    required String detail,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CScholarMaterial.clayDeep,
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Row(
            children: [
              Icon(icon, size: 22, color: CScholarColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.body(
                        13,
                        FontWeight.w600,
                        CScholarColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.body(
                        11.5,
                        FontWeight.w400,
                        CScholarColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = NeumorphButton(
            label: buttonLabel,
            gel: false,
            onPressed: onPressed,
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 10), button],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _previewCard(ImportJob preview) {
    final canImport = preview.invalidCount == 0 &&
        (preview.readyCount + preview.updateCount) > 0;
    return CScholarCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('3. Review before importing'),
          const SizedBox(height: 6),
          Text(
            preview.errorCount > 0
                ? 'Fix the rows marked Error in the CSV, then upload again. '
                      'Nothing has been saved.'
                : 'These rows are ready. Nothing has been saved yet.',
            style: CScholarTextStyles.body(
              13,
              FontWeight.w400,
              CScholarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _countChip('${preview.readyCount} ready', CScholarColors.primaryGreen),
              if (preview.updateCount > 0)
                _countChip('${preview.updateCount} will update', CScholarColors.violetInk),
              if (preview.alreadyCount > 0)
                _countChip('${preview.alreadyCount} already imported', CScholarColors.textMuted),
              if (preview.invalidCount > 0)
                _countChip('${preview.invalidCount} errors', CScholarColors.error),
            ],
          ),
          const SizedBox(height: 14),
          // The row layout needs ~900px to stay readable. On a narrow window
          // it scrolls sideways instead of crushing five columns.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                children: [
                  _previewHeader(),
                  const Divider(height: 1),
                  for (final row in preview.rows) _previewRow(row),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              NeumorphButton(
                label: _starting
                    ? 'Starting…'
                    : 'Import ${preview.readyCount + preview.updateCount} studies as drafts',
                icon: _starting ? null : Icons.library_add_outlined,
                loading: _starting,
                onPressed: canImport && !_starting ? _startImport : null,
              ),
              NeumorphButton(
                label: 'Download preview',
                icon: Icons.download_outlined,
                gel: false,
                onPressed: _downloading ? null : _downloadReport,
              ),
            ],
          ),
          if (!canImport) ...[
            const SizedBox(height: 8),
            Text(
              preview.invalidCount > 0
                  ? 'Import is disabled while any row has an error.'
                  : 'There are no new rows to import in this batch.',
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 106, child: _headerLabel('Status')),
          SizedBox(width: 42, child: _headerLabel('Row')),
          Expanded(flex: 4, child: _headerLabel('Study')),
          Expanded(flex: 2, child: _headerLabel('Program / Year')),
          Expanded(flex: 2, child: _headerLabel('Message')),
        ],
      ),
    );
  }

  Widget _previewRow(ImportRow row) {
    final style = _rowStyle(row);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CScholarMaterial.rim, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 106, child: _statusPill(row.statusLabel, style)),
          SizedBox(
            width: 42,
            child: Text(
              '${row.row}',
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                    12.5,
                    FontWeight.w600,
                    CScholarColors.textPrimary,
                  ),
                ),
                if (row.authors.isNotEmpty)
                  Text(
                    row.authors,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.body(
                      11,
                      FontWeight.w400,
                      CScholarColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.programCode} · ${row.academicYear}\n${row.pdfFilename}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                11,
                FontWeight.w400,
                CScholarColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CScholarTextStyles.body(
                11,
                FontWeight.w400,
                row.hasError ? CScholarColors.error : CScholarColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(ImportJob job) {
    if (job.isRunning) {
      return CScholarCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Importing…'),
            const SizedBox(height: 8),
            Text(
              '${job.processedRows} of ${job.totalRows} rows processed. '
              'Keep this page open; indexing runs in the background.',
              style: CScholarTextStyles.body(
                13,
                FontWeight.w400,
                CScholarColors.textSecondary,
              ),
            ),
            if (job.message != null) ...[
              const SizedBox(height: 6),
              Text(
                job.message!,
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w500,
                  CScholarColors.primaryGreen,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (job.progress == 0)
              const ClayLoader(height: 8)
            else
              ClayProgressBar(value: job.progress, height: 8),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _countChip('${job.createdCount} created', CScholarColors.primaryGreen),
                if (job.updatedCount > 0)
                  _countChip('${job.updatedCount} updated', CScholarColors.violetInk),
                if (job.skippedCount > 0)
                  _countChip('${job.skippedCount} skipped', CScholarColors.textMuted),
                if (job.indexedCount > 0)
                  _countChip('${job.indexedCount} indexed', CScholarColors.primaryGreen),
                if (job.errorCount > 0)
                  _countChip('${job.errorCount} errors', CScholarColors.error),
              ],
            ),
          ],
        ),
      );
    }

    final completed = job.status == 'completed';
    return CScholarCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle_outline : Icons.error_outline,
                color: completed ? CScholarColors.primaryGreen : CScholarColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  completed ? 'Import complete' : 'Import failed',
                  style: CScholarTextStyles.body(
                    16,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completed
                ? '${job.createdCount} created, ${job.updatedCount} updated, '
                      '${job.skippedCount} skipped'
                      '${job.errorCount > 0 ? ', ${job.errorCount} failed' : ''}. '
                      '${job.indexedCount} studies are ready for semantic search. '
                      'They are still drafts until you publish them.'
                : (job.message ?? 'The batch could not be completed.'),
            style: CScholarTextStyles.body(
              13,
              FontWeight.w400,
              CScholarColors.textSecondary,
            ),
          ),
          if (job.message != null && completed) ...[
            const SizedBox(height: 8),
            Text(
              job.message!,
              style: CScholarTextStyles.body(
                12,
                FontWeight.w500,
                CScholarColors.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              NeumorphButton(
                label: 'Download report',
                icon: Icons.download_outlined,
                gel: false,
                onPressed: _downloading ? null : _downloadReport,
              ),
              if (completed)
                NeumorphButton(
                  label: 'Review drafts',
                  icon: Icons.article_outlined,
                  onPressed: () => context.go('/admin/thesis/management'),
                )
              else
                NeumorphButton(
                  label: _starting ? 'Starting…' : 'Try again',
                  icon: _starting ? null : Icons.refresh,
                  loading: _starting,
                  onPressed: _starting ? null : () => _retry(job.id),
                ),
              NeumorphButton(
                label: 'Import another batch',
                gel: false,
                onPressed: _reset,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: CScholarTextStyles.body(15, FontWeight.w700, CScholarColors.textPrimary),
  );

  Widget _headerLabel(String text) => Text(
    text.toUpperCase(),
    style: CScholarTextStyles.body(
      10.5,
      FontWeight.w700,
      CScholarColors.textMuted,
      letterSpacing: 0.5,
    ),
  );

  Widget _countChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CScholarRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: CScholarTextStyles.body(11.5, FontWeight.w600, color),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CScholarRadius.full),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CScholarTextStyles.body(10.5, FontWeight.w700, color),
      ),
    );
  }

  Color _rowStyle(ImportRow row) {
    if (row.hasError) return CScholarColors.error;
    switch (row.action) {
      case 'would_create':
      case 'created':
        return CScholarColors.primaryGreen;
      case 'would_update':
      case 'updated':
        return CScholarColors.violetInk;
      default:
        return CScholarColors.textMuted;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CScholarColors.errorLight,
        borderRadius: BorderRadius.circular(CScholarRadius.lg),
        border: Border.all(color: CScholarColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: CScholarColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: CScholarTextStyles.body(
                12.5,
                FontWeight.w500,
                CScholarColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: CScholarColors.error,
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
