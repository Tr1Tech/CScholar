import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';

/// Rows per page for every admin table. One constant so Users, Theses and the
/// Programs tabs can never disagree about what "a page" is.
const int kAdminTablePageSize = 10;

/// Clamps a 0-based page index to the pages that actually exist for [total]
/// rows. A filter or search that shrinks the list silently lands the table on
/// its last valid page instead of a blank one.
int clampPageIndex(int page, int total, {int pageSize = kAdminTablePageSize}) {
  if (total <= 0) return 0;
  final lastPage = ((total - 1) ~/ pageSize).clamp(0, 1 << 30);
  return page.clamp(0, lastPage);
}

/// Table footer: "Showing 1–10 of 57" with the same clay chevron pager the
/// dashboard's activity feed uses, so the two pagers read as one control.
///
/// A single page renders nothing — a pager that only ever says "Page 1 of 1"
/// is chrome, not navigation.
class ClayPagination extends StatelessWidget {
  const ClayPagination({
    super.key,
    required this.page,
    required this.total,
    required this.onPageChanged,
    this.pageSize = kAdminTablePageSize,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  /// 1-based current page.
  final int page;
  final int total;
  final ValueChanged<int> onPageChanged;
  final int pageSize;
  final EdgeInsetsGeometry padding;

  int get _totalPages => total <= 0 ? 1 : ((total - 1) ~/ pageSize) + 1;

  @override
  Widget build(BuildContext context) {
    if (total <= pageSize) return const SizedBox.shrink();

    final current = page.clamp(1, _totalPages);
    final first = (current - 1) * pageSize + 1;
    final last = math.min(current * pageSize, total);
    final style = CScholarTextStyles.body(
      12,
      FontWeight.w600,
      CScholarColors.textMuted,
    );
    final canGoBack = current > 1;
    final canGoForward = current < _totalPages;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $first–$last of $total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          NeumorphIconButton(
            icon: Icons.chevron_left,
            size: 36,
            tooltip: 'Previous page',
            color: canGoBack
                ? CScholarColors.textPrimary
                : CScholarColors.textHint,
            onPressed: canGoBack ? () => onPageChanged(current - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Page $current of $_totalPages', style: style),
          ),
          NeumorphIconButton(
            icon: Icons.chevron_right,
            size: 36,
            tooltip: 'Next page',
            color: canGoForward
                ? CScholarColors.textPrimary
                : CScholarColors.textHint,
            onPressed: canGoForward ? () => onPageChanged(current + 1) : null,
          ),
        ],
      ),
    );
  }
}
