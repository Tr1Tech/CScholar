// Riverpod 3.x state management (modern Notifier API — no code generation)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/mock_repository_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── API Service provider (production HTTP client) ───────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Auth API provider ────────────────────────────────────────────────────────
final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.read(apiServiceProvider)));

// ─── Repository Service provider ──────────────────────────────────────────────
final repositoryServiceProvider = Provider<RepositoryService>((ref) {
  return MockRepositoryService();
});

// Auth state using Notifier (Riverpod 3.x — simple and clean)
final authProvider =
    NotifierProvider<AuthNotifier, AsyncValue<User?>>(() => AuthNotifier());

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
        createdAt: DateTime.tryParse(userData['created_at'] as String? ?? '') ?? DateTime.now(),
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
          createdAt: DateTime.tryParse(userData['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        state = AsyncValue.data(user);
      } catch (_) {
        await prefs.remove('auth_token');
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
  final String? researchType;
  final String? status;
  final int? page;
  final int? pageSize;

  const ThesisListParams({
    this.query,
    this.programId,
    this.academicYearId,
    this.researchType,
    this.status,
    this.page,
    this.pageSize,
  });
}

// ─── Thesis API provider ─────────────────────────────────────────────────────
final thesisApiProvider = Provider<ThesisApi>((ref) => ThesisApi(ref.read(apiServiceProvider)));

final thesisListProvider = FutureProvider.autoDispose
    .family<List<Thesis>?, ThesisListParams>((ref, params) async {
  // Use real API
  final api = ref.read(apiServiceProvider);
  try {
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
    if (params.researchType != null) {
      queryParams['research_type'] = params.researchType!;
    }
    if (params.status != null) {
      queryParams['status'] = params.status!;
    }
    final qs = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final endpoint = qs.isEmpty ? '/api/theses' : '/api/theses?$qs';
    final data = await api.get(endpoint);
    final List<dynamic> raw = data['theses'] as List<dynamic>;
    return raw.map((e) => Thesis.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    // Fallback to mock
    return ref.read(repositoryServiceProvider).getTheses(
      query: params.query,
      programId: params.programId,
      academicYearId: params.academicYearId,
      researchType: params.researchType,
      status: params.status,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
});

/// Phase 9: semantic search result with similarity score.
class SemanticResult {
  final Thesis thesis;
  final double similarity;
  const SemanticResult({required this.thesis, required this.similarity});
}

final semanticSearchProvider = FutureProvider.autoDispose
    .family<List<SemanticResult>?, String>((ref, query) async {
  if (query.trim().isEmpty) return null;
  final thesisApi = ref.read(thesisApiProvider);
  try {
    final raw = await thesisApi.semanticSearch(query.trim(), limit: 10);
    final out = <SemanticResult>[];
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      try {
        // Semantic endpoint returns a slim payload — hydrate via detail endpoint.
        final detail = await ref.read(apiServiceProvider).get('/api/theses/${m['id']}');
        out.add(SemanticResult(
          thesis: Thesis.fromJson(detail as Map<String, dynamic>),
          similarity: (m['similarity'] as num?)?.toDouble() ?? 0.0,
        ));
      } catch (_) {
        // Skip unhydratable rows instead of failing the whole search.
        continue;
      }
    }
    return out;
  } catch (_) {
    return null;
  }
});

final thesisProvider = FutureProvider.autoDispose.family<Thesis?, int>((ref, id) async {
  // Use real API
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/theses/$id');
    return Thesis.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return ref.read(repositoryServiceProvider).getThesisById(id);
  }
});

// Alias for detail screen readability
final thesisDetailProvider = thesisProvider;

// Saved thesis IDs as a simple Set<int> — easy to check membership
final savedThesisIdsProvider =
    NotifierProvider<SavedThesisIdsNotifier, Set<int>>(() => SavedThesisIdsNotifier());

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

final recentThesesProvider = FutureProvider.autoDispose<List<Thesis>>((ref) async {
  return ref.read(repositoryServiceProvider).getRecentTheses(limit: 5);
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
        final detail = await ref.read(apiServiceProvider).get('/api/theses/${m['id']}');
        out.add(SemanticResult(
          thesis: Thesis.fromJson(detail as Map<String, dynamic>),
          similarity: (m['similarity'] as num?)?.toDouble() ?? 0.0,
        ));
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
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/programs');
    final List<dynamic> raw = data as List<dynamic>;
    return raw.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return ref.read(repositoryServiceProvider).getPrograms();
  }
});

final academicYearsProvider = FutureProvider.autoDispose<List<AcademicYear>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/academic-years');
    final List<dynamic> raw = data as List<dynamic>;
    return raw.map((e) => AcademicYear.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return ref.read(repositoryServiceProvider).getAcademicYears();
  }
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/categories');
    final List<dynamic> raw = data as List<dynamic>;
    return raw.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return ref.read(repositoryServiceProvider).getCategories();
  }
});

final keywordsProvider = FutureProvider.autoDispose<List<Keyword>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/keywords');
    final List<dynamic> raw = data as List<dynamic>;
    return raw.map((e) => Keyword.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return ref.read(repositoryServiceProvider).getKeywords();
  }
});

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    final data = await api.get('/api/theses');
    final List<dynamic> raw = data['theses'] as List<dynamic>;
    return {
      'studies': raw.length,
      'programs': 3,
      'years': 5,
      'saved': 0,
    };
  } catch (_) {
    return ref.read(repositoryServiceProvider).getDashboardStats();
  }
});

// Simple state notifier for saved theses
final savedThesesProvider =
    NotifierProvider<SavedThesesNotifier, List<Thesis>>(() => SavedThesesNotifier());

class SavedThesesNotifier extends Notifier<List<Thesis>> {
  RepositoryService get _repository => ref.read(repositoryServiceProvider);

  @override
  List<Thesis> build() => [];

  Future<void> saveThesis(Thesis thesis) async {
    if (!state.any((t) => t.id == thesis.id)) {
      await _repository.saveThesis(thesis.id);
      state = [...state, thesis];
    }
  }

  Future<void> unsaveThesis(Thesis thesis) async {
    await _repository.unsaveThesis(thesis.id);
    state = state.where((t) => t.id != thesis.id).toList();
  }

  bool isSaved(int thesisId) => state.any((t) => t.id == thesisId);
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

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(
  () => SearchFiltersNotifier(),
);

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setProgram(int? id) => state = state.copyWith(programId: id);
  void setAcademicYear(int? id) => state = state.copyWith(academicYearId: id);
  void setResearchType(String? type) => state = state.copyWith(researchType: type);
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
