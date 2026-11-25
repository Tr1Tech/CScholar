// Riverpod 3.x state management (modern Notifier API — no code generation)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// All data shown in the UI comes from the backend API — there is no local
// sample/seed data anywhere in the app.

// ─── API Service provider (production HTTP client) ───────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) {
  final api = ApiService();
  // A 401 from any authenticated call ends the session centrally: the token is
  // dropped and the router redirects to sign-in. Screens then show a normal
  // "session expired" message instead of ApiException(401) (TRU-4).
  api.onUnauthorized = () {
    ref.read(authProvider.notifier).sessionExpired();
  };
  return api;
});

// ─── Auth API provider ────────────────────────────────────────────────────────
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.read(apiServiceProvider)),
);

// Auth state using Notifier (Riverpod 3.x — simple and clean)
final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  () => AuthNotifier(),
);

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  AuthApi get _authApi => ref.read(authApiProvider);

  @override
  AsyncValue<User?> build() => const AsyncValue.data(null);

  User? get user => state.value;
  bool get isAuthenticated => state.value != null;
  bool get isStudent => state.value?.role == 'student';
  bool get isFaculty => state.value?.role == 'faculty';
  bool get isAdmin => state.value?.role == 'admin';

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Call real API
      final token = await _authApi.login(email, password);
      // Store token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      ref.read(apiServiceProvider).setToken(token);
      // Get user profile
      final userData = await _authApi.me();
      final user = User(
        id: userData['id'] as int,
        username: userData['username'] as String,
        email: userData['email'] as String,
        passwordHash: '',
        role: userData['role'] as String,
        isActive: userData['is_active'] as bool? ?? true,
        createdAt:
            DateTime.tryParse(userData['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Changes this account's password and adopts the replacement token.
  ///
  /// The password change rotates the server-side fingerprint, so every token
  /// issued before it stops working. Swapping in the new token here is what
  /// keeps this device signed in while other sessions drop out.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _authApi.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    ref.read(apiServiceProvider).setToken(token);
    // [state] is deliberately untouched: the user did not change, and
    // notifying the router would only bounce them off the current page.
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ref.read(apiServiceProvider).clearToken();
    state = const AsyncValue.data(null);
  }

  /// The server rejected this session's token (expired, revoked by a password
  /// change, or account deactivated). Keep the app honest: drop the local
  /// session so the router lands on sign-in, without a raw 401 on screen.
  Future<void> sessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {
      // Best-effort: the in-memory session is still cleared below.
    }
    ref.read(apiServiceProvider).clearToken();
    state = const AsyncValue.data(null);
  }

  /// Creates the account and reports whether it landed.
  ///
  /// Registration is NOT a session event, so this deliberately leaves [state]
  /// alone. Touching it fires the router's refresh, and this call cannot sign
  /// the user in anyway (the register route never stores the token it returns).
  ///
  /// Failures are rethrown: the screen needs to tell a duplicate account
  /// (409) apart from a network failure. Swallowing the error here made every
  /// failure read as "email may already be in use" (CNT-4).
  Future<void> register(User user) async {
    await _authApi.register({
      'username': user.username,
      'email': user.email,
      'password': user.passwordHash,
    });
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      ref.read(apiServiceProvider).setToken(token);
      try {
        final userData = await _authApi.me();
        final user = User(
          id: userData['id'] as int,
          username: userData['username'] as String,
          email: userData['email'] as String,
          passwordHash: '',
          role: userData['role'] as String,
          isActive: userData['is_active'] as bool? ?? true,
          createdAt:
              DateTime.tryParse(userData['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.now(),
        );
        state = AsyncValue.data(user);
      } catch (_) {
        await prefs.remove('auth_token');
        ref.read(apiServiceProvider).clearToken();
        state = const AsyncValue.data(null);
      }
    }
  }
}

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});

final currentUserRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.role;
});

/// Device-local state that belongs to a person — bookmarks, the
/// recommendation anchor, recent searches — is namespaced per account.
///
/// These lists used to live under one flat key, so signing out and registering
/// a new account inherited the previous account's bookmarks and history. The
/// signed-out scope keeps the bare key: nothing is written there while a user
/// is signed in, and it keeps pre-login browsing / existing device data
/// working.
String localStateKey(String base, int? userId) =>
    userId == null ? base : '$base:u$userId';

/// The signed-in account's id, or null while signed out/restoring.
///
/// Per-account notifiers watch this, so switching accounts (log out and sign
/// in again, or register a new account) rebuilds them from that account's own
/// slice of local storage instead of carrying the previous list in memory.
final localStateScopeProvider = Provider<int?>((ref) {
  return ref.watch(authProvider.select((state) => state.value?.id));
});

// Thesis list params
class ThesisListParams {
  final String? query;
  final int? programId;
  final int? academicYearId;
  final int? categoryId;
  final String? keyword;
  final String? sortBy;
  final String? researchType;
  final String? status;
  final bool showAll;
  final int? page;
  final int? pageSize;

  const ThesisListParams({
    this.query,
    this.programId,
    this.academicYearId,
    this.categoryId,
    this.keyword,
    this.sortBy,
    this.researchType,
    this.status,
    this.showAll = false,
    this.page,
    this.pageSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThesisListParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          programId == other.programId &&
          academicYearId == other.academicYearId &&
          categoryId == other.categoryId &&
          keyword == other.keyword &&
          sortBy == other.sortBy &&
          researchType == other.researchType &&
          status == other.status &&
          showAll == other.showAll &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      query.hashCode ^
      programId.hashCode ^
      academicYearId.hashCode ^
      categoryId.hashCode ^
      keyword.hashCode ^
      sortBy.hashCode ^
      researchType.hashCode ^
      status.hashCode ^
      showAll.hashCode ^
      page.hashCode ^
      pageSize.hashCode;
}

// ─── Upload API provider ────────────────────────────────────────────────────
final uploadApiProvider = Provider<UploadApi>(
  (ref) => UploadApi(ref.read(apiServiceProvider)),
);

// ─── Thesis API provider ─────────────────────────────────────────────────────
final thesisApiProvider = Provider<ThesisApi>(
  (ref) => ThesisApi(ref.read(apiServiceProvider)),
);

// ─── Bulk import API provider ───────────────────────────────────────────────
final importApiProvider = Provider<ImportApi>(
  (ref) => ImportApi(ref.read(apiServiceProvider)),
);

Map<String, String> _thesisQueryParams(ThesisListParams params) {
  final queryParams = <String, String>{};
  if (params.query != null && params.query!.isNotEmpty) {
    queryParams['q'] = params.query!;
  }
  if (params.programId != null) {
    queryParams['program_id'] = params.programId.toString();
  }
  if (params.academicYearId != null) {
    queryParams['year_id'] = params.academicYearId.toString();
  }
  if (params.categoryId != null) {
    queryParams['category_id'] = params.categoryId.toString();
  }
  if (params.keyword != null && params.keyword!.isNotEmpty) {
    queryParams['keyword'] = params.keyword!;
  }
  if (params.sortBy != null && params.sortBy!.isNotEmpty) {
    queryParams['sort_by'] = params.sortBy!;
  }
  if (params.researchType != null) {
    queryParams['research_type'] = params.researchType!;
  }
  if (params.status != null) {
    queryParams['status'] = params.status!;
  }
  if (params.showAll) {
    queryParams['show_all'] = 'true';
    // The admin screen paginates client-side over this one response. The API
    // caps per_page at 100; asking for the cap keeps the visible list (and
    // bulk selection) from silently stopping at the first 20 records.
    queryParams['per_page'] = '100';
  }
  return queryParams;
}

String _encodeQuery(Map<String, String> params) => params.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');

final thesisListProvider = FutureProvider.autoDispose
    .family<List<Thesis>?, ThesisListParams>((ref, params) async {
      final api = ref.read(apiServiceProvider);
      final qs = _encodeQuery(_thesisQueryParams(params));
      final endpoint = qs.isEmpty ? '/api/theses' : '/api/theses?$qs';
      final data = await api.get(endpoint);
      final List<dynamic> raw = data['theses'] as List<dynamic>;
      return raw
          .map((e) => Thesis.fromJson(e as Map<String, dynamic>))
          .toList();
    });

/// One server-paged slice of the repository, with the envelope the API already
/// returns (`total`, `page`, `per_page`, `pages`). Used by the student
/// repository so its pager counts the whole result set, not just the page.
class ThesisPage {
  const ThesisPage({
    required this.theses,
    required this.total,
    required this.page,
    required this.pages,
    required this.pageSize,
  });

  final List<Thesis> theses;
  final int total;
  final int page;
  final int pages;
  final int pageSize;

  bool get isEmpty => theses.isEmpty;
}

final thesisPageProvider = FutureProvider.autoDispose
    .family<ThesisPage, ThesisListParams>((ref, params) async {
      final api = ref.read(apiServiceProvider);
      final page = (params.page ?? 1).clamp(1, 1 << 30);
      final pageSize = (params.pageSize ?? 10).clamp(1, 100);
      final queryParams = _thesisQueryParams(params)
        ..['page'] = page.toString()
        ..['per_page'] = pageSize.toString();
      final qs = _encodeQuery(queryParams);
      final data = await api.get('/api/theses?$qs');
      final List<dynamic> raw = data['theses'] as List<dynamic>;
      return ThesisPage(
        theses: raw
            .map((e) => Thesis.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (data['total'] as num?)?.toInt() ?? raw.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        pages: (data['pages'] as num?)?.toInt() ?? 1,
        pageSize: (data['per_page'] as num?)?.toInt() ?? pageSize,
      );
    });

/// Phase 9: semantic search result with similarity score.
class SemanticResult {
  final Thesis thesis;
  final double similarity;
  const SemanticResult({required this.thesis, required this.similarity});
}

final semanticSearchProvider = FutureProvider.autoDispose
    .family<List<SemanticResult>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      final thesisApi = ref.read(thesisApiProvider);
      try {
        final raw = await thesisApi
            .semanticSearch(query.trim(), limit: 10)
            .timeout(const Duration(seconds: 20));
        // Hydrate in parallel — sequential awaits made 10 hits take up to 100s.
        final futures = raw.map((e) async {
          final m = e as Map<String, dynamic>;
          try {
            // Semantic endpoint returns a slim payload — hydrate via detail endpoint.
            final detail = await ref
                .read(apiServiceProvider)
                .get('/api/theses/${m['id']}')
                .timeout(const Duration(seconds: 10));
            return SemanticResult(
              thesis: Thesis.fromJson(detail as Map<String, dynamic>),
              similarity: (m['similarity'] as num?)?.toDouble() ?? 0.0,
            );
          } catch (_) {
            // Skip unhydratable rows instead of failing the whole search.
            return null;
          }
        }).toList();
        final hydrated = await Future.wait(futures);
        return hydrated.whereType<SemanticResult>().toList();
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    });

final thesisProvider = FutureProvider.autoDispose.family<Thesis?, int>((
  ref,
  id,
) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.get('/api/theses/$id');
  return Thesis.fromJson(data as Map<String, dynamic>);
});

// Alias for detail screen readability
final thesisDetailProvider = thesisProvider;

// Saved thesis IDs as a simple Set<int> — easy to check membership.
//
// Persisted on the device, not the server: the recommender receives these
// ids with each request, so no per-student row is stored in the database.
// The stored list is namespaced by account (see [localStateKey]) so a new
// account never inherits the previous reader's bookmarks.
final savedThesisIdsProvider =
    NotifierProvider<SavedThesisIdsNotifier, Set<int>>(
      () => SavedThesisIdsNotifier(),
    );

class SavedThesisIdsNotifier extends Notifier<Set<int>> {
  static const _prefsKey = 'saved_thesis_ids';

  /// Bumped on every account change. A prefs read started for the previous
  /// account must not land on the new one.
  int _generation = 0;

  /// Set as soon as the reader changes a bookmark. A slow prefs read must not
  /// overwrite a newer local action with the disk copy.
  bool _touched = false;

  @override
  Set<int> build() {
    final userId = ref.watch(localStateScopeProvider);
    _generation++;
    _touched = false;
    _restore(userId, _generation);
    return {};
  }

  Future<void> _restore(int? userId, int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(localStateKey(_prefsKey, userId)) ??
          const <String>[];
      final ids = raw.map(int.tryParse).whereType<int>().toSet();
      if (!ref.mounted || generation != _generation || _touched) return;
      if (ids.isNotEmpty) {
        state = ids;
        ref.invalidate(recommendationsProvider);
      }
    } catch (_) {
      // No prefs available (tests, first run): start empty.
    }
  }

  Future<void> _persist(Set<int> ids, int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        localStateKey(_prefsKey, userId),
        ids.map((id) => id.toString()).toList(),
      );
    } catch (_) {
      // Losing a bookmark write is not worth surfacing to the reader.
    }
  }

  void toggle(int id) {
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    final wasSaved = state.contains(id);
    final next = wasSaved ? ({...state}..remove(id)) : {...state, id};
    state = next;
    _persist(next, userId);
    if (!wasSaved) {
      // Saving is an action: the feed re-anchors on this study.
      ref.read(recommendationAnchorProvider.notifier).setAnchor(id, 'saved');
    } else {
      ref.invalidate(recommendationsProvider);
    }
  }

  void clear() {
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    state = {};
    _persist({}, userId);
    ref.invalidate(recommendationsProvider);
  }
}

// Studies this account has opened, newest first.
//
// The schema has no per-student view table, so history stays on the device
// like the saved set. Only the count is surfaced (the dashboard strip); the
// ids themselves never leave the phone.
//
// Namespaced by account (see [localStateKey]): a freshly registered account
// must start at zero instead of inheriting the previous reader's history.
final viewedThesisIdsProvider =
    NotifierProvider<ViewedThesisIdsNotifier, List<int>>(
      () => ViewedThesisIdsNotifier(),
    );

class ViewedThesisIdsNotifier extends Notifier<List<int>> {
  static const _prefsKey = 'viewed_thesis_ids';

  /// The strip counts distinct studies, so the list is a tally, not an
  /// archive. Cap it so prefs cannot grow without bound.
  static const int _cap = 200;

  /// Bumped on every account change, so a slow prefs read for the previous
  /// account cannot land on this one.
  int _generation = 0;

  /// Set as soon as a view is recorded. A slow prefs read must not overwrite
  /// a newer local write with the disk copy.
  bool _touched = false;

  @override
  List<int> build() {
    final userId = ref.watch(localStateScopeProvider);
    _generation++;
    _touched = false;
    _restore(userId, _generation);
    return const [];
  }

  Future<void> _restore(int? userId, int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(localStateKey(_prefsKey, userId)) ??
          const <String>[];
      final ids = raw.map(int.tryParse).whereType<int>().toList();
      if (!ref.mounted || generation != _generation || _touched) return;
      if (ids.isNotEmpty) state = ids;
    } catch (_) {
      // No prefs available (tests, first run): start empty.
    }
  }

  Future<void> _persist(List<int> ids, int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        localStateKey(_prefsKey, userId),
        ids.map((id) => id.toString()).toList(),
      );
    } catch (_) {
      // Losing a view count is not worth surfacing to the reader.
    }
  }

  /// Records one open. Re-opening a study that is already counted is a no-op,
  /// so the number means "distinct studies this account has read".
  void record(int id) {
    if (id <= 0 || state.contains(id)) return;
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    final next = <int>[id, ...state];
    state = next.length > _cap ? next.sublist(0, _cap) : next;
    _persist(state, userId);
  }
}

/// The study the dashboard feed is currently anchored on.
///
/// The last thing the student acted on — opened or saved — replaces the
/// previous anchor. One item keeps the explanation to a single sentence:
/// "you viewed X, so here is what is closest to X".
///
/// Namespaced per account: the dashboard caption is personal history, so a
/// newly registered account must not inherit "because you viewed X".
class ThesisAnchor {
  const ThesisAnchor({required this.id, required this.kind});

  final int id;

  /// `viewed` or `saved`.
  final String kind;
}

final recommendationAnchorProvider =
    NotifierProvider<RecommendationAnchorNotifier, ThesisAnchor?>(
      () => RecommendationAnchorNotifier(),
    );

class RecommendationAnchorNotifier extends Notifier<ThesisAnchor?> {
  static const _idKey = 'reco_anchor_id';
  static const _kindKey = 'reco_anchor_kind';

  /// Bumped on every account change so a stale prefs read cannot apply the
  /// previous account's anchor to this one.
  int _generation = 0;

  /// A slow prefs read must not overwrite a newer action.
  bool _touched = false;

  @override
  ThesisAnchor? build() {
    final userId = ref.watch(localStateScopeProvider);
    _generation++;
    _touched = false;
    _restore(userId, _generation);
    return null;
  }

  Future<void> _restore(int? userId, int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = int.tryParse(
        prefs.getString(localStateKey(_idKey, userId)) ?? '',
      );
      final kind = prefs.getString(localStateKey(_kindKey, userId));
      if (!ref.mounted || generation != _generation || _touched) return;
      if (id == null || id <= 0) return;
      if (kind != 'viewed' && kind != 'saved') return;
      state = ThesisAnchor(id: id, kind: kind!);
    } catch (_) {
      // Start with no anchor.
    }
  }

  Future<void> _write(int id, String kind, int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(localStateKey(_idKey, userId), id.toString());
      await prefs.setString(localStateKey(_kindKey, userId), kind);
    } catch (_) {
      // Best-effort: the feed still works for this session.
    }
  }

  /// Re-anchor on [id]. Called on detail open (`viewed`) and on save.
  void setAnchor(int id, String kind) {
    if (id <= 0) return;
    if (kind != 'viewed' && kind != 'saved') return;
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    if (state?.id == id && state?.kind == kind) return;
    state = ThesisAnchor(id: id, kind: kind);
    _write(id, kind, userId);
  }

  void clear() {
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    state = null;
    _write(0, '', userId);
  }
}

/// One row of the personalized feed.
class Recommendation {
  const Recommendation({
    required this.thesis,
    required this.reason,
    this.score,
  });

  final Thesis thesis;

  /// Cosine similarity (0..1), null for the "new" fallback rows.
  final double? score;

  /// `similar` or `new`.
  final String reason;
}

/// The dashboard feed plus the honest caption describing why it is ranked.
class RecommendationFeed {
  const RecommendationFeed({
    required this.personalized,
    required this.basis,
    required this.items,
  });

  final bool personalized;
  final String basis;
  final List<Recommendation> items;

  bool get isEmpty => items.isEmpty;
}

/// Personalized recommendations for the signed-in student.
///
/// The server ranks against a centroid built from the ids sent here; the
/// history itself never leaves the device.
final recommendationsProvider = FutureProvider.autoDispose<RecommendationFeed>((
  ref,
) async {
  // One anchor, not a profile: the last study opened or saved. With exactly
  // one source the server answers "Because you viewed/saved X", which is the
  // sentence the UI prints.
  //
  // Watching (not reading) the anchor matters across account switches: the
  // anchor is per-account, so a new account's feed must be rebuilt even when
  // that account has no anchor yet (instead of reusing the old caption).
  final anchor = ref.watch(recommendationAnchorProvider);
  final savedIds = <int>[
    if (anchor != null && anchor.kind == 'saved') anchor.id,
  ];
  final viewedIds = <int>[
    if (anchor != null && anchor.kind == 'viewed') anchor.id,
  ];
  final data = await ref.read(apiServiceProvider).post('/api/recommendations', {
    'saved_ids': savedIds,
    'viewed_ids': viewedIds,
    'limit': 4,
  });
  final map = data as Map<String, dynamic>;
  final items = <Recommendation>[];
  for (final raw in (map['items'] as List<dynamic>? ?? const <dynamic>[])) {
    final row = raw as Map<String, dynamic>;
    items.add(
      Recommendation(
        thesis: Thesis.fromJson(row['thesis'] as Map<String, dynamic>),
        score: (row['score'] as num?)?.toDouble(),
        reason: (row['reason'] as String?) ?? 'similar',
      ),
    );
  }
  return RecommendationFeed(
    personalized: map['personalized'] as bool? ?? false,
    basis: map['basis'] as String? ?? '',
    items: items,
  );
});

final recentThesesProvider = FutureProvider.autoDispose<List<Thesis>>((
  ref,
) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.get('/api/theses');
  final List<dynamic> raw = data['theses'] as List<dynamic>;
  return raw.map((e) => Thesis.fromJson(e as Map<String, dynamic>)).toList();
});

final recommendedThesesProvider = FutureProvider.autoDispose
    .family<List<SemanticResult>, int>((ref, thesisId) async {
      final api = ref.read(thesisApiProvider);
      try {
        final raw = await api.recommend(thesisId);
        final out = <SemanticResult>[];
        for (final e in raw) {
          final m = e as Map<String, dynamic>;
          try {
            final detail = await ref
                .read(apiServiceProvider)
                .get('/api/theses/${m['id']}');
            out.add(
              SemanticResult(
                thesis: Thesis.fromJson(detail as Map<String, dynamic>),
                similarity: (m['similarity'] as num?)?.toDouble() ?? 0.0,
              ),
            );
          } catch (_) {
            continue;
          }
        }
        return out;
      } catch (_) {
        return [];
      }
    });

final programsProvider = FutureProvider.autoDispose<List<Program>>((ref) async {
  final data = await ref.read(apiServiceProvider).get('/api/programs');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
});

final academicYearsProvider = FutureProvider.autoDispose<List<AcademicYear>>((
  ref,
) async {
  final data = await ref.read(apiServiceProvider).get('/api/academic-years');
  final List<dynamic> raw = data as List<dynamic>;
  return raw
      .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
      .toList();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final data = await ref.read(apiServiceProvider).get('/api/categories');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
});

final keywordsProvider = FutureProvider.autoDispose<List<Keyword>>((ref) async {
  final data = await ref.read(apiServiceProvider).get('/api/keywords');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => Keyword.fromJson(e as Map<String, dynamic>)).toList();
});

/// Authors registered in the database (used by the thesis submission form).
final authorsProvider = FutureProvider.autoDispose<List<Author>>((ref) async {
  final data = await ref.read(apiServiceProvider).get('/api/authors');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
});

/// Advisers registered in the database (used by the thesis submission form).
final advisersProvider = FutureProvider.autoDispose<List<Adviser>>((ref) async {
  final data = await ref.read(apiServiceProvider).get('/api/advisers');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => Adviser.fromJson(e as Map<String, dynamic>)).toList();
});

/// Research types supported by the backend (GET /api/research-types).
final researchTypesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final data = await ref.read(apiServiceProvider).get('/api/research-types');
  final List<dynamic> raw = data as List<dynamic>;
  return raw.map((e) => e.toString()).toList();
});

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final data = await ref.read(apiServiceProvider).get('/api/dashboard/stats');
    return Map<String, dynamic>.from(data as Map);
  },
);

/// Public stats for non-admin dashboards — the admin /api/dashboard/stats
/// endpoint returns 403 for students, so the student dashboard uses this.
final publicStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final data = await ref.read(apiServiceProvider).get('/api/stats/summary');
  return Map<String, dynamic>.from(data as Map);
});

/// One page of the admin dashboard's live audit feed.
typedef RecentActivityPage = ({
  List<Map<String, dynamic>> items,
  int total,
  int page,
  int limit,
});

/// Page size for the live audit feed. Kept here so the screen can trust the
/// `limit` echoed back by the API when it computes the page count.
const int recentActivityPageSize = 5;

final recentActivityProvider = FutureProvider.autoDispose
    .family<RecentActivityPage, int>((ref, page) async {
      final data = await ref
          .read(apiServiceProvider)
          .get(
            '/api/dashboard/recent-activity'
            '?page=$page&limit=$recentActivityPageSize',
          );
      final List<dynamic> raw = data['activity'] as List<dynamic>;
      return (
        items: raw.cast<Map<String, dynamic>>(),
        total: (data['total'] as num?)?.toInt() ?? raw.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        limit: (data['limit'] as num?)?.toInt() ?? recentActivityPageSize,
      );
    });

final facultyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final data = await ref.read(apiServiceProvider).get('/api/faculty/dashboard');
  return Map<String, dynamic>.from(data as Map);
});

final facultyActivityProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/faculty/activity');
      final List<dynamic> raw = data['activity'] as List<dynamic>;
      return raw.cast<Map<String, dynamic>>();
    });

/// Full thesis records advised by the current faculty member.
final facultyThesesProvider = FutureProvider.autoDispose<List<Thesis>>((
  ref,
) async {
  final data = await ref
      .read(apiServiceProvider)
      .get('/api/faculty/theses?per_page=50');
  final List<dynamic> raw =
      (data as Map<String, dynamic>)['theses'] as List<dynamic>;
  return raw.map((e) => Thesis.fromJson(e as Map<String, dynamic>)).toList();
});

/// Authors linked to the faculty member's advised theses.
final facultyAdviseesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/faculty/advisees');
      final List<dynamic> raw =
          (data as Map<String, dynamic>)['advisees'] as List<dynamic>;
      return raw.cast<Map<String, dynamic>>();
    });

/// Status/program/year breakdown of the faculty member's advised theses.
final facultyAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/faculty/analytics');
      return Map<String, dynamic>.from(data as Map);
    });

final usersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final data = await ref.read(apiServiceProvider).get('/api/users');
  final List<dynamic> raw = data['users'] as List<dynamic>;
  return raw.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
});

// Saved studies — the bookmarked IDs are kept per account on this device, but
// every study shown is re-loaded from the database so no stale/offline copy is
// displayed.
final savedThesesProvider = FutureProvider.autoDispose<List<Thesis>>((
  ref,
) async {
  final ids = ref.watch(savedThesisIdsProvider);
  if (ids.isEmpty) return const <Thesis>[];
  final api = ref.read(apiServiceProvider);
  final saved = <Thesis>[];
  for (final id in ids) {
    try {
      final data = await api.get('/api/theses/$id');
      saved.add(Thesis.fromJson(data as Map<String, dynamic>));
    } on Exception {
      // A saved study can leave the public catalogue (returned to draft,
      // archived) or be deleted. Skipping it keeps the rest of the list
      // usable instead of failing the whole provider on one 404.
      continue;
    }
  }
  return saved;
});

/// Queries the student has run, newest first, kept on this device only.
///
/// Written by the repository search box and read by the profile card. Nothing
/// is sent to the server just to keep the list — the query only travels when
/// the student is actually searching with it. Namespaced per account, so a new
/// account starts with an empty history.
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      () => RecentSearchesNotifier(),
    );

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _prefsKey = 'recent_search_queries';
  static const _maxEntries = 6;

  /// Bumped on every account change so a stale prefs read cannot apply the
  /// previous account's history to this one.
  int _generation = 0;

  /// Set as soon as a query is recorded, so a slow prefs read cannot replace
  /// the fresh local list with the older disk copy.
  bool _touched = false;

  @override
  List<String> build() {
    final userId = ref.watch(localStateScopeProvider);
    _generation++;
    _touched = false;
    _restore(userId, _generation);
    return const [];
  }

  Future<void> _restore(int? userId, int generation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(localStateKey(_prefsKey, userId)) ??
          const <String>[];
      if (!ref.mounted ||
          generation != _generation ||
          _touched ||
          raw.isEmpty) {
        return;
      }
      state = raw;
    } catch (_) {
      // No prefs available (tests, first run): start empty.
    }
  }

  Future<void> _persist(List<String> queries, int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(localStateKey(_prefsKey, userId), queries);
    } catch (_) {
      // Best-effort: the card still updates for this session.
    }
  }

  /// Records [query] as the newest search.
  ///
  /// Live search produces a ladder of prefixes ("mach", "machine", "machine
  /// learning"), so a query that extends — or shortens — an existing entry
  /// replaces it instead of filling the card with near-duplicates.
  void record(String query) {
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (q.isEmpty) return;
    if (state.isNotEmpty && state.first == q) return;

    final lower = q.toLowerCase();
    final next = <String>[
      q,
      for (final old in state)
        if (old.toLowerCase() != lower &&
            !lower.startsWith(old.toLowerCase()) &&
            !old.toLowerCase().startsWith(lower))
          old,
    ];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    state = next;
    _persist(next, userId);
  }

  void remove(String query) {
    final next = state.where((q) => q != query).toList();
    if (next.length == state.length) return;
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    state = next;
    _persist(next, userId);
  }

  void clear() {
    if (state.isEmpty) return;
    final userId = ref.read(localStateScopeProvider);
    _touched = true;
    state = const [];
    _persist(const [], userId);
  }
}

// Simple state for search
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () => SearchQueryNotifier(),
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

/// The admin lists the topbar search can filter.
///
/// One query per section: the bar is shell chrome that sits OUTSIDE the page,
/// so the two can only meet through shared state. Keeping a query per section
/// means typing on Users never silently filters the thesis table.
enum AdminSearchSection { theses, users, programs }

/// Search text for one admin list, written by AdminTopbar and read by the page
/// that owns the list (kept separate from the student search box).
final adminSearchProvider =
    NotifierProvider.family<AdminSearchNotifier, String, AdminSearchSection>(
      AdminSearchNotifier.new,
    );

class AdminSearchNotifier extends Notifier<String> {
  AdminSearchNotifier(this.section);

  /// The list this instance holds the query for — the family argument.
  final AdminSearchSection section;

  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

class SearchFilters {
  final int? programId;
  final int? academicYearId;
  final String? researchType;
  final String? status;

  const SearchFilters({
    this.programId,
    this.academicYearId,
    this.researchType,
    this.status,
  });

  SearchFilters copyWith({
    int? programId,
    int? academicYearId,
    String? researchType,
    String? status,
  }) {
    return SearchFilters(
      programId: programId ?? this.programId,
      academicYearId: academicYearId ?? this.academicYearId,
      researchType: researchType ?? this.researchType,
      status: status ?? this.status,
    );
  }
}

final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(
      () => SearchFiltersNotifier(),
    );

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setProgram(int? id) => state = state.copyWith(programId: id);
  void setAcademicYear(int? id) => state = state.copyWith(academicYearId: id);
  void setResearchType(String? type) =>
      state = state.copyWith(researchType: type);
  void setStatus(String? status) => state = state.copyWith(status: status);
  void clear() => state = const SearchFilters();
}

final viewedThesisIdProvider = NotifierProvider<ViewedThesisIdNotifier, int?>(
  () => ViewedThesisIdNotifier(),
);

class ViewedThesisIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) => state = id;
}
