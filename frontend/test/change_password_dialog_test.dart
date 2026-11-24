// Change Password is shared by every role, so its contract is tested once here:
// the dialog validates locally, calls the API exactly once with the typed
// values, and closes with a confirmation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/change_password_dialog.dart';
import 'package:frontend/services/api_service.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(ApiService(baseUrl: 'http://127.0.0.1:1'));

  String? current;
  String? next;
  int calls = 0;
  Object? error;

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls++;
    current = currentPassword;
    next = newPassword;
    if (error != null) throw error!;
    return 'fresh-token';
  }
}

Future<void> _openDialog(
  WidgetTester tester,
  _FakeAuthApi api, {
  bool dark = false,
}) async {
  Widget app = MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showChangePasswordDialog(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
  if (dark) {
    app = CScholarMobileThemeScope(isDark: true, child: app);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authApiProvider.overrideWithValue(api)],
      child: app,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('rejects mismatched confirmation without calling the API', (
    tester,
  ) async {
    final api = _FakeAuthApi();
    await _openDialog(tester, api);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'oldpass');
    await tester.enterText(fields.at(1), 'newpass1');
    await tester.enterText(fields.at(2), 'newpass2');
    await tester.tap(find.text('Update password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(api.calls, 0);
  });

  testWidgets('sends current and new password, then confirms', (tester) async {
    final api = _FakeAuthApi();
    await _openDialog(tester, api);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'oldpass');
    await tester.enterText(fields.at(1), 'newpass1');
    await tester.enterText(fields.at(2), 'newpass1');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(api.calls, 1);
    expect(api.current, 'oldpass');
    expect(api.next, 'newpass1');
    expect(find.text('Change Password'), findsNothing);
    expect(find.text('Password updated.'), findsOneWidget);
  });

  testWidgets('mobile dark mode recolors the sheet, fields and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeAuthApi();
    await _openDialog(tester, api, dark: true);

    final title = tester.widget<Text>(find.text('Change Password'));
    expect(title.style?.color, CScholarMobileColors.inkDark);

    final label = tester.widget<Text>(find.text('CURRENT PASSWORD'));
    expect(label.style?.color, CScholarMobileColors.mutedDark);

    final field = find.byType(TextField).first;
    final wells = tester.widgetList<AnimatedContainer>(
      find.ancestor(of: field, matching: find.byType(AnimatedContainer)),
    );
    expect(
      wells.any(
        (well) =>
            (well.decoration as BoxDecoration?)?.color ==
            CScholarMobileColors.surfaceSoftDark,
      ),
      isTrue,
      reason: 'the field well must use the dark mobile fill, not light clay',
    );

    final cancel = tester.widget<Text>(find.text('Cancel'));
    expect(cancel.style?.color, CScholarMobileColors.inkDark);

    // Cancel left, Update right — never stacked.
    final cancelCenter = tester.getCenter(find.text('Cancel'));
    final updateCenter = tester.getCenter(find.text('Update password'));
    expect(cancelCenter.dy, updateCenter.dy);
    expect(cancelCenter.dx, lessThan(updateCenter.dx));
  });

  testWidgets('shows the server sentence when the current password is wrong', (
    tester,
  ) async {
    final api = _FakeAuthApi()
      ..error = ApiException(
        401,
        '{"detail":"Current password is incorrect"}',
      );
    await _openDialog(tester, api);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'wrongpass');
    await tester.enterText(fields.at(1), 'newpass1');
    await tester.enterText(fields.at(2), 'newpass1');
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.calls, 1);
    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
  });
}
