import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// Compact inline failure with a retry action (STA-4).
///
/// For a loader that feeds one field or one panel — a program picker, a roster
/// side card — a full [EmptyState] is too heavy, but a bare "Could not load"
/// text is a dead end (CNT-3). This is the smallest unit that still tells the
/// user what happened and offers the way out.
class InlineRetry extends StatelessWidget {
  const InlineRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: CScholarTextStyles.body(
              12,
              FontWeight.w500,
              CScholarColors.error,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}
