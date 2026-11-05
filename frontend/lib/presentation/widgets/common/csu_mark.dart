import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// The single CSU brand mark (matches the identity block):
/// solid green rounded square with a white mortarboard.
/// All brand/identity instances use this — never ad-hoc icon boxes.
class CSUMark extends StatelessWidget {
  final double size;
  final double iconScale;

  const CSUMark({super.key, this.size = 36, this.iconScale = 0.62});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CScholarColors.primaryGreen,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(Icons.school,
          size: size * iconScale, color: Colors.white),
    );
  }
}

/// CSU lockup: mark + "Caraga State University" / "CEIT Department".
class CSUIdentity extends StatelessWidget {
  final double markSize;
  final bool compact;

  const CSUIdentity({super.key, this.markSize = 34, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CSUMark(size: markSize),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Caraga State University',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CScholarTextStyles.body(
                      compact ? 11.5 : 12.5,
                      FontWeight.w700,
                      CScholarColors.textPrimary)),
              if (!compact)
                Text('CEIT Department',
                    style: CScholarTextStyles.body(11,
                        FontWeight.w400, CScholarColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
