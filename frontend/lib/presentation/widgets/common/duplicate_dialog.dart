import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/services/api_service.dart';

/// One row from the backend soft-duplicate guard
/// (`POST /api/theses` → 409 `possible_duplicates`).
class DuplicateCandidate {
  final int id;
  final String title;
  final String status;
  final String matchType;

  const DuplicateCandidate({
    required this.id,
    required this.title,
    required this.status,
    required this.matchType,
  });

  factory DuplicateCandidate.fromJson(Map<String, dynamic> json) =>
      DuplicateCandidate(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? 'Untitled',
        status: (json['status'] as String?) ?? 'draft',
        matchType: (json['match_type'] as String?) ?? 'exact_title',
      );

  /// Human label for the match — same wording on faculty + admin screens.
  String get matchLabel => matchType == 'exact_title_and_abstract'
      ? 'Same title + abstract'
      : 'Same title';
}

/// Extract `possible_duplicates` from a 409 [ApiException].
/// Returns empty when the error is anything else (network, validation…).
List<DuplicateCandidate> parseDuplicateCandidates(Object error) {
  if (error is! ApiException || error.statusCode != 409) return [];
  try {
    final body = jsonDecode(error.message) as Map<String, dynamic>;
    final list = body['possible_duplicates'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(DuplicateCandidate.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

/// Shared confirm dialog — one design for faculty + admin submit flows.
///
/// Uses the app's dialog shell ([GlassDialog] via [showClayDialog]), the
/// amber draft-chip palette for the warning banner, and [ThesisStatusChip]
/// per row so statuses read exactly like everywhere else.
Future<bool> showDuplicateConfirmDialog(
  BuildContext context,
  List<DuplicateCandidate> candidates,
) async {
  final result = await showClayDialog<bool>(
    context: context,
    // Cap the shell: the title's Expanded would otherwise stretch the
    // dialog to the full inset width and leave dead space beside a
    // fixed-width content column (plus squeeze the action buttons).
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CScholarColors.adminLight,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
              border: Border.all(color: CScholarMaterial.rimDraft),
            ),
            child: Icon(
              Icons.warning_amber_outlined,
              size: 20,
              color: CScholarColors.warningFg,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Possible duplicate found',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CScholarColors.adminLight,
              borderRadius: BorderRadius.circular(CScholarRadius.md),
              border: Border.all(color: CScholarMaterial.rimDraft),
            ),
            child: Text(
              'A thesis with the same title already exists. '
              'Same titles are allowed when the study is different — '
              'submit anyway only if this is not a copy.',
              style: CScholarTextStyles.body(
                  12.5, FontWeight.w500, CScholarColors.warningFg),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < candidates.length; i++)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: i == candidates.length - 1 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: CScholarMaterial.clayDeep,
                        borderRadius:
                            BorderRadius.circular(CScholarRadius.md),
                        border:
                            Border.all(color: CScholarMaterial.rim),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidates[i].title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CScholarTextStyles.body(13,
                                      FontWeight.w600,
                                      CScholarColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${candidates[i].id} • ${candidates[i].matchLabel}',
                                  style: CScholarTextStyles.body(
                                      11.5,
                                      FontWeight.w500,
                                      CScholarColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ThesisStatusChip(candidates[i].status),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Stacked full-width: the shared action row can't fit two wide
          // buttons in a 480 dialog (it overflows past ~350px of content
          // width, and truncates the confirm label). Same shell and same
          // controls, just laid out so nothing can squeeze or clip —
          // including at 200% text scale.
          const SizedBox(height: 16),
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, false),
            label: 'Cancel',
            gel: false,
            expand: true,
          ),
          const SizedBox(height: 8),
          NeumorphButton(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Submit anyway',
            icon: Icons.send_outlined,
            expand: true,
          ),
        ],
      ),
        ),
      ),
    ),
  );
  return result == true;
}
