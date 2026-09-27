import 'package:flutter/material.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';

/// Faculty topbar: identity pill only (faculty search lives in-page).
///
/// Shares [TopbarUserPill] with the admin bar so the two can never drift apart
/// again — they previously differed in shadow, avatar treatment and fill.
class FacultyTopbar extends StatelessWidget {
  final User? user;
  const FacultyTopbar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Topbar(
      trailing: TopbarUserPill(
        name: user?.username,
        role: 'Faculty',
        fallbackName: 'Faculty',
      ),
    );
  }
}
