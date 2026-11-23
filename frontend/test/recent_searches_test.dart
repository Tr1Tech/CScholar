import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/providers/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('records newest first and collapses typing prefixes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recentSearchesProvider.notifier);

    notifier.record('machine');
    notifier.record('machine learning');
    notifier.record(' IoT ');
    notifier.record('machine learning');

    expect(container.read(recentSearchesProvider), ['machine learning', 'IoT']);
  });

  test('keeps the six most recent queries and persists them', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recentSearchesProvider.notifier);

    for (final query in [
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
    ]) {
      notifier.record(query);
    }

    expect(container.read(recentSearchesProvider), [
      'seven',
      'six',
      'five',
      'four',
      'three',
      'two',
    ]);

    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('recent_search_queries'), [
      'seven',
      'six',
      'five',
      'four',
      'three',
      'two',
    ]);
  });

  test('restores the saved list on a cold start', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recent_search_queries': ['graph theory', 'iot'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(recentSearchesProvider);
    await pumpEventQueue();

    expect(container.read(recentSearchesProvider), ['graph theory', 'iot']);
  });

  test('remove and clear update the saved list', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recentSearchesProvider.notifier);

    notifier.record('graph theory');
    notifier.record('iot');
    notifier.remove('graph theory');
    expect(container.read(recentSearchesProvider), ['iot']);

    notifier.clear();
    expect(container.read(recentSearchesProvider), isEmpty);

    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('recent_search_queries'), isEmpty);
  });
}
