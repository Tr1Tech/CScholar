// Page headers pin their trailing control to the page's trailing edge.
//
// The original bug: `Flexible` next to `Expanded` both default to flex 1, so a
// header row split its slack 50/50 and the action ("Find More", "Add User", the
// repository's filter cluster) floated at the halfway mark with a dead gutter to
// the right of it. `PageHeader` is shared by thirteen screens, so one regression
// test there covers the pills; the repository builds its own strip and gets its
// own case.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/presentation/screens/repository/repository_screen.dart';
import 'package:frontend/presentation/screens/student/saved_theses_screen.dart';
import 'package:frontend/presentation/widgets/common/page_header.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';

Widget _host(Widget child, {double textScale = 1}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    );

Widget _routerHost(Widget screen) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(path: '/:rest(.*)', builder: (_, _) => screen),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

Rect _actionRect(WidgetTester tester) =>
    tester.getRect(find.byType(NeumorphButton));

void main() {
  setUp(() {
    // A desktop-width surface: wide enough that "middle of the row" and
    // "trailing edge" are hundreds of pixels apart.
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(1280, 900);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('PageHeader action is pinned to the trailing edge',
      (tester) async {
    await tester.pumpWidget(_host(
      PageHeader(
        title: 'Saved Studies',
        subtitle: 'Your bookmarked research studies and reference papers',
        action: NeumorphButton(
          onPressed: () {},
          icon: Icons.search,
          label: 'Find More',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final action = _actionRect(tester);
    final header = tester.getRect(find.byType(PageHeader));

    expect(action.right, moreOrLessEquals(header.right, epsilon: 0.5),
        reason: 'the action must end at the header trailing edge, not float in '
            'the middle of the row');
  });

  testWidgets('PageHeader title is not capped at half the row', (tester) async {
    const longTitle = 'Thesis Management Programme Archive Overview';
    await tester.pumpWidget(_host(
      PageHeader(
        title: longTitle,
        subtitle: 'Every submission in the programme, one queue.',
        action: NeumorphButton(onPressed: () {}, label: 'Add User'),
      ),
    ));
    await tester.pumpAndSettle();

    final action = _actionRect(tester);
    final header = tester.getRect(find.byType(PageHeader));
    final title = tester.getRect(find.text(longTitle));

    expect(action.width, lessThan(header.width / 3));
    expect(title.right, lessThan(action.left));
    expect(title.width, greaterThan(header.width * 0.6),
        reason: 'the title must not be capped at half the row.');
  });

  testWidgets('PageHeader action shrinks instead of overflowing at 200% text',
      (tester) async {
    await tester.pumpWidget(_host(
      const SizedBox(
        width: 420,
        child: PageHeader(
          title: 'User Management',
          subtitle: 'Accounts, roles, and access status.',
          action: NeumorphButton(icon: Icons.person_add, label: 'Add User'),
        ),
      ),
      textScale: 2,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final action = _actionRect(tester);
    final header = tester.getRect(find.byType(PageHeader));
    expect(action.right, lessThanOrEqualTo(header.right + 0.5));
  });

  testWidgets('Saved Studies "Find More" pill sits on the content edge',
      (tester) async {
    // The reported screenshot: the pill hung around the middle of the header
    // with a dead gutter to its right, while the segmented control below it ran
    // to the content edge.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpWidget(_routerHost(const SavedThesesScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    final pill = tester.getRect(find.widgetWithText(NeumorphButton, 'Find More'));
    final content = tester.getRect(find.byType(NeumorphSegmented));

    expect(pill.right, moreOrLessEquals(content.right, epsilon: 1),
        reason: 'the pill must line up with the content edge the segmented '
            'control below it sits on');
  });

  testWidgets('repository filter strip sits on its trailing edge',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpWidget(_routerHost(const RepositoryScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    // The strip row holds the title and the cluster; the cluster is its
    // trailing child. `Expanded` + `Flexible` split the row 50/50, so the title
    // column was capped at half and the visible gap between title and cluster
    // grew to a double gutter.
    final titleColumn = find
        .ancestor(
          of: find.text('Search Results'),
          matching: find.byType(Column),
        )
        .first;
    final cluster = find
        .ancestor(of: find.text('Sort: '), matching: find.byType(Wrap))
        .first;
    final titleRect = tester.getRect(titleColumn);
    final clusterRect = tester.getRect(cluster);
    final stripRow = tester.getRect(find
        .ancestor(of: find.text('Search Results'), matching: find.byType(Row))
        .evaluate()
        .map((e) => find.byWidget(e.widget))
        .firstWhere((f) => tester.getRect(f).right >= clusterRect.right));

    expect(clusterRect.right, moreOrLessEquals(stripRow.right, epsilon: 1),
        reason: 'the cluster ends on the strip trailing edge');
    expect(clusterRect.left - titleRect.right, lessThan(40),
        reason: 'the title and the cluster are separated by the designed gap, '
            'not by the double gutter a 50/50 flex split leaves');
  });
}
