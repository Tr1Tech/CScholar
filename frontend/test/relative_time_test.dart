import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/utils/relative_time.dart';

void main() {
  // Local wall-clock "now" so the assertions do not depend on the machine's
  // UTC offset.
  final now = DateTime(2026, 11, 24, 12);

  String at(Duration ago) => relativeFrom(now.subtract(ago), now: now);

  test('compacts fresh events into minutes, hours and days', () {
    expect(at(const Duration(seconds: 20)), 'Just now');
    expect(at(const Duration(minutes: 5)), '5m ago');
    expect(at(const Duration(hours: 3)), '3h ago');
    expect(at(const Duration(days: 2)), '2d ago');
  });

  test('switches to a calendar date past a week', () {
    expect(relativeFrom(DateTime(2026, 10, 1, 8), now: now), 'Oct 1');
    expect(relativeFrom(DateTime(2025, 10, 1, 8), now: now), 'Oct 1, 2025');
  });

  test('parses ISO strings and clamps future timestamps', () {
    expect(
      relativeTime(DateTime(2026, 11, 24, 9).toIso8601String(), now: now),
      '3h ago',
    );
    expect(relativeTime('2026-11-24T12:00:30', now: now), 'Just now');
  });

  test('drops missing or unparseable timestamps', () {
    expect(relativeTime(null, now: now), '');
    expect(relativeTime('   ', now: now), '');
    expect(relativeTime('not a date', now: now), '');
  });
}
