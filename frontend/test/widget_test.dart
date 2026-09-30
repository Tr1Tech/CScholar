import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('CScholar app starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CScholarApp()),
    );
    // The auth entry screen owns repeating ambient motion (the drifting orbs,
    // plus the ClayLoader behind a pending request), so like the render matrix
    // this pump uses a frame budget rather than `pumpAndSettle()` — a page
    // with a repeating controller never settles, by design.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CScholar'), findsAny);
  });
}
