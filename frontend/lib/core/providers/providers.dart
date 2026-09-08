// Riverpod 3.x state management (modern Notifier API — no code generation)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/mock_repository_service.dart';
import 'package:frontend/services/api_service.dart';

// ─── API Service provider (production HTTP client) ───────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Repository Service provider ──────────────────────────────────────────────
final repositoryServiceProvider = Provider<RepositoryService>((ref) {
  return MockRepositoryService();
});

// Auth state using Notifier (Riverpod 3.x — simple and clean)
final authProvider =
    NotifierProvider<AuthNotifier, AsyncValue<User?>>(() => AuthNotifier());

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  RepositoryService get _repository => ref.read(repositoryServiceProvider);

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
      final user = await _repository.login(email, password);
      state = user != null ? AsyncValue.data(user) : const AsyncValue.data(null);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }

  Future<bool> register(User user) async {
    state = const AsyncValue.loading();
    try {
      final newUser = await _repository.register(user);
      state = newUser != null ? AsyncValue.data(newUser) : const AsyncValue.data(null);
      return newUser != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
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

final thesisListProvider = FutureProvider.autoDispose
    .family<List<Thesis>?, ThesisListParams>((ref, params) async {
  return ref.read(repositoryServiceProvider).getTheses(
    query: params.query,
    programId: params.programId,
    academicYearId: params.academicYearId,
    researchType: params.researchType,
    status: params.status,
    page: params.page,
    pageSize: params.pageSize,
  );
});

final thesisProvider = FutureProvider.autoDispose.family<Thesis?, int>((ref, id) async {
  return ref.read(repositoryServiceProvider).getThesisById(id);
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
    .family<List<Thesis>, int>((ref, thesisId) async {
  return ref.read(repositoryServiceProvider).getRecommendedTheses(thesisId, limit: 5);
});

final programsProvider = FutureProvider.autoDispose<List<Program>>((ref) async {
  return ref.read(repositoryServiceProvider).getPrograms();
});

final academicYearsProvider = FutureProvider.autoDispose<List<AcademicYear>>((ref) async {
  return ref.read(repositoryServiceProvider).getAcademicYears();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  return ref.read(repositoryServiceProvider).getCategories();
});

final keywordsProvider = FutureProvider.autoDispose<List<Keyword>>((ref) async {
  return ref.read(repositoryServiceProvider).getKeywords();
});

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.read(repositoryServiceProvider).getDashboardStats();
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
