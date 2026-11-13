import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';

/// Every dialog goes through [GlassDialog], so one layout contract here keeps
/// all of them symmetrical: content spans the panel's inner width (even when a
/// call site still passes a fixed-width SizedBox) and the action group is
/// centred on the panel axis.
void main() {
  testWidgets('GlassDialog fills its width and centres its actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final nameCtrl = TextEditingController();
    addTearDown(nameCtrl.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: GlassDialog(
                title: const Text('Add Program'),
                // A legacy call site: the shell must override this width.
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeumorphField(
                        key: const Key('field'),
                        controller: nameCtrl,
                        label: 'Name *',
                      ),
                    ],
                  ),
                ),
                actions: const [
                  NeumorphButton(label: 'Cancel', gel: false),
                  NeumorphButton(label: 'Save'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panelRect = tester.getRect(find.byType(GlassPanel));
    final fieldRect = tester.getRect(find.byKey(const Key('field')));
    final cancelRect = tester.getRect(find.byType(NeumorphButton).first);
    final saveRect = tester.getRect(find.byType(NeumorphButton).last);

    // GlassDialog's horizontal padding is 24 on each side.
    expect(fieldRect.width, closeTo(panelRect.width - 48, 1));
    // Equal space to the left and right of the button group.
    expect(
      (cancelRect.left + saveRect.right) / 2,
      closeTo(panelRect.center.dx, 1),
    );
  });
}
