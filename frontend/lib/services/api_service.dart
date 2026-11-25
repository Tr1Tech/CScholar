// API service — HTTP calls to the CScholar backend
// Production implementation: replace mock_service calls with these

import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final String baseUrl;
  String? _token;

  /// Called once when an authenticated request comes back 401: the session is
  /// gone and the app should return to sign-in instead of showing a raw error.
  void Function()? onUnauthorized;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  /// Exposed so screens can build authenticated URLs (e.g. PDF in browser tab).
  String? get token => _token;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    _checkError(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkError(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkError(res);
    return jsonDecode(res.body);
  }

  Future<void> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    _checkError(res);
  }

  void _checkError(http.Response res) {
    if (res.statusCode == 401 && _token != null) {
      // An expired/revoked token is not a screen-level error: clear it and let
      // the app return to sign-in (TRU-4). The callback is wired by the
      // provider; the service never imports auth state itself.
      clearToken();
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

// --- Auth ---

class AuthApi {
  final ApiService _api;
  AuthApi(this._api);

  Future<String> login(String email, String password) async {
    final data = await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return data['token'] as String;
  }

  Future<void> register(Map<String, dynamic> payload) async {
    await _api.post('/api/auth/register', payload);
  }

  Future<Map<String, dynamic>> me() async {
    return await _api.get('/api/auth/me');
  }

  /// Change the signed-in account's password (works for every role).
  ///
  /// Returns the fresh token the server mints: changing the password revokes
  /// every older token, including this device's.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final data = await _api.put('/api/auth/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return (data as Map<String, dynamic>)['token'] as String;
  }
}

// --- Theses ---

class ThesisApi {
  final ApiService _api;
  ThesisApi(this._api);

  Future<List<dynamic>> list({
    String? q,
    int? programId,
    int? yearId,
    int? categoryId,
    String? keyword,
    String? sortBy,
    String? researchType,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (programId != null) params['program_id'] = programId.toString();
    if (yearId != null) params['year_id'] = yearId.toString();
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (sortBy != null && sortBy.isNotEmpty) params['sort_by'] = sortBy;
    if (researchType != null && researchType.isNotEmpty) {
      params['research_type'] = researchType;
    }
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('/api/theses').replace(queryParameters: params);
    final data = await _api.get(uri.toString());
    return data['theses'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    return await _api.get('/api/theses/$id');
  }

  Future<Map<String, dynamic>> create(ThesisFormPayload payload) async {
    return await _api.post('/api/theses', payload.toJson());
  }

  Future<void> update(int id, ThesisFormPayload payload) async {
    await _api.put('/api/theses/$id', payload.toJson());
  }

  /// Change lifecycle status. Returning an approved study to draft carries
  /// the reviewer's notes, which the server stores as `review_notes`.
  Future<Map<String, dynamic>> updateStatus(
    int id,
    String status, {
    String? reviewNotes,
  }) async {
    final notes = reviewNotes?.trim();
    return await _api.put('/api/theses/$id', {
      'status': status,
      if (notes != null && notes.isNotEmpty) 'review_notes': notes,
    });
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/theses/$id');
  }

  /// Move many studies through the lifecycle in one admin action.
  /// The server applies the same per-row transition guard as the single row
  /// control and returns which ids were updated or skipped.
  Future<Map<String, dynamic>> bulkStatus(List<int> ids, String status) async {
    return await _api.post('/api/theses/bulk-status', {
      'ids': ids,
      'status': status,
    }) as Map<String, dynamic>;
  }

  Future<List<dynamic>> recommend(int thesisId) async {
    final data = await _api.get('/api/theses/$thesisId/recommend');
    return data['theses'] as List<dynamic>;
  }

  /// Phase 9: semantic search via pgvector embeddings.
  /// Returns raw list with similarity scores: [{id, title, abstract, ..., similarity}]
  Future<List<dynamic>> semanticSearch(String query, {int limit = 10}) async {
    final data = await _api.post('/api/embeddings/search', {
      'query': query,
      'limit': limit,
    });
    return data['results'] as List<dynamic>;
  }
}

// --- Upload (multipart for PDF) ---

class UploadApi {
  final ApiService _api;
  UploadApi(this._api);

  // Step 1: Upload PDF → backend extracts text + generates embedding
  // Optionally pass thesisId to associate the PDF with a thesis record
  Future<UploadPreview> uploadPdf(
    List<int> pdfBytes,
    String filename, {
    int? thesisId,
  }) async {
    final uri = Uri.parse('${_api.baseUrl}/api/upload/pdf');
    final request = http.MultipartRequest('POST', uri);
    if (_api._token != null) {
      request.headers['Authorization'] = 'Bearer ${_api._token}';
    }
    if (thesisId != null) {
      request.fields['thesis_id'] = thesisId.toString();
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', pdfBytes, filename: filename),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _api._checkError(res);
    final data = jsonDecode(res.body);
    return UploadPreview.fromJson(data);
  }

  // Step 2: Submit full thesis record
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async {
    return await _api.post('/api/theses', payload);
  }
}

class UploadPreview {
  final String extractedText;
  final String suggestedTitle;
  final List<String> suggestedKeywords;
  final String? pdfUrl;

  UploadPreview({
    required this.extractedText,
    required this.suggestedTitle,
    required this.suggestedKeywords,
    this.pdfUrl,
  });

  factory UploadPreview.fromJson(Map<String, dynamic> json) => UploadPreview(
    extractedText: json['extracted_text'] as String? ?? '',
    suggestedTitle: json['suggested_title'] as String? ?? '',
    suggestedKeywords:
        (json['suggested_keywords'] as List<dynamic>?)?.cast<String>() ?? [],
    pdfUrl: json['pdf_url'] as String?,
  );
}

class ThesisFormPayload {
  final String title;
  final String abstract_;
  final int programId;
  final int academicYearId;
  final String researchType;
  final List<int> authorIds;
  final int? adviserId;
  final List<int> categoryIds;
  final List<String> keywordTerms;
  final String? pdfUrl;
  final String? status;
  final bool confirmDuplicate;

  ThesisFormPayload({
    required this.title,
    required this.abstract_,
    required this.programId,
    required this.academicYearId,
    required this.researchType,
    required this.authorIds,
    this.adviserId,
    required this.categoryIds,
    required this.keywordTerms,
    this.pdfUrl,
    this.status,
    this.confirmDuplicate = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'abstract': abstract_,
    'program_id': programId,
    'academic_year_id': academicYearId,
    'research_type': researchType,
    'author_ids': authorIds,
    if (adviserId != null) 'adviser_id': adviserId,
    'category_ids': categoryIds,
    'keyword_terms': keywordTerms,
    if (pdfUrl != null) 'pdf_url': pdfUrl,
    if (status != null) 'status': status,
    if (confirmDuplicate) 'confirm_duplicate': true,
  };
}

// --- Programs / Categories / Keywords ---

class MetaApi {
  final ApiService _api;
  MetaApi(this._api);

  Future<List<dynamic>> programs() async =>
      (await _api.get('/api/programs')) as List<dynamic>;
  Future<List<dynamic>> academicYears() async =>
      (await _api.get('/api/academic-years')) as List<dynamic>;
  Future<List<dynamic>> categories() async =>
      (await _api.get('/api/categories')) as List<dynamic>;
  Future<List<dynamic>> keywords() async =>
      (await _api.get('/api/keywords')) as List<dynamic>;
  Future<List<dynamic>> researchTypes() async =>
      (await _api.get('/api/research-types')) as List<dynamic>;
  Future<List<dynamic>> authors() async =>
      (await _api.get('/api/authors')) as List<dynamic>;
  Future<List<dynamic>> advisers() async =>
      (await _api.get('/api/advisers')) as List<dynamic>;
}

// --- Admin bulk import ----------------------------------------------------

class ImportRow {
  final int row;
  final String action;
  final int? thesisId;
  final String pdfFilename;
  final String title;
  final String programCode;
  final String academicYear;
  final String authors;
  final String adviser;
  final int? pages;
  final int? chunks;
  final bool indexed;
  final List<String> warnings;
  final List<String> errors;
  final String sourceNotes;

  ImportRow({
    required this.row,
    required this.action,
    this.thesisId,
    required this.pdfFilename,
    required this.title,
    required this.programCode,
    required this.academicYear,
    required this.authors,
    required this.adviser,
    this.pages,
    this.chunks,
    required this.indexed,
    required this.warnings,
    required this.errors,
    required this.sourceNotes,
  });

  factory ImportRow.fromJson(Map<String, dynamic> json) => ImportRow(
    row: (json['row'] as num?)?.toInt() ?? 0,
    action: json['action'] as String? ?? '',
    thesisId: (json['thesis_id'] as num?)?.toInt(),
    pdfFilename: json['pdf_filename'] as String? ?? '',
    title: json['title'] as String? ?? '',
    programCode: json['program_code'] as String? ?? '',
    academicYear: json['academic_year'] as String? ?? '',
    authors: json['authors'] as String? ?? '',
    adviser: json['adviser'] as String? ?? '',
    pages: (json['pages'] as num?)?.toInt(),
    chunks: (json['chunks'] as num?)?.toInt(),
    indexed: json['indexed'] as bool? ?? false,
    warnings: (json['warnings'] as List?)?.cast<String>() ?? const [],
    errors: (json['errors'] as List?)?.cast<String>() ?? const [],
    sourceNotes: json['source_notes'] as String? ?? '',
  );

  bool get hasError => errors.isNotEmpty || action == 'error';

  String get statusLabel {
    switch (action) {
      case 'would_create':
        return 'Ready';
      case 'would_update':
        return 'Will update';
      case 'would_skip':
        return 'Already imported';
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'skipped':
        return 'Skipped';
      case 'error':
        return 'Error';
      default:
        return action.isEmpty ? 'Unknown' : action;
    }
  }

  String get message {
    if (errors.isNotEmpty) return errors.join(' | ');
    if (warnings.isNotEmpty) return warnings.join(' | ');
    return '';
  }
}

class ImportJob {
  final int id;
  final String status;
  final String? csvFilename;
  final int totalRows;
  final int processedRows;
  final int createdCount;
  final int updatedCount;
  final int skippedCount;
  final int errorCount;
  final int indexedCount;
  final String? message;
  final List<ImportRow> rows;
  final String? createdAt;
  final String? startedAt;
  final String? finishedAt;

  ImportJob({
    required this.id,
    required this.status,
    this.csvFilename,
    required this.totalRows,
    required this.processedRows,
    required this.createdCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.indexedCount,
    this.message,
    required this.rows,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory ImportJob.fromJson(Map<String, dynamic> json) => ImportJob(
    id: (json['id'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'previewed',
    csvFilename: json['csv_filename'] as String?,
    totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
    processedRows: (json['processed_rows'] as num?)?.toInt() ?? 0,
    createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
    updatedCount: (json['updated_count'] as num?)?.toInt() ?? 0,
    skippedCount: (json['skipped_count'] as num?)?.toInt() ?? 0,
    errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
    indexedCount: (json['indexed_count'] as num?)?.toInt() ?? 0,
    message: json['message'] as String?,
    rows:
        (json['rows'] as List?)
            ?.map((e) => ImportRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    createdAt: json['created_at'] as String?,
    startedAt: json['started_at'] as String?,
    finishedAt: json['finished_at'] as String?,
  );

  bool get isPreview => status == 'previewed';
  bool get isRunning => status == 'queued' || status == 'running';
  bool get isFinished => status == 'completed' || status == 'failed';

  int get readyCount => rows.where((r) => r.action == 'would_create').length;
  int get updateCount => rows.where((r) => r.action == 'would_update').length;
  int get alreadyCount => rows.where((r) => r.action == 'would_skip').length;
  int get invalidCount => rows.where((r) => r.hasError).length;

  double get progress =>
      totalRows == 0 ? 0 : (processedRows / totalRows).clamp(0, 1).toDouble();
}

class ImportApi {
  final ApiService _api;
  ImportApi(this._api);

  Future<ImportJob> preview(PlatformFile csv, List<PlatformFile> pdfs) async {
    final uri = Uri.parse('${_api.baseUrl}/api/import/preview');
    final request = http.MultipartRequest('POST', uri);
    if (_api._token != null) {
      request.headers['Authorization'] = 'Bearer ${_api._token}';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'csv_file',
        await csv.readAsBytes(),
        filename: csv.name,
      ),
    );
    for (final pdf in pdfs) {
      final length = await pdf.length();
      request.files.add(
        http.MultipartFile(
          'pdf_files',
          pdf.readAsByteStream(),
          length ?? 0,
          filename: pdf.name,
        ),
      );
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _api._checkError(res);
    return ImportJob.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ImportJob> run(int id) async {
    final data = await _api.post('/api/import/$id/run', {});
    return ImportJob.fromJson(data as Map<String, dynamic>);
  }

  Future<ImportJob> status(int id) async {
    final data = await _api.get('/api/import/$id');
    return ImportJob.fromJson(data as Map<String, dynamic>);
  }

  Future<void> discard(int id) async {
    await _api.delete('/api/import/$id');
  }

  Future<Uint8List> reportBytes(int id) => _download('/api/import/$id/report');

  Future<Uint8List> templateBytes() => _download('/api/import/template');

  Future<Uint8List> _download(String endpoint) async {
    final res = await http.get(
      Uri.parse('${_api.baseUrl}$endpoint'),
      headers: {
        if (_api._token != null) 'Authorization': 'Bearer ${_api._token}',
      },
    );
    _api._checkError(res);
    return res.bodyBytes;
  }
}
