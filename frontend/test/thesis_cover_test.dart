// The list cover copies the dashboard's identity tile exactly: one white
// `article` glyph on the green gel rounded square, lifted by a green drop
// shadow. No seeded glyph rotation, no second decorative layer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/thesis_cover.dart';

void main() {
  testWidgets('cover is the green article tile', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: ThesisCover(seed: 7))),
    );

    expect(find.byType(Icon), findsOneWidget);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, ThesisCover.glyph);
    expect(icon.icon, Icons.article);
    expect(icon.color, Colors.white);

    final cover = tester.getRect(find.byType(ThesisCover));
    final glyph = tester.getRect(find.byType(Icon));
    expect(glyph.center, cover.center);

    final tile = tester.widget<Container>(find.byType(Container));
    final decoration = tile.decoration! as BoxDecoration;
    expect(
      decoration.color,
      isNull,
      reason: 'the gel fill is a gradient, not a flat swatch',
    );
    expect(
      decoration.gradient,
      ThesisCover.fill,
      reason: 'the cover copies the dashboard stat tile top-to-bottom gel',
    );
    expect(
      (decoration.gradient! as LinearGradient).colors.first,
      CScholarMaterial.actionFill,
    );
    expect(
      (decoration.gradient! as LinearGradient).colors.last,
      CScholarMaterial.actionFillRest,
    );
    expect(
      decoration.boxShadow,
      isNotEmpty,
      reason: 'the tile keeps the identity lift of the dashboard stat tile',
    );
  });

  testWidgets('the same mark is used for every seed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ThesisCover(seed: 1, width: 52, height: 64, iconSize: 22),
            ThesisCover(seed: 8, width: 52, height: 64, iconSize: 22),
          ],
        ),
      ),
    );

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons, hasLength(2));
    expect(icons.every((i) => i.icon == Icons.article), isTrue);
  });
}
