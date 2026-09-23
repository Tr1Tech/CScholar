// API service — HTTP calls to the CScholar backend
// Production implementation: replace mock_service calls with these

import 'package:http/http.dart' as http;
import 'dart:convert';
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

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<dynamic> get(String endpoint) async {
    final res = await http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);
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
    final res = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers);
    _checkError(res);
  }

  void _checkError(http.Response res) {
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
    if (researchType != null && researchType.isNotEmpty) params['research_type'] = researchType;
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

  Future<void> delete(int id) async {
    await _api.delete('/api/theses/$id');
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
  Future<UploadPreview> uploadPdf(List<int> pdfBytes, String filename, {int? thesisId}) async {
    final uri = Uri.parse('${_api.baseUrl}/api/upload/pdf');
    final request = http.MultipartRequest('POST', uri);
    if (_api._token != null) request.headers['Authorization'] = 'Bearer ${_api._token}';
    if (thesisId != null) {
      request.fields['thesis_id'] = thesisId.toString();
    }
    request.files.add(http.MultipartFile.fromBytes('file', pdfBytes, filename: filename));

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
    suggestedKeywords: (json['suggested_keywords'] as List<dynamic>?)?.cast<String>() ?? [],
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
  };
}

// --- Programs / Categories / Keywords ---

class MetaApi {
  final ApiService _api;
  MetaApi(this._api);

  Future<List<dynamic>> programs() async => (await _api.get('/api/programs')) as List<dynamic>;
  Future<List<dynamic>> academicYears() async => (await _api.get('/api/academic-years')) as List<dynamic>;
  Future<List<dynamic>> categories() async => (await _api.get('/api/categories')) as List<dynamic>;
  Future<List<dynamic>> keywords() async => (await _api.get('/api/keywords')) as List<dynamic>;
  Future<List<dynamic>> researchTypes() async => (await _api.get('/api/research-types')) as List<dynamic>;
  Future<List<dynamic>> authors() async => (await _api.get('/api/authors')) as List<dynamic>;
  Future<List<dynamic>> advisers() async => (await _api.get('/api/advisers')) as List<dynamic>;
}
