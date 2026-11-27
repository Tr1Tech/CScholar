import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';

/// One value in a chart. Kept deliberately small: every analytics card builds
/// these from a count map, so the painters never know about API payloads.
class ChartSlice {
  final String label;
  final int value;
  final Color color;

  const ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Status-style donut: a ring for the distribution, plus a legend with exact
/// numbers. The legend is not decoration — it is the accessible readout.
class DonutChart extends StatelessWidget {
  final List<ChartSlice> slices;
  final String centerLabel;
  final double size;

  const DonutChart({
    super.key,
    required this.slices,
    this.centerLabel = 'total',
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    final visible = slices.where((slice) => slice.value > 0).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(slices: visible, total: total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: CScholarTextStyles.heading(
                      26,
                      FontWeight.w800,
                      CScholarColors.textPrimary,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: CScholarTextStyles.body(
                      10.5,
                      FontWeight.w600,
                      CScholarColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final legend = _Legend(slices: visible, total: total);
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              chart,
              const SizedBox(height: 16),
              legend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chart,
            const SizedBox(width: 20),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final List<ChartSlice> slices;
  final int total;

  const _Legend({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Text(
        'No data yet',
        style: CScholarTextStyles.body(
          12,
          FontWeight.w400,
          CScholarColors.textMuted,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: slice.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.body(
                      12,
                      FontWeight.w500,
                      CScholarColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${slice.value}'
                  '${total == 0 ? '' : ' · ${(slice.value * 100 / total).round()}%'}',
                  style: CScholarTextStyles.body(
                    12,
                    FontWeight.w700,
                    CScholarColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ChartSlice> slices;
  final int total;

  const _DonutPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.min(size.width, size.height) * 0.16;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = CScholarMaterial.clayDeep;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total == 0) return;
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    for (final slice in slices) {
      final sweep = math.pi * 2 * slice.value / total;
      paint.color = slice.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}

/// Horizontal bars for a ranked breakdown (programs, top queries).
class AnalyticsBars extends StatelessWidget {
  final List<ChartSlice> slices;
  final String emptyMessage;
  final int maxRows;

  const AnalyticsBars({
    super.key,
    required this.slices,
    this.emptyMessage = 'No data yet',
    this.maxRows = 8,
  });

  @override
  Widget build(BuildContext context) {
    final rows = slices.where((slice) => slice.value > 0).take(maxRows).toList();
    if (rows.isEmpty) {
      return Text(
        emptyMessage,
        style: CScholarTextStyles.body(
          12,
          FontWeight.w400,
          CScholarColors.textMuted,
        ),
      );
    }
    final maxValue = rows.fold<int>(1, (max, row) => math.max(max, row.value));
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.body(
                          12,
                          FontWeight.w600,
                          CScholarColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${row.value}',
                      style: CScholarTextStyles.body(
                        12,
                        FontWeight.w700,
                        CScholarColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(CScholarRadius.full),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(color: CScholarMaterial.clayDeep),
                        FractionallySizedBox(
                          widthFactor: row.value / maxValue,
                          child: Container(color: row.color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Vertical bars for an ordered series (academic years).
class ColumnChart extends StatelessWidget {
  final List<ChartSlice> slices;
  final double height;

  const ColumnChart({
    super.key,
    required this.slices,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final rows = slices.where((slice) => slice.value > 0).toList();
    if (rows.isEmpty) {
      return Text(
        'No data yet',
        style: CScholarTextStyles.body(
          12,
          FontWeight.w400,
          CScholarColors.textMuted,
        ),
      );
    }
    final maxValue = rows.fold<int>(1, (max, row) => math.max(max, row.value));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final row in rows)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${row.value}',
                      style: CScholarTextStyles.body(
                        11,
                        FontWeight.w700,
                        CScholarColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: row.value / maxValue,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 4),
                          decoration: BoxDecoration(
                            color: row.color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(CScholarRadius.sm),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: CScholarTextStyles.body(
                        10,
                        FontWeight.w500,
                        CScholarColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
