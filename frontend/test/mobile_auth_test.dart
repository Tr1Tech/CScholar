// Mobile auth: the shell switch and the two-step registration.
//
// Phone widths use the mobile paper screens, not the web glass slab. The
// registration form is split so no step is longer than a login screen; these
// tests pin the step gate, the value preservation on Back, and the hand-off
// after the account is created.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';
import 'package:frontend/presentation/screens/auth/register_screen.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_auth.dart';
import 'package:frontend/services/api_service.dart';

class _AcceptingAuthApi extends AuthApi {
  _AcceptingAuthApi() : super(ApiService(baseUrl: 'http://unused.invalid'));

  int calls = 0;

  @override
  Future<void> register(Map<String, dynamic> payload) async {
    calls++;
  }
}

class _RejectingAuthApi extends AuthApi {
  _RejectingAuthApi() : super(ApiService(baseUrl: 'http://unused.invalid'));

  int loginCalls = 0;

  @override
  Future<String> login(String email, String password) async {
    loginCalls++;
    throw ApiException(401, 'Invalid credentials');
  }
}

final _program = Program(
  id: 1,
  code: 'BSCS',
  name: 'BS Computer Science',
  createdAt: DateTime(2020),
);

Widget _host(
  Widget screen, {
  required AuthApi auth,
  String initial = '/register',
}) {
  CScholarPalette.activate(false);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/register', builder: (_, _) => screen),
      GoRoute(
        path: '/login',
        builder: (_, state) =>
            LoginScreen(initialEmail: state.uri.queryParameters['email']),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authApiProvider.overrideWithValue(auth),
      programsProvider.overrideWith((ref) async => [_program]),
    ],
    child: CScholarPaletteScope(
      isDark: false,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

Future<void> _pumpMobile(
  WidgetTester tester,
  Widget screen, {
  required AuthApi auth,
  String initial = '/register',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(screen, auth: auth, initial: initial));
  await tester.pumpAndSettle();
}

Future<void> _fillStepOne(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Maria Santos');
  await tester.enterText(fields.at(1), '2021-00001');
  await tester.tap(find.text('Select your degree program'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('BS Computer Science'));
  await tester.pumpAndSettle();
}

Future<void> _advance(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

Future<void> _fillStepTwo(WidgetTester tester, {required String email}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), 'pass1234');
  await tester.enterText(fields.at(2), 'pass1234');
}

void main() {
  setUp(() {
    CScholarPalette.activate(false);
    CScholarMotion.ambientEnabled = false;
  });
  tearDown(() => CScholarMotion.ambientEnabled = true);

  testWidgets('login uses the mobile shell at phone width', (tester) async {
    await _pumpMobile(
      tester,
      const LoginScreen(),
      auth: _AcceptingAuthApi(),
      initial: '/login',
    );

    expect(find.byType(MobileAuthShell), findsOneWidget);
    expect(find.byType(AuthShell), findsNothing);
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('CEIT THESIS REPOSITORY'), findsOneWidget);
  });

  testWidgets('email and password wells keep the same height', (tester) async {
    await _pumpMobile(
      tester,
      const LoginScreen(),
      auth: _AcceptingAuthApi(),
      initial: '/login',
    );

    final fields = find.byType(TextField);
    Rect wellOf(int index) => tester.getRect(
      find
          .ancestor(of: fields.at(index), matching: find.byType(Container))
          .first,
    );

    final email = wellOf(0);
    final password = wellOf(1);

    expect(
      password.height,
      moreOrLessEquals(email.height, epsilon: 0.1),
      reason: 'the eye affordance must not stretch the password well',
    );
    expect(email.height, greaterThanOrEqualTo(50));
  });

  testWidgets('mobile sign-in submits the form and shows the rejection', (
    tester,
  ) async {
    final auth = _RejectingAuthApi();
    await _pumpMobile(
      tester,
      const LoginScreen(),
      auth: auth,
      initial: '/login',
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'maria@csu.edu.ph');
    await tester.enterText(fields.at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(auth.loginCalls, 1, reason: 'the mobile form must actually submit');
    expect(
      find.text('Invalid credentials. Please check your email and password.'),
      findsOneWidget,
    );
  });

  testWidgets('step one validates before it advances', (tester) async {
    await _pumpMobile(
      tester,
      const RegisterScreen(),
      auth: _AcceptingAuthApi(),
    );

    await _advance(tester);

    expect(find.text('Tell us who you are.'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    // The hint plus the validation message: an empty name shows both.
    expect(
      find.text('Enter your full name'),
      findsNWidgets(2),
      reason: 'step one must show its error instead of advancing',
    );
    expect(find.text('Set your sign-in.'), findsNothing);
  });

  testWidgets('registration walks two steps and creates the account', (
    tester,
  ) async {
    final auth = _AcceptingAuthApi();
    await _pumpMobile(tester, const RegisterScreen(), auth: auth);

    expect(find.text('Tell us who you are.'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await _fillStepOne(tester);
    await _advance(tester);

    // Step two is the short one: email + password + confirm.
    expect(find.text('Set your sign-in.'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    await _fillStepTwo(tester, email: 'maria@csu.edu.ph');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(auth.calls, 1);
    expect(find.text('Account created'), findsOneWidget);

    // The confirmation hands the new account to sign-in with its email.
    await tester.tap(find.text('Continue to sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final email = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(email.controller?.text, 'maria@csu.edu.ph');
  });

  testWidgets('Back keeps everything already typed', (tester) async {
    await _pumpMobile(
      tester,
      const RegisterScreen(),
      auth: _AcceptingAuthApi(),
    );

    await _fillStepOne(tester);
    await _advance(tester);
    expect(find.text('Set your sign-in.'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us who you are.'), findsOneWidget);
    final name = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(name.controller?.text, 'Maria Santos');
    // The program survives too — the picker never re-asks.
    expect(find.text('BS Computer Science'), findsOneWidget);
  });

  testWidgets('the password chips fill in as the fields agree', (tester) async {
    await _pumpMobile(
      tester,
      const RegisterScreen(),
      auth: _AcceptingAuthApi(),
    );
    await _fillStepOne(tester);
    await _advance(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'pass1234');
    await tester.enterText(fields.at(2), 'pass1234');
    await tester.pump();

    // Both chips render a check when their requirement is met.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });
}
