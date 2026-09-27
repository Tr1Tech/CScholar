import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/common/cscholar_card.dart';

/// Standard empty panel: icon, headline, one-line guidance, optional action.
/// Replaces every sad blank list/table in the app (design plan, item 4).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return CScholarCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayIconTile(
              icon: icon,
              size: 56,
              gel: false,
              background: CScholarColors.primaryGreenLight,
              tint: CScholarColors.primaryGreen,
            ),
            const SizedBox(height: 16),
            Text(title,
                style: CScholarTextStyles.poppins(16, FontWeight.w700, CScholarColors.textPrimary),
                textAlign: TextAlign.center),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(message!,
                  style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textMuted),
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: CScholarColors.primaryGreen),
                child: Text(actionLabel!, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
