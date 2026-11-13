// Real-wiring registration flow.
//
// register_success_test covers the screen with a minimal router. This one runs
// the SHIPPING wiring: CScholarApp + appRouter + authProvider.
//
// The regression it guards: submitting used to reset the app to /login. The
// old register() flipped authProvider to loading/data, appRouter watched that
// state and rebuilt the GoRouter, and a fresh router snaps back to its
// initialLocation — so the success panel could never paint. Now the auth
// change only refreshes the redirect, and registration leaves the session
// alone.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/services/api_service.dart';

class _AcceptingAuthApi extends AuthApi {
  _AcceptingAuthApi() : super(ApiService(baseUrl: 'http://unused.invalid'));

  int registerCalls = 0;

  @override
  Future<void> register(Map<String, dynamic> payload) async {
    registerCalls++;
  }

  @override
  Future<String> login(String email, String password) async => 'token';

  @override
  Future<Map<String, dynamic>> me() async => <String, dynamic>{
        'id': 1,
        'username': 'Maria Santos',
        'email': 'maria@csu.edu.ph',
        'role': 'student',
        'is_active': true,
      };
}

Future<void> _pumpRealApp(WidgetTester tester, _AcceptingAuthApi auth) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(auth)],
      child: const CScholarApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));

  // Drive the shipping router to the register route.
  final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  container.read(appRouter).go('/register');
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _fillForm(WidgetTester tester, {required String email}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Maria Santos');
  await tester.enterText(fields.at(1), '2021-00001');
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), 'pass1234');
  await tester.enterText(fields.at(4), 'pass1234');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CScholarMotion.ambientEnabled = false;
  });
  tearDown(() => CScholarMotion.ambientEnabled = true);

  testWidgets('the shipping router keeps the form alive through submit',
      (tester) async {
    final auth = _AcceptingAuthApi();
    await _pumpRealApp(tester, auth);

    expect(find.text('Create your account'), findsOneWidget);

    await _fillForm(tester, email: 'maria@csu.edu.ph');
    await tester.tap(find.text('Create Account'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(auth.registerCalls, 1);
    expect(
      find.text('Account created'),
      findsOneWidget,
      reason: 'the dialog is the whole confirmation',
    );
    expect(find.byType(GlassDialog), findsOneWidget);

    // Still on /register — the failure mode was being snapped back to /login.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    expect(
      container.read(appRouter).routerDelegate.currentConfiguration.uri.path,
      '/register',
    );
  });
}
