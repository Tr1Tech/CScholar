// The active pill must TRAVEL between rows, not blink from one to the next.
// Both rails are rebuilt on every route change (each screen owns its shell), so
// the slide only works if the rail remembers the row it came from — these lock
// that behaviour in, on the sidebar and on the mobile bottom nav.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/presentation/widgets/common/clay_nav_list.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_student_nav.dart';

const _stride = ClayNavList.rowHeight + ClayNavList.gap; // 46

Widget _rail(int index, {Key? key}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 248,
        child: ClayNavList(
          key: key,
          rail: 'test-rail',
          selectedIndex: index,
          links: [
            for (var i = 0; i < 4; i++)
              ClayNavLink(
                label: 'Row $i',
                icon: Icons.circle_outlined,
                selectedIcon: Icons.circle,
                onTap: () {},
              ),
          ],
        ),
      ),
    ),
  ),
);

Widget _nav(int index, {Key? key}) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: MobileStudentNav(key: key, currentIndex: index),
    ),
  ),
);

double _pillOffset(WidgetTester tester, Type host) =>
    tester.getTopLeft(find.byType(AnimatedPositioned)).dy -
    tester.getTopLeft(find.byType(host)).dy;

double _pillLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byType(AnimatedPositioned)).dx -
    tester.getTopLeft(find.byType(MobileStudentNav)).dx;

void main() {
  testWidgets('the rail pill glides from the row the last page left', (
    tester,
  ) async {
    await tester.pumpWidget(_rail(0));
    await tester.pump();
    expect(_pillOffset(tester, ClayNavList), 0);

    // A route change throws the rail's State away: same rail, new element.
    await tester.pumpWidget(_rail(2, key: UniqueKey()));
    expect(
      _pillOffset(tester, ClayNavList),
      0,
      reason: 'the first frame still sits on the row we came from',
    );

    await tester.pump(); // the frame that starts the glide
    await tester.pump(const Duration(milliseconds: 75));
    final mid = _pillOffset(tester, ClayNavList);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(2 * _stride));

    await tester.pumpAndSettle();
    expect(_pillOffset(tester, ClayNavList), closeTo(2 * _stride, 0.5));
  });

  testWidgets('the mobile fill slides between tabs', (tester) async {
    await tester.pumpWidget(_nav(0));
    await tester.pump();
    // Its rest offset is the nav's padding + rim, so measure the delta.
    final start = _pillLeft(tester);

    await tester.pumpWidget(_nav(2, key: UniqueKey()));
    expect(
      _pillLeft(tester),
      closeTo(start, 0.5),
      reason: 'the first frame still sits under the tab we came from',
    );

    final cell = (tester.getSize(find.byType(MobileStudentNav)).width - 16) / 4;

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    final mid = _pillLeft(tester);
    expect(mid, greaterThan(start));
    expect(mid, lessThan(start + 2 * cell));

    await tester.pumpAndSettle();
    expect(_pillLeft(tester), closeTo(start + 2 * cell, 0.5));
  });

  testWidgets('nav glyphs are static — only the pill travels', (tester) async {
    // A morphing or scaling glyph competes with the travelling pill and makes
    // every page change read as a flicker. The glyph may swap instantly, but
    // it must not animate.
    await tester.pumpWidget(_rail(0));
    await tester.pump();
    for (final animated in [MorphIcon, AnimatedScale, AnimatedSlide]) {
      expect(
        find.descendant(
          of: find.byType(ClayNavList),
          matching: find.byType(animated),
        ),
        findsNothing,
        reason: 'the rail glyph must not animate ($animated)',
      );
    }

    await tester.pumpWidget(_nav(0));
    await tester.pump();
    for (final animated in [MorphIcon, AnimatedScale, AnimatedSlide]) {
      expect(
        find.descendant(
          of: find.byType(MobileStudentNav),
          matching: find.byType(animated),
        ),
        findsNothing,
        reason: 'the bottom-nav glyph must not animate ($animated)',
      );
    }
  });
}
