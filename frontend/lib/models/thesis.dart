// Data models matching the database schema exactly
 
/// Parses an ISO-8601 timestamp from the API, tolerating missing values so a
/// partial row from the database never breaks a screen.
DateTime _parseDate(dynamic value) =>
    DateTime.tryParse((value as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

/// CEIT Program model
class Program {
  final int id;
  final String code;
  final String name;
  final String? college;
  final DateTime createdAt;

  const Program({
    required this.id,
    required this.code,
    required this.name,
    this.college,
    required this.createdAt,
  });

  factory Program.fromJson(Map<String, dynamic> json) => Program(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    college: json['college'] as String?,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'college': college,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Academic Year model
class AcademicYear {
  final int id;
  final String label;
  final int startYear;
  final int endYear;
  final bool isActive;
  final DateTime createdAt;

  const AcademicYear({
    required this.id,
    required this.label,
    required this.startYear,
    required this.endYear,
    required this.isActive,
    required this.createdAt,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
    id: json['id'] as int,
    // The API exposes the label as "label" on /api/academic-years and as
    // "name" when nested inside a thesis payload.
    label: (json['label'] ?? json['name'] ?? '') as String,
    startYear: json['start_year'] as int,
    endYear: json['end_year'] as int,
    isActive: json['is_active'] as bool? ?? false,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'start_year': startYear,
    'end_year': endYear,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Author model
class Author {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? studentId;
  final DateTime createdAt;

  const Author({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.studentId,
    required this.createdAt,
  });

  String get fullName {
    final parts = <String>[firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    parts.add(lastName);
    return parts.join(' ');
  }

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as int,
    firstName: json['first_name'] as String,
    middleName: json['middle_name'] as String?,
    lastName: json['last_name'] as String,
    email: json['email'] as String?,
    studentId: json['student_id'] as String?,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'email': email,
    'student_id': studentId,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Adviser model
class Adviser {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? email;
  final String? designation;
  final DateTime createdAt;

  const Adviser({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email,
    this.designation,
    required this.createdAt,
  });

  String get fullName {
    final parts = <String>[firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    parts.add(lastName);
    return parts.join(' ');
  }

  factory Adviser.fromJson(Map<String, dynamic> json) => Adviser(
    id: json['id'] as int,
    firstName: json['first_name'] as String,
    middleName: json['middle_name'] as String?,
    lastName: json['last_name'] as String,
    email: json['email'] as String?,
    designation: json['designation'] as String?,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'email': email,
    'designation': designation,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Category model
class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Keyword model
class Keyword {
  final int id;
  final String term;
  final DateTime createdAt;

  const Keyword({
    required this.id,
    required this.term,
    required this.createdAt,
  });

  factory Keyword.fromJson(Map<String, dynamic> json) => Keyword(
    id: json['id'] as int,
    term: json['term'] as String,
    createdAt: _parseDate(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Thesis File model
class ThesisFile {
  final int id;
  final int thesisId;
  final String filename;
  final String originalFilename;
  final String fileType;
  final int? fileSizeBytes;
  final DateTime uploadedAt;

  const ThesisFile({
    required this.id,
    required this.thesisId,
    required this.filename,
    required this.originalFilename,
    required this.fileType,
    this.fileSizeBytes,
    required this.uploadedAt,
  });

  factory ThesisFile.fromJson(Map<String, dynamic> json) => ThesisFile(
    id: json['id'] as int,
    thesisId: json['thesis_id'] as int,
    filename: json['filename'] as String,
    originalFilename: json['original_filename'] as String,
    fileType: json['file_type'] as String,
    fileSizeBytes: json['file_size_bytes'] as int?,
    uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'thesis_id': thesisId,
    'filename': filename,
    'original_filename': originalFilename,
    'file_type': fileType,
    'file_size_bytes': fileSizeBytes,
    'uploaded_at': uploadedAt.toIso8601String(),
  };
}

/// Thesis Embedding model
class ThesisEmbedding {
  final int id;
  final int thesisId;
  final String chunkText;
  final List<double> embedding;
  final String modelName;
  final DateTime createdAt;

  const ThesisEmbedding({
    required this.id,
    required this.thesisId,
    required this.chunkText,
    required this.embedding,
    required this.modelName,
    required this.createdAt,
  });

  factory ThesisEmbedding.fromJson(Map<String, dynamic> json) => ThesisEmbedding(
    id: json['id'] as int,
    thesisId: json['thesis_id'] as int,
    chunkText: json['chunk_text'] as String,
    embedding: (json['embedding'] as List).cast<double>(),
    modelName: json['model_name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'thesis_id': thesisId,
    'chunk_text': chunkText,
    'embedding': embedding,
    'model_name': modelName,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Search Log model
class SearchLog {
  final int id;
  final int? userId;
  final String queryText;
  final int resultsCount;
  final DateTime searchedAt;

  const SearchLog({
    required this.id,
    this.userId,
    required this.queryText,
    required this.resultsCount,
    required this.searchedAt,
  });

  factory SearchLog.fromJson(Map<String, dynamic> json) => SearchLog(
    id: json['id'] as int,
    userId: json['user_id'] as int?,
    queryText: json['query_text'] as String,
    resultsCount: json['results_count'] as int,
    searchedAt: DateTime.parse(json['searched_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'query_text': queryText,
    'results_count': resultsCount,
    'searched_at': searchedAt.toIso8601String(),
  };
}

/// Recommendation Log model
class RecommendationLog {
  final int id;
  final int? userId;
  final int thesisId;
  final int sourceThesisId;
  final String sourceType;
  final double? similarityScore;
  final DateTime recommendedAt;

  const RecommendationLog({
    required this.id,
    this.userId,
    required this.thesisId,
    required this.sourceThesisId,
    required this.sourceType,
    this.similarityScore,
    required this.recommendedAt,
  });

  factory RecommendationLog.fromJson(Map<String, dynamic> json) => RecommendationLog(
    id: json['id'] as int,
    userId: json['user_id'] as int?,
    thesisId: json['thesis_id'] as int,
    sourceThesisId: json['source_thesis_id'] as int,
    sourceType: json['source_type'] as String,
    similarityScore: (json['similarity_score'] as num?)?.toDouble(),
    recommendedAt: DateTime.parse(json['recommended_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'thesis_id': thesisId,
    'source_thesis_id': sourceThesisId,
    'source_type': sourceType,
    'similarity_score': similarityScore,
    'recommended_at': recommendedAt.toIso8601String(),
  };
}

/// User model
class User {
  final int id;
  final String username;
  final String email;
  final String passwordHash;
  final String role; // 'student' | 'faculty' | 'admin'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['created_at']);
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      // /api/users never exposes the password hash.
      passwordHash: json['password_hash'] as String? ?? '',
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: created,
      updatedAt: json['updated_at'] == null ? created : _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'password_hash': passwordHash,
    'role': role,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Main Thesis model with relations
class Thesis {
  final int id;
  final String title;
  final String abstract;
  final String researchType; // 'Thesis' | 'Capstone'
  final String status; // 'draft' | 'approved' | 'published' | 'archived'
  final int programId;
  final int academicYearId;
  final int? creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? pdfUrl;

  // Relations (optional, loaded when needed)
  final Program? program;
  final AcademicYear? academicYear;
  final List<Author>? authors;
  final List<Adviser>? advisers;
  final List<Category>? categories;
  final List<Keyword>? keywords;
  final ThesisFile? file;
  final ThesisEmbedding? embedding;

  const Thesis({
    required this.id,
    required this.title,
    required this.abstract,
    required this.researchType,
    required this.status,
    required this.programId,
    required this.academicYearId,
    this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.pdfUrl,
    this.program,
    this.academicYear,
    this.authors,
    this.advisers,
    this.categories,
    this.keywords,
    this.file,
    this.embedding,
  });

  factory Thesis.fromJson(Map<String, dynamic> json) => Thesis(
    id: json['id'] as int,
    title: json['title'] as String,
    abstract: json['abstract'] as String? ?? '',
    researchType: json['research_type'] as String? ?? '',
    status: json['status'] as String? ?? '',
    programId: json['program_id'] as int,
    academicYearId: json['academic_year_id'] as int,
    creatorId: json['creator_id'] as int?,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
    publishedAt: json['published_at'] != null
        ? DateTime.parse(json['published_at'] as String)
        : null,
    program: json['program'] != null
        ? Program.fromJson(json['program'] as Map<String, dynamic>)
        : null,
    academicYear: json['academic_year'] != null
        ? AcademicYear.fromJson(json['academic_year'] as Map<String, dynamic>)
        : null,
    authors: (json['authors'] as List?)?.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList(),
    advisers: (json['advisers'] as List?)?.map((e) => Adviser.fromJson(e as Map<String, dynamic>)).toList(),
    categories: (json['categories'] as List?)?.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList(),
    keywords: (json['keywords'] as List?)?.map((e) => Keyword.fromJson(e as Map<String, dynamic>)).toList(),
    file: json['file'] != null
        ? ThesisFile.fromJson(json['file'] as Map<String, dynamic>)
        : null,
    embedding: json['embedding'] != null
        ? ThesisEmbedding.fromJson(json['embedding'] as Map<String, dynamic>)
        : null,
    pdfUrl: json['pdf_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'abstract': abstract,
    'research_type': researchType,
    'status': status,
    'program_id': programId,
    'academic_year_id': academicYearId,
    'creator_id': creatorId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'published_at': publishedAt?.toIso8601String(),
    'program': program?.toJson(),
    'academic_year': academicYear?.toJson(),
    'authors': authors?.map((e) => e.toJson()).toList(),
    'advisers': advisers?.map((e) => e.toJson()).toList(),
    'categories': categories?.map((e) => e.toJson()).toList(),
    'keywords': keywords?.map((e) => e.toJson()).toList(),
    'file': file?.toJson(),
    'embedding': embedding?.toJson(),
  };

  /// Short description for cards (first 150 chars of abstract)
  String get shortDescription {
    if (abstract.length <= 150) return abstract;
    return '${abstract.substring(0, 150)}...';
  }

  /// Formatted authors string (empty when the database has no linked authors)
  String get authorsString {
    if (authors == null || authors!.isEmpty) return '';
    return authors!.map((a) => a.fullName).join(', ');
  }

  /// Formatted categories string
  String get categoriesString {
    if (categories == null || categories!.isEmpty) return '';
    return categories!.map((c) => c.name).join(', ');
  }

  /// Formatted keywords string
  String get keywordsString {
    if (keywords == null || keywords!.isEmpty) return '';
    return keywords!.map((k) => k.term).join(', ');
  }
}