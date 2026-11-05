import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';

/// Admin topbar: the search for whichever list the page is showing, plus the
/// admin identity pill.
///
/// The field writes to [adminSearchProvider] for [section] (debounced) and that
/// page reads the same section back — the bar lives in the shell, above the
/// page, so shared state is the only way the two can meet.
class AdminTopbar extends ConsumerStatefulWidget {
  /// The list this bar filters. Null on pages with nothing to filter
  /// (dashboard, settings, the thesis editor): a well whose text lands on a
  /// list you cannot see is worse than no well at all.
  final AdminSearchSection? section;

  const AdminTopbar({super.key, this.section});

  /// Shown in the field, per list. Phrased as what it searches, because the
  /// bar outlives the page and the hint is the only thing naming the target.
  static String hintFor(AdminSearchSection section) {
    switch (section) {
      case AdminSearchSection.theses:
        return 'Search the thesis table...';
      case AdminSearchSection.users:
        return 'Search users by name or email...';
      case AdminSearchSection.programs:
        return 'Search programs, years, or categories...';
    }
  }

  @override
  ConsumerState<AdminTopbar> createState() => _AdminTopbarState();
}

class _AdminTopbarState extends ConsumerState<AdminTopbar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final section = widget.section;
    if (section != null) {
      _controller.text = ref.read(adminSearchProvider(section));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _write(String value) {
    final section = widget.section;
    if (section == null) return;
    _debounce?.cancel();
    _debounce = Timer(CScholarDurations.debounce, () {
      if (!mounted) return;
      ref.read(adminSearchProvider(section).notifier).setQuery(value.trim());
    });
  }

  void _clear() {
    final section = widget.section;
    if (section == null) return;
    _debounce?.cancel();
    _controller.clear();
    ref.read(adminSearchProvider(section).notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final section = widget.section;
    final query = section == null
        ? ''
        : ref.watch(adminSearchProvider(section));

    return Topbar(
      leading: section == null
          ? null
          : TopbarSearchField(
              controller: _controller,
              hintText: AdminTopbar.hintFor(section),
              onChanged: _write,
              onSubmitted: (v) {
                _debounce?.cancel();
                ref
                    .read(adminSearchProvider(section).notifier)
                    .setQuery(v.trim());
              },
              onClear: query.isEmpty ? null : _clear,
            ),
      trailing: TopbarUserPill(
        name: user?.username,
        role: 'Administrator',
        fallbackName: 'Admin',
      ),
    );
  }
}
