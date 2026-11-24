import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/thesis/thesis_detail_screen.dart';

Thesis _thesis() => Thesis(
  id: 1,
  title: 'Library Monitoring and Borrowing Information System',
  abstract: 'A study of the library circulation workflow.',
  researchType: 'Thesis',
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  program: Program(
    id: 1,
    code: 'BSIT',
    name: 'Bachelor of Science in Information Technology',
    createdAt: DateTime(2024),
  ),
  academicYear: AcademicYear(
    id: 1,
    label: '2022-2023',
    startYear: 2022,
    endYear: 2023,
    isActive: false,
    createdAt: DateTime(2024),
  ),
  authors: [
    Author(
      id: 1,
      firstName: 'Juan',
      lastName: 'Dela Cruz',
      createdAt: DateTime(2024),
    ),
  ],
  advisers: [
    Adviser(
      id: 1,
      firstName: 'Maria',
      lastName: 'Santos',
      createdAt: DateTime(2024),
    ),
  ],
  categories: [
    Category(id: 1, name: 'Information Systems', createdAt: DateTime(2024)),
  ],
  keywords: [
    Keyword(id: 1, term: 'library', createdAt: DateTime(2024)),
    Keyword(id: 2, term: 'automation', createdAt: DateTime(2024)),
  ],
);

Widget _host() {
  final router = GoRouter(
    initialLocation: '/thesis/1',
    routes: [
      GoRoute(
        path: '/thesis/:id',
        builder: (_, _) => const ThesisDetailScreen(thesisId: 1),
      ),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => const SizedBox()),
    ],
  );
  return ProviderScope(
    overrides: [
      thesisProvider.overrideWith((ref, id) async => _thesis()),
      recommendedThesesProvider.overrideWith(
        (ref, id) async => const <SemanticResult>[],
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CScholarMotion.ambientEnabled = false;
  });
  tearDownAll(() => CScholarMotion.ambientEnabled = true);

  testWidgets(
    'mobile header uses the program code, details keep the full name',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The eyebrow is scannable: code + year, not the full degree name.
      expect(find.text('BSIT · 2022-2023'), findsOneWidget);
      expect(
        find.text('Bachelor of Science in Information Technology · 2022-2023'),
        findsNothing,
      );
      expect(find.text('THESIS'), findsOneWidget);

      await tester.tap(find.text('Research details'));
      await tester.pump(const Duration(milliseconds: 400));

      // The full record still lives one tap away, matching the web metadata.
      expect(find.text('Program'), findsOneWidget);
      expect(
        find.text('Bachelor of Science in Information Technology'),
        findsOneWidget,
      );
      expect(find.text('Academic year'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Thesis'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Information Systems'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Adviser'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('Keywords'), findsOneWidget);
      expect(find.text('library, automation'), findsOneWidget);
    },
  );
}
