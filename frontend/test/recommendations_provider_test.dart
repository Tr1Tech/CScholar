import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/services/api_service.dart';

/// Records the recommendation requests and answers with an empty feed.
class _FakeApi extends ApiService {
  _FakeApi() : super(baseUrl: 'http://test.local');

  final List<Map<String, dynamic>> posts = [];

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == '/api/recommendations') {
      posts.add(Map<String, dynamic>.from(body));
      return <String, dynamic>{
        'personalized': (body['viewed_ids'] as List).isNotEmpty ||
            (body['saved_ids'] as List).isNotEmpty,
        'basis': 'test',
        'items': <dynamic>[],
      };
    }
    return <String, dynamic>{};
  }
}

ProviderContainer _container(_FakeApi api) {
  final container = ProviderContainer(
    overrides: [apiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(recommendationsProvider, (_, _) {});
  addTearDown(sub.close);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('viewing a thesis anchors the feed on it', () async {
    final api = _FakeApi();
    final container = _container(api);

    await container.read(recommendationsProvider.future);
    expect(api.posts.length, 1);
    expect(api.posts.first['viewed_ids'], isEmpty);
    expect(api.posts.first['saved_ids'], isEmpty);

    container.read(recommendationAnchorProvider.notifier)
        .setAnchor(59, 'viewed');
    await container.read(recommendationsProvider.future);

    expect(
      api.posts.length,
      2,
      reason: 'anchoring must trigger a new recommendation request',
    );
    expect(api.posts.last['viewed_ids'], [59]);
    expect(api.posts.last['saved_ids'], isEmpty);
  });

  test('saving a thesis re-anchors the feed on it', () async {
    final api = _FakeApi();
    final container = _container(api);

    await container.read(recommendationsProvider.future);
    expect(api.posts.length, 1);

    container.read(savedThesisIdsProvider.notifier).toggle(46);
    await container.read(recommendationsProvider.future);

    expect(api.posts.length, 2);
    expect(api.posts.last['saved_ids'], [46]);
    expect(api.posts.last['viewed_ids'], isEmpty);
  });

  test('unsaving does not change the anchor', () async {
    final api = _FakeApi();
    final container = _container(api);

    final anchor = container.read(recommendationAnchorProvider.notifier);
    anchor.setAnchor(59, 'viewed');
    container.read(savedThesisIdsProvider.notifier).toggle(46);
    container.read(savedThesisIdsProvider.notifier).toggle(46); // unsave

    expect(container.read(recommendationAnchorProvider)?.kind, 'saved');
    expect(container.read(recommendationAnchorProvider)?.id, 46);
    await container.read(recommendationsProvider.future);
    expect(api.posts.last['saved_ids'], [46]);
  });

  test('a restored anchor is sent with the request', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reco_anchor_id': '59',
      'reco_anchor_kind': 'viewed',
    });
    final api = _FakeApi();
    final container = _container(api);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(recommendationsProvider.future);

    expect(api.posts.last['viewed_ids'], [59]);
  });

  test('a local action wins over a slow prefs restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reco_anchor_id': '43',
      'reco_anchor_kind': 'viewed',
    });
    final api = _FakeApi();
    final container = _container(api);
    final sub = container.listen(recommendationAnchorProvider, (_, _) {});
    addTearDown(sub.close);

    // Act before the restore callback can land.
    container.read(recommendationAnchorProvider.notifier)
        .setAnchor(59, 'viewed');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      container.read(recommendationAnchorProvider)?.id,
      59,
      reason: 'the disk copy must not overwrite a newer local action',
    );
  });
}
