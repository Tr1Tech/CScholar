import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/services/api_service.dart';

/// Creates a student author without leaving the thesis form.
///
/// Both forms used to require the student to already exist in `/api/authors`,
/// and authors are only created by an admin or the importer. A new student had
/// no path in at all. The server de-duplicates by email or full name, so a
/// retry (or two staff entering the same student) returns the existing row
/// instead of splitting that student's history across duplicates.
Future<Author?> showNewAuthorDialog(BuildContext context) {
  return showClayDialog<Author>(
    context: context,
    builder: (_) => const _NewAuthorDialog(),
  );
}

class _NewAuthorDialog extends ConsumerStatefulWidget {
  const _NewAuthorDialog();

  @override
  ConsumerState<_NewAuthorDialog> createState() => _NewAuthorDialogState();
}

class _NewAuthorDialogState extends ConsumerState<_NewAuthorDialog> {
  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = await ref.read(apiServiceProvider).post('/api/authors', {
        'first_name': first,
        'last_name': last,
        if (_middleCtrl.text.trim().isNotEmpty)
          'middle_name': _middleCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      });
      final author = Author.fromJson(Map<String, dynamic>.from(data as Map));
      ref.invalidate(authorsProvider);
      if (mounted) Navigator.pop(context, author);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _friendly(e);
        });
      }
    }
  }

  String _friendly(Object error) {
    final raw = error is ApiException ? error.message : error.toString();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {
      // Fall through to the raw message.
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: const Text('New Author'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add the student to the repository and select them for this '
                'study. An existing student with the same name or email is '
                'reused instead of duplicated.',
                style: CScholarTextStyles.body(
                  12,
                  FontWeight.w400,
                  CScholarColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              NeumorphField(controller: _firstCtrl, label: 'First name *'),
              const SizedBox(height: 12),
              NeumorphField(controller: _middleCtrl, label: 'Middle name'),
              const SizedBox(height: 12),
              NeumorphField(controller: _lastCtrl, label: 'Last name *'),
              const SizedBox(height: 12),
              NeumorphField(
                controller: _emailCtrl,
                label: 'Email (optional)',
                keyboardType: TextInputType.emailAddress,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w500,
                    CScholarColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        NeumorphButton(
          label: 'Cancel',
          gel: false,
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        NeumorphButton(
          label: _saving ? 'Saving...' : 'Add author',
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
