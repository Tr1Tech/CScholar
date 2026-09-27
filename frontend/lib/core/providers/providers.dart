// Riverpod 3.x state management (modern Notifier API — no code generation)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// All data shown in the UI comes from the backend API — there is no local
// sample/seed data anywhere in the app.

// ─── API Service provider (production HTTP client) ───────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ref.read(apiServiceProvider).clearToken();
    state = const AsyncValue.data(null);
  }

  Future<bool> register(User user) async {
    state = const AsyncValue.loading();
    try {
      await _authApi.register({
        'username': user.username,
        'email': user.email,
        'password': user.passwordHash,
        'role': user.role,
      });
      //Registration does not log the user in (no token returned to store),
      // so reset to logged-out instead of leaving the provider stuck in loading.
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
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

final thesisListProvider = FutureProvider.autoDispose
    .family<List<Thesis>?, ThesisListParams>((ref, params) async {
      final api = ref.read(apiServiceProvider);
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
      }
      final qs = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint = qs.isEmpty ? '/api/theses' : '/api/theses?$qs';
      final data = await api.get(endpoint);
      final List<dynamic> raw = data['theses'] as List<dynamic>;
      return raw
          .map((e) => Thesis.fromJson(e as Map<String, dynamic>))
          .toList();
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

// Saved thesis IDs as a simple Set<int> — easy to check membership
final savedThesisIdsProvider =
    NotifierProvider<SavedThesisIdsNotifier, Set<int>>(
      () => SavedThesisIdsNotifier(),
    );

class SavedThesisIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  void clear() => state = {};
}

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
final publicStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final data = await ref.read(apiServiceProvider).get('/api/stats/summary');
    return Map<String, dynamic>.from(data as Map);
  },
);

final recentActivityProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/dashboard/recent-activity');
      final List<dynamic> raw = data['activity'] as List<dynamic>;
      return raw.cast<Map<String, dynamic>>();
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
  final List<dynamic> raw = (data as Map<String, dynamic>)['theses'] as List<dynamic>;
  return raw.map((e) => Thesis.fromJson(e as Map<String, dynamic>)).toList();
});

/// Authors linked to the faculty member's advised theses.
final facultyAdviseesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final data = await ref
          .read(apiServiceProvider)
          .get('/api/faculty/advisees');
      final List<dynamic> raw = (data as Map<String, dynamic>)['advisees'] as List<dynamic>;
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

// Saved studies — the bookmarked IDs are kept per session, but every study
// shown is re-loaded from the database so no stale/offline copy is displayed.
final savedThesesProvider = FutureProvider.autoDispose<List<Thesis>>((
  ref,
) async {
  final ids = ref.watch(savedThesisIdsProvider);
  if (ids.isEmpty) return const <Thesis>[];
  final api = ref.read(apiServiceProvider);
  final saved = <Thesis>[];
  for (final id in ids) {
    final data = await api.get('/api/theses/$id');
    saved.add(Thesis.fromJson(data as Map<String, dynamic>));
  }
  return saved;
});

// Simple state for search
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () => SearchQueryNotifier(),
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

/// Admin thesis-table search text, written by AdminTopbar and consumed by
/// the thesis management list (kept separate from the student search box).
final adminThesisSearchProvider =
    NotifierProvider<AdminThesisSearchNotifier, String>(
  () => AdminThesisSearchNotifier(),
);

class AdminThesisSearchNotifier extends Notifier<String> {
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
