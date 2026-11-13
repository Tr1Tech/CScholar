// Registration success flow.
//
// The register endpoint mints no session, so a successful sign-up can't hand
// the user to a dashboard — it used to bounce them to /login with no word of
// what happened. These tests pin the confirmation panel, the hand-off to the
// login screen, and the prefilled email that makes the second step one field.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/screens/auth/login_screen.dart';
import 'package:frontend/presentation/screens/auth/register_screen.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/services/api_service.dart';

/// Accepts the registration without touching HTTP, so the test exercises the
/// screen's own success branch (flutter_test's default client would 400).
class _AcceptingAuthApi extends AuthApi {
  _AcceptingAuthApi() : super(ApiService(baseUrl: 'http://unused.invalid'));

  @override
  Future<void> register(Map<String, dynamic> payload) async {}
}

Widget _harness() {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          // Mirrors app_router: the success panel hands the email over as a
          // query parameter.
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authApiProvider.overrideWithValue(_AcceptingAuthApi())],
    child: MaterialApp.router(
      routerConfig: router,
      // Reduced motion: the auth shell's orbs and any loading sweep stop
      // looping, so pumpAndSettle can reach a settled tree.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

Future<void> _fillForm(WidgetTester tester, {required String email}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Maria Santos');
  await tester.enterText(fields.at(1), '2021-00001');
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), 'pass1234');
  await tester.enterText(fields.at(4), 'pass1234');
}

/// The register card is taller than the default 800x600 test view; give it a
/// desktop-sized window so the submit button is actually hittable.
Future<void> _pumpRegister(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
}

void main() {
  // The auth shell's ambient orbs loop forever; pin them off so pumpAndSettle
  // can reach a settled tree (same switch the rest of the suite flips).
  setUp(() => CScholarMotion.ambientEnabled = false);
  tearDown(() => CScholarMotion.ambientEnabled = true);

  testWidgets('a created account shows a success dialog', (tester) async {
    await _pumpRegister(tester);

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Account created'), findsNothing);

    await _fillForm(tester, email: 'maria@csu.edu.ph');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // The dialog IS the confirmation — the card behind keeps the form.
    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.text('Account created'), findsOneWidget);
    expect(
      find.text(
        'Your account is ready. Sign in as maria@csu.edu.ph to start saving '
        'and building your library.',
      ),
      findsOneWidget,
      reason: 'the confirmation must name the account that was created',
    );
    final dialogCta = find.descendant(
      of: find.byType(GlassDialog),
      matching: find.text('Continue to Sign In'),
    );
    expect(dialogCta, findsOneWidget, reason: 'the dialog owns one CTA');
  });

  testWidgets('dismissing the dialog still lands on sign-in', (tester) async {
    await _pumpRegister(tester);

    await _fillForm(tester, email: 'maria@csu.edu.ph');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);

    // Back / Escape pops the dialog, and the flow still goes forward: nobody
    // is left on a filled form they could resubmit into a 409.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialog), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    final email = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(email.controller?.text, 'maria@csu.edu.ph');
  });

  testWidgets('the success hand-off prefills the login email', (tester) async {
    await _pumpRegister(tester);

    await _fillForm(tester, email: 'maria@csu.edu.ph');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(GlassDialog),
        matching: find.text('Continue to Sign In'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final email = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(email.controller?.text, 'maria@csu.edu.ph');
  });
}
