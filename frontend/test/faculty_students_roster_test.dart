import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/faculty/faculty_students_screen.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

void main() {
  setUp(() => CScholarMotion.ambientEnabled = false);
  tearDown(() => CScholarMotion.ambientEnabled = true);

  final now = DateTime(2026, 11, 20);

  final theses = <Thesis>[
    Thesis(
      id: 59,
      title: 'LIBRARY MONITORING AND BORROWING INFORMATION SYSTEM',
      abstract: 'A library system.',
      researchType: 'Thesis',
      status: 'published',
      programId: 1,
      academicYearId: 1,
      createdAt: now,
      updatedAt: now,
      program: Program(id: 1, code: 'BSIT', name: 'BS Information Technology', createdAt: now),
      academicYear: AcademicYear(
        id: 1,
        label: '2022-2023',
        startYear: 2022,
        endYear: 2023,
        isActive: false,
        createdAt: now,
      ),
      authors: [
        Author(id: 1, firstName: 'Glen', middleName: 'D.', lastName: 'Cruz', createdAt: now),
      ],
    ),
    Thesis(
      id: 41,
      title: 'HOMETEL RESERVATION SYSTEM',
      abstract: 'A booking system.',
      researchType: 'Thesis',
      status: 'published',
      programId: 1,
      academicYearId: 1,
      createdAt: now,
      updatedAt: now,
      program: Program(id: 1, code: 'BSIT', name: 'BS Information Technology', createdAt: now),
      academicYear: AcademicYear(
        id: 1,
        label: '2023-2024',
        startYear: 2023,
        endYear: 2024,
        isActive: true,
        createdAt: now,
      ),
      authors: [
        Author(id: 2, firstName: 'Maria', lastName: 'Santos', createdAt: now),
      ],
    ),
  ];

  final advisees = <Map<String, dynamic>>[
    {
      'id': 1,
      'first_name': 'Glen',
      'middle_name': 'D.',
      'last_name': 'Cruz',
      'email': null,
      'thesis_count': 1,
      'last_activity': '2026-11-20T00:57:43',
    },
    {
      'id': 2,
      'first_name': 'Maria',
      'last_name': 'Santos',
      'email': null,
      'thesis_count': 1,
      'last_activity': '2026-11-19T00:57:43',
    },
  ];

  Widget host({double textScale = 1.0}) {
    final router = GoRouter(
      initialLocation: '/students',
      routes: [
        GoRoute(path: '/students', builder: (_, _) => const FacultyStudentsScreen()),
        GoRoute(
          path: '/thesis/:id',
          builder: (_, _) => const Scaffold(body: Text('study-detail')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        facultyAdviseesProvider.overrideWith((ref) async => advisees),
        facultyThesesProvider.overrideWith((ref) async => theses),
        currentUserProvider.overrideWithValue(
          User(
            id: 1,
            username: 'demo_faculty',
            email: 'demo.faculty@csu.edu.ph',
            passwordHash: '',
            role: 'faculty',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('roster shows the study behind each advisee', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Glen D. Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('LIBRARY MONITORING AND BORROWING INFORMATION SYSTEM'), findsOneWidget);
    expect(find.text('HOMETEL RESERVATION SYSTEM'), findsOneWidget);
    expect(find.text('BSIT · 2022-2023 · 1 study'), findsOneWidget);
    expect(find.text('2 advisees'), findsOneWidget);
    expect(find.text('2 studies'), findsOneWidget);
  });

  testWidgets('search filters by name and by study title', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'maria');
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Glen D. Cruz'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'library');
    await tester.pumpAndSettle();
    expect(find.text('Glen D. Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'nobody');
    await tester.pumpAndSettle();
    expect(find.text('No matching advisees'), findsOneWidget);
  });

  testWidgets('a single-study advisee opens the study', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();

    expect(find.text('study-detail'), findsOneWidget);
  });

  testWidgets('roster survives phone width at 200% text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Glen D. Cruz'), findsOneWidget);
  });
}
