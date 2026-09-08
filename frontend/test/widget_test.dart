import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('CScholar app starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CScholarApp()),
    );
    expect(find.text('CScholar'), findsAny);
  });
}
