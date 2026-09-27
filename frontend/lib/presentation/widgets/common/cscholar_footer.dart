import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/common/csu_mark.dart';

/// Shared CEIT identity footer for scrollable content pages
/// (design plan, item 5 in the phase-3 additions).
class CScholarFooter extends StatelessWidget {
  const CScholarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CScholarColors.borderLight)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const CSUIdentity(),
              Text(
                'College of Engineering and Information Technology • Caraga State University',
                style: CScholarTextStyles.inter(
                    11.5, FontWeight.w400, CScholarColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
