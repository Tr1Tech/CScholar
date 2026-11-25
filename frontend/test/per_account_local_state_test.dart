import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';

/// Auth stub that lets a test switch accounts without hitting the API.
class _SwitchableAuth extends AuthNotifier {
  @override
  AsyncValue<User?> build() => const AsyncValue.data(null);

  void signIn(int id) => state = AsyncValue.data(_user(id));

  void signOut() => state = const AsyncValue.data(null);
}

User _user(int id) => User(
  id: id,
  username: 'user$id',
  email: 'user$id@example.com',
  passwordHash: '',
  role: 'student',
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('bookmarks, viewed anchor and searches do not cross accounts', () async {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuth.new)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier) as _SwitchableAuth;

    // Reading each provider triggers its build for the new scope, then the
    // queue lets the (mock) SharedPreferences read land.
    Future<void> settle() async {
      container.read(savedThesisIdsProvider);
      container.read(recommendationAnchorProvider);
      container.read(recentSearchesProvider);
      container.read(viewedThesisIdsProvider);
      await pumpEventQueue();
    }

    // Account A acts on all four pieces of device-local state.
    auth.signIn(1);
    container.read(savedThesisIdsProvider.notifier).toggle(46);
    container
        .read(recommendationAnchorProvider.notifier)
        .setAnchor(59, 'viewed');
    container.read(viewedThesisIdsProvider.notifier).record(59);
    container.read(recentSearchesProvider.notifier).record('machine learning');
    await pumpEventQueue();

    // Logging out must not leave A's state in memory.
    auth.signOut();
    await settle();
    expect(container.read(savedThesisIdsProvider), isEmpty);
    expect(container.read(recommendationAnchorProvider), isNull);
    expect(container.read(recentSearchesProvider), isEmpty);
    expect(container.read(viewedThesisIdsProvider), isEmpty);

    // A brand-new account starts clean instead of inheriting A's activity.
    auth.signIn(2);
    await settle();
    expect(container.read(savedThesisIdsProvider), isEmpty);
    expect(container.read(recommendationAnchorProvider), isNull);
    expect(container.read(recentSearchesProvider), isEmpty);
    expect(container.read(viewedThesisIdsProvider), isEmpty);

    // A's data is still A's when A signs back in.
    auth.signIn(1);
    await settle();
    expect(container.read(savedThesisIdsProvider), {46});
    expect(container.read(recommendationAnchorProvider)?.id, 59);
    expect(container.read(recentSearchesProvider), ['machine learning']);
    expect(container.read(viewedThesisIdsProvider), [59]);
  });

  test('each account persists under its own prefs key', () async {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuth.new)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier) as _SwitchableAuth;

    auth.signIn(7);
    container.read(savedThesisIdsProvider.notifier).toggle(12);
    container.read(recentSearchesProvider.notifier).record('iot');
    await pumpEventQueue();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('saved_thesis_ids:u7'), ['12']);
    expect(prefs.getStringList('recent_search_queries:u7'), ['iot']);
    expect(prefs.getStringList('saved_thesis_ids'), isNull);
    expect(prefs.getStringList('recent_search_queries'), isNull);
  });

  test('viewed history counts distinct studies, newest first', () async {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(_SwitchableAuth.new)],
    );
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier) as _SwitchableAuth;

    auth.signIn(3);
    final viewed = container.read(viewedThesisIdsProvider.notifier);
    viewed.record(11);
    viewed.record(22);
    // Re-opening a study already counted must not inflate the tally.
    viewed.record(11);
    await pumpEventQueue();

    expect(container.read(viewedThesisIdsProvider), [22, 11]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('viewed_thesis_ids:u3'), ['22', '11']);
    expect(prefs.getStringList('viewed_thesis_ids'), isNull);
  });

  test('signed-out state still restores the device-scope keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saved_thesis_ids': ['3'],
      'recent_search_queries': ['graph theory'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(savedThesisIdsProvider);
    container.read(recentSearchesProvider);
    await pumpEventQueue();

    expect(container.read(savedThesisIdsProvider), {3});
    expect(container.read(recentSearchesProvider), ['graph theory']);
  });
}
