// Mock repository service - simulates the backend API
// This will be replaced by ApiRepositoryService when connecting to real backend

import 'package:frontend/models/thesis.dart';

/// Interface for repository service (allows swapping mock/real)
abstract class RepositoryService {
  Future<List<Thesis>> getTheses({
    String? query,
    int? programId,
    int? academicYearId,
    String? researchType,
    String? status,
    int? page,
    int? pageSize,
  });

  Future<Thesis?> getThesisById(int id);

  Future<List<Thesis>> getRecentTheses({int limit = 5});

  Future<List<Thesis>> getRecommendedTheses(int thesisId, {int limit = 5});

  Future<List<Program>> getPrograms();

  Future<List<AcademicYear>> getAcademicYears();

  Future<List<Category>> getCategories();

  Future<List<Keyword>> getKeywords();

  Future<Map<String, int>> getDashboardStats();

  Future<void> saveThesis(int thesisId);

  Future<void> unsaveThesis(int thesisId);

  Future<List<Thesis>> getSavedTheses();

  Future<void> deleteThesis(int id);

  Future<User?> login(String email, String password);

  Future<User?> register(User user);
}

/// Mock implementation for prototype
class MockRepositoryService implements RepositoryService {
  // Mock data
  late final List<Program> _programs;
  late final List<AcademicYear> _academicYears;
  late final List<Category> _categories;
  late final List<Keyword> _keywords;
  late final List<Author> _authors;
  late final List<Adviser> _advisers;
  late final List<Thesis> _theses;
  late final List<User> _users;
  final Set<int> _savedThesisIds = {};

  MockRepositoryService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Programs (CEIT departments)
    _programs = [
      Program(id: 1, code: 'BSIT', name: 'BS Information Technology', college: 'CEIT', createdAt: DateTime(2024, 1, 1)),
      Program(id: 2, code: 'BSCS', name: 'BS Computer Science', college: 'CEIT', createdAt: DateTime(2024, 1, 1)),
      Program(id: 3, code: 'BSIS', name: 'BS Information Systems', college: 'CEIT', createdAt: DateTime(2024, 1, 1)),
    ];

    // Academic years
    _academicYears = [
      AcademicYear(id: 1, label: '2025-2026', startYear: 2025, endYear: 2026, isActive: true, createdAt: DateTime(2025, 1, 1)),
      AcademicYear(id: 2, label: '2024-2025', startYear: 2024, endYear: 2025, isActive: false, createdAt: DateTime(2024, 1, 1)),
      AcademicYear(id: 3, label: '2023-2024', startYear: 2023, endYear: 2024, isActive: false, createdAt: DateTime(2023, 1, 1)),
    ];

    // Categories
    _categories = [
      Category(id: 1, name: 'Mobile Applications', description: 'Mobile app development', createdAt: DateTime(2024, 1, 1)),
      Category(id: 2, name: 'Web Development', description: 'Web technologies and frameworks', createdAt: DateTime(2024, 1, 1)),
      Category(id: 3, name: 'Artificial Intelligence', description: 'AI and machine learning', createdAt: DateTime(2024, 1, 1)),
      Category(id: 4, name: 'Cybersecurity', description: 'Security and privacy', createdAt: DateTime(2024, 1, 1)),
      Category(id: 5, name: 'Internet of Things', description: 'IoT systems and applications', createdAt: DateTime(2024, 1, 1)),
      Category(id: 6, name: 'Data Science', description: 'Data analytics and visualization', createdAt: DateTime(2024, 1, 1)),
    ];

    // Keywords
    _keywords = [
      Keyword(id: 1, term: 'mobile', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 2, term: 'classroom', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 3, term: 'navigation', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 4, term: 'indoor positioning', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 5, term: 'Flutter', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 6, term: 'student', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 7, term: 'attendance', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 8, term: 'AI', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 9, term: 'machine learning', createdAt: DateTime(2024, 1, 1)),
      Keyword(id: 10, term: 'campus', createdAt: DateTime(2024, 1, 1)),
    ];

    // Authors
    _authors = [
      Author(id: 1, firstName: 'Juan', lastName: 'Dela Cruz', middleName: 'Santos', email: 'juan.dc@csu.edu.ph', studentId: '2021-1001', createdAt: DateTime(2024, 1, 1)),
      Author(id: 2, firstName: 'Maria', lastName: 'Santos', middleName: 'Garcia', email: 'maria.santos@csu.edu.ph', studentId: '2021-1002', createdAt: DateTime(2024, 1, 1)),
      Author(id: 3, firstName: 'Pedro', lastName: 'Reyes', middleName: 'Mendoza', email: 'pedro.reyes@csu.edu.ph', studentId: '2021-1003', createdAt: DateTime(2024, 1, 1)),
      Author(id: 4, firstName: 'Ana', lastName: 'Lopez', middleName: 'Torres', email: 'ana.lopez@csu.edu.ph', studentId: '2021-1004', createdAt: DateTime(2024, 1, 1)),
      Author(id: 5, firstName: 'Luis', lastName: 'Gonzalez', middleName: 'Ramos', email: 'luis.gonzalez@csu.edu.ph', studentId: '2021-1005', createdAt: DateTime(2024, 1, 1)),
      Author(id: 6, firstName: 'Carmen', lastName: 'Villanueva', middleName: 'Castro', email: 'carmen.villanueva@csu.edu.ph', studentId: '2021-1006', createdAt: DateTime(2024, 1, 1)),
    ];

    // Advisers
    _advisers = [
      Adviser(id: 1, firstName: 'Dr. Jose', lastName: 'Rizal', middleName: 'Protacio', email: 'j.rizal@csu.edu.ph', designation: 'Professor, CS Department', createdAt: DateTime(2024, 1, 1)),
      Adviser(id: 2, firstName: 'Dr. Gabriela', lastName: 'Silang', middleName: 'Cariño', email: 'g.silang@csu.edu.ph', designation: 'Associate Professor, IT Department', createdAt: DateTime(2024, 1, 1)),
      Adviser(id: 3, firstName: 'Dr. Andres', lastName: 'Bonifacio', middleName: 'Tolentino', email: 'a.bonifacio@csu.edu.ph', designation: 'Assistant Professor, IS Department', createdAt: DateTime(2024, 1, 1)),
    ];

    // Theses (matching the seed data in DB)
    _theses = [
      Thesis(
        id: 1,
        title: 'Campus Navigation and Room Locator Application',
        abstract: 'This study presents a mobile application that helps students and visitors navigate the CSU campus and locate classrooms, offices, and facilities using indoor positioning technology. The application uses Bluetooth beacons and WiFi fingerprinting to provide accurate indoor navigation without GPS.',
        researchType: 'Capstone',
        status: 'published',
        programId: 1,
        academicYearId: 1,
        createdAt: DateTime(2025, 3, 15),
        updatedAt: DateTime(2025, 3, 15),
        publishedAt: DateTime(2025, 6, 1),
        program: _programs[0],
        academicYear: _academicYears[0],
        authors: [_authors[0], _authors[1]],
        advisers: [_advisers[0]],
        categories: [_categories[0], _categories[4]],
        keywords: [_keywords[0], _keywords[1], _keywords[2], _keywords[3], _keywords[5], _keywords[9]],
      ),
      Thesis(
        id: 2,
        title: 'Indoor Positioning System for University Buildings Using Bluetooth Beacons',
        abstract: 'This research develops an indoor positioning system (IPS) for university buildings using Bluetooth Low Energy (BLE) beacons and trilateration algorithms. The system achieves sub-meter accuracy and can be used for navigation, asset tracking, and emergency response.',
        researchType: 'Thesis',
        status: 'published',
        programId: 2,
        academicYearId: 1,
        createdAt: DateTime(2025, 2, 20),
        updatedAt: DateTime(2025, 2, 20),
        publishedAt: DateTime(2025, 5, 15),
        program: _programs[1],
        academicYear: _academicYears[0],
        authors: [_authors[2]],
        advisers: [_advisers[1]],
        categories: [_categories[4], _categories[2]],
        keywords: [_keywords[3], _keywords[8], _keywords[9], _keywords[4]],
      ),
      Thesis(
        id: 3,
        title: 'AI-Based Student Attendance Monitoring System Using Facial Recognition',
        abstract: 'An automated attendance monitoring system that uses computer vision and facial recognition to track student attendance in real-time. The system eliminates manual roll calls and provides analytics on attendance patterns.',
        researchType: 'Thesis',
        status: 'published',
        programId: 1,
        academicYearId: 1,
        createdAt: DateTime(2025, 1, 10),
        updatedAt: DateTime(2025, 1, 10),
        publishedAt: DateTime(2025, 4, 1),
        program: _programs[0],
        academicYear: _academicYears[0],
        authors: [_authors[3], _authors[4]],
        advisers: [_advisers[2]],
        categories: [_categories[2], _categories[3]],
        keywords: [_keywords[6], _keywords[7], _keywords[8], _keywords[5]],
      ),
      Thesis(
        id: 4,
        title: 'Mobile-Based Campus Event Management System',
        abstract: 'A comprehensive mobile application for managing campus events, from creation and promotion to registration and attendance tracking. Features include real-time notifications, QR code check-in, and event analytics.',
        researchType: 'Capstone',
        status: 'approved',
        programId: 1,
        academicYearId: 1,
        createdAt: DateTime(2025, 4, 5),
        updatedAt: DateTime(2025, 4, 5),
        program: _programs[0],
        academicYear: _academicYears[0],
        authors: [_authors[5]],
        advisers: [_advisers[0]],
        categories: [_categories[0], _categories[1]],
        keywords: [_keywords[0], _keywords[5], _keywords[9]],
      ),
      Thesis(
        id: 5,
        title: 'Machine Learning Approach for Student Performance Prediction',
        abstract: 'This study applies machine learning algorithms to predict student academic performance based on historical data, attendance, and engagement metrics. The model helps identify at-risk students early for intervention.',
        researchType: 'Thesis',
        status: 'published',
        programId: 3,
        academicYearId: 1,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
        publishedAt: DateTime(2025, 6, 15),
        program: _programs[2],
        academicYear: _academicYears[0],
        authors: [_authors[0], _authors[2]],
        advisers: [_advisers[1]],
        categories: [_categories[2], _categories[5]],
        keywords: [_keywords[7], _keywords[8], _keywords[5]],
      ),
      Thesis(
        id: 6,
        title: 'Secure Document Management System for Academic Records',
        abstract: 'A blockchain-based document management system for secure storage and verification of academic records. The system ensures data integrity, prevents tampering, and enables instant verification.',
        researchType: 'Capstone',
        status: 'draft',
        programId: 2,
        academicYearId: 2,
        createdAt: DateTime(2024, 11, 15),
        updatedAt: DateTime(2024, 11, 15),
        program: _programs[1],
        academicYear: _academicYears[1],
        authors: [_authors[1], _authors[3]],
        advisers: [_advisers[2]],
        categories: [_categories[3], _categories[1]],
        keywords: [_keywords[7], _keywords[9]],
      ),
      Thesis(
        id: 7,
        title: 'IoT-Based Smart Classroom Environment Monitoring',
        abstract: 'An IoT system that monitors classroom environmental conditions (temperature, humidity, CO2, lighting) and automatically adjusts HVAC and lighting for optimal learning conditions and energy efficiency.',
        researchType: 'Thesis',
        status: 'approved',
        programId: 1,
        academicYearId: 2,
        createdAt: DateTime(2024, 10, 1),
        updatedAt: DateTime(2024, 10, 1),
        program: _programs[0],
        academicYear: _academicYears[1],
        authors: [_authors[4], _authors[5]],
        advisers: [_advisers[0]],
        categories: [_categories[4], _categories[5]],
        keywords: [_keywords[8], _keywords[9]],
      ),
      Thesis(
        id: 8,
        title: 'E-Learning Platform with Adaptive Content Delivery',
        abstract: 'An adaptive e-learning platform that personalizes content delivery based on student learning styles, progress, and preferences. Uses collaborative filtering and content-based recommendation algorithms.',
        researchType: 'Capstone',
        status: 'published',
        programId: 3,
        academicYearId: 2,
        createdAt: DateTime(2024, 9, 1),
        updatedAt: DateTime(2024, 9, 1),
        publishedAt: DateTime(2024, 12, 1),
        program: _programs[2],
        academicYear: _academicYears[1],
        authors: [_authors[2], _authors[5]],
        advisers: [_advisers[1]],
        categories: [_categories[1], _categories[2]],
        keywords: [_keywords[7], _keywords[8], _keywords[5]],
      ),
    ];

    // Users for mock login
    _users = [
      User(id: 1, username: 'student1', email: 'student@csu.edu.ph', passwordHash: 'pass123', role: 'student', isActive: true, createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1)),
      User(id: 2, username: 'faculty1', email: 'faculty@csu.edu.ph', passwordHash: 'pass123', role: 'faculty', isActive: true, createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1)),
      User(id: 3, username: 'admin1', email: 'admin@csu.edu.ph', passwordHash: 'pass123', role: 'admin', isActive: true, createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1)),
    ];
  }

  @override
  Future<List<Thesis>> getTheses({
    String? query,
    int? programId,
    int? academicYearId,
    String? researchType,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network

    var results = _theses.where((t) => t.status == 'published' || t.status == 'approved').toList();

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.abstract.toLowerCase().contains(q) ||
        t.authorsString.toLowerCase().contains(q) ||
        t.keywordsString.toLowerCase().contains(q) ||
        t.categoriesString.toLowerCase().contains(q)
      ).toList();
    }

    if (programId != null) {
      results = results.where((t) => t.programId == programId).toList();
    }

    if (academicYearId != null) {
      results = results.where((t) => t.academicYearId == academicYearId).toList();
    }

    if (researchType != null) {
      results = results.where((t) => t.researchType == researchType).toList();
    }

    if (status != null) {
      results = results.where((t) => t.status == status).toList();
    }

    // Sort by relevance (mock: newest first for now)
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Pagination
    final pageNum = page ?? 1;
    final size = pageSize ?? 10;
    final start = (pageNum - 1) * size;
    final end = start + size;
    return results.sublist(start.clamp(0, results.length), end.clamp(0, results.length));
  }

  @override
  Future<Thesis?> getThesisById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _theses.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Thesis>> getRecentTheses({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final published = _theses.where((t) => t.status == 'published' || t.status == 'approved').toList();
    published.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return published.take(limit).toList();
  }

  @override
  Future<List<Thesis>> getRecommendedTheses(int thesisId, {int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock recommendation: find theses with overlapping categories/keywords
    var candidates = _theses.where((t) =>
      t.id != thesisId &&
      (t.status == 'published' || t.status == 'approved')
    ).toList();

    // Sort by category overlap (mock relevance)
    candidates.sort((a, b) {
      final aCats = a.categories?.length ?? 0;
      final bCats = b.categories?.length ?? 0;
      return bCats.compareTo(aCats); // More categories = higher
    });

    return candidates.take(limit).toList();
  }

  @override
  Future<List<Program>> getPrograms() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _programs;
  }

  @override
  Future<List<AcademicYear>> getAcademicYears() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _academicYears;
  }

  @override
  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _categories;
  }

  @override
  Future<List<Keyword>> getKeywords() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _keywords;
  }

  @override
  Future<Map<String, int>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'totalStudies': _theses.where((t) => t.status == 'published' || t.status == 'approved').length,
      'totalAuthors': _authors.length,
      'totalPrograms': _programs.length,
      'totalSearches': 1284, // mock
    };
  }

  @override
  Future<void> saveThesis(int thesisId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _savedThesisIds.add(thesisId);
  }

  @override
  Future<void> unsaveThesis(int thesisId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _savedThesisIds.remove(thesisId);
  }

  @override
  Future<List<Thesis>> getSavedTheses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _theses.where((t) => _savedThesisIds.contains(t.id)).toList();
  }

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _users.firstWhere((u) => u.email == email && u.passwordHash == password);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> register(User user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newUser = User(
      id: _users.length + 1,
      username: user.username,
      email: user.email,
      passwordHash: user.passwordHash,
      role: user.role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<void> deleteThesis(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _theses.removeWhere((t) => t.id == id);
  }
}