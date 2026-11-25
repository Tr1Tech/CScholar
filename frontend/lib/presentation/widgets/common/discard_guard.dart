import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// Confirms before typed work is thrown away (FRM-17).
///
/// Returns `true` when there is nothing to lose, so callers can write
/// `if (!await confirmDiscardChanges(...)) return;` without branching twice.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required bool hasChanges,
  String? actionLabel,
}) async {
  if (!hasChanges) return true;
  final confirmed = await showClayDialog<bool>(
    context: context,
    builder: (ctx) => GlassDialog(
      title: const Text('Discard your changes?'),
      content: Text(
        actionLabel == null
            ? 'What you typed on this page has not been saved. Leaving now discards it.'
            : 'What you typed on this page has not been saved. Leaving to $actionLabel now discards it.',
      ),
      actions: [
        NeumorphButton(
          onPressed: () => Navigator.pop(ctx, false),
          label: 'Keep editing',
          gel: false,
        ),
        NeumorphButton(
          onPressed: () => Navigator.pop(ctx, true),
          label: 'Discard',
          danger: true,
        ),
      ],
    ),
  );
  return confirmed == true;
}
