import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/topbar.dart';

/// Admin topbar: thesis-table search + admin identity pill.
///
/// The search writes to [adminThesisSearchProvider] (debounced) and the thesis
/// management list filters live — admins never leave the page.
class AdminTopbar extends ConsumerStatefulWidget {
  const AdminTopbar({super.key});

  @override
  ConsumerState<AdminTopbar> createState() => _AdminTopbarState();
}

class _AdminTopbarState extends ConsumerState<AdminTopbar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(adminThesisSearchProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(CScholarDurations.debounce, () {
      if (!mounted) return;
      ref.read(adminThesisSearchProvider.notifier).setQuery(v.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(adminThesisSearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final query = ref.watch(adminThesisSearchProvider);

    return Topbar(
      leading: TopbarSearchField(
        controller: _controller,
        hintText: 'Search the thesis table...',
        onChanged: _onChanged,
        onSubmitted: (v) {
          _debounce?.cancel();
          ref.read(adminThesisSearchProvider.notifier).setQuery(v.trim());
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
