// Compact "when" labels for dashboard activity feeds.
//
// The API sends ISO-8601 timestamps, so the feed rows show fresh events in
// minutes, older ones in days, and anything past a week as a plain calendar
// date — keeping the label short enough to sit beside a long thesis title.

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Turns an ISO-8601 timestamp into a short relative label such as `5m ago`,
/// `3h ago`, `2d ago`, or `Mar 4`.
///
/// Returns an empty string for missing or unparseable input so callers can
/// render the label without branching. Future timestamps (clock skew) read as
/// `Just now` rather than a negative age.
String relativeTime(String? iso, {DateTime? now}) {
  if (iso == null || iso.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return '';
  return relativeFrom(parsed, now: now);
}

/// Same as [relativeTime] but for an already-parsed [DateTime].
String relativeFrom(DateTime when, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toLocal();
  final local = when.toLocal();
  final age = current.difference(local);

  if (age.isNegative || age.inSeconds < 60) return 'Just now';
  if (age.inMinutes < 60) return '${age.inMinutes}m ago';
  if (age.inHours < 24) return '${age.inHours}h ago';
  if (age.inDays < 7) return '${age.inDays}d ago';

  final month = _monthNames[local.month - 1];
  return local.year == current.year
      ? '$month ${local.day}'
      : '$month ${local.day}, ${local.year}';
}
