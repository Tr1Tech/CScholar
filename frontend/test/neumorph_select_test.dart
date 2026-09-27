// NeumorphSelect verification — the system's ONE dropdown/select control.
//
// Covers what the tier 3 suite covers for NeumorphField, plus the defect that
// motivated the controlled/adapter split: filter bars reset their value
// EXTERNALLY ("Clear filters" sets the screen's value back to null), and a
// FormField never re-syncs initialValue after the user picks something — so
// the filters use the controlled NeumorphSelectField while forms keep the
// FormField adapter NeumorphSelect.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/inset_shadow.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';

Widget _host(
  Widget child, {
  bool highContrast = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: CScholarMaterial.canvas,
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    ),
  );
}

List<DropdownMenuItem<String>> _typeItems() => const [
      DropdownMenuItem(value: null, child: Text('All')),
      DropdownMenuItem(value: 'Thesis', child: Text('Thesis')),
      DropdownMenuItem(value: 'Capstone', child: Text('Capstone')),
    ];

BoxDecoration _wellDecoration(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.byType(DropdownButton<String>),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first
      .decoration as BoxDecoration;
}

void main() {
  group('NeumorphSelect is a Form field', () {
    testWidgets('Form.validate() runs the validator and blocks submit',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      var submitted = 0;

      await tester.pumpWidget(
        _host(Form(
          key: formKey,
          child: Column(
            children: [
              NeumorphSelect<String>(
                initialValue: null,
                hintText: 'Select research type',
                items: _typeItems(),
                onChanged: (_) {},
                validator: (v) =>
                    v == null ? 'Select a research type' : null,
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) submitted++;
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        )),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(submitted, 0);
      expect(find.text('Select a research type'), findsOneWidget);

      // Picking a value flows into field state, so validation passes after.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thesis').last);
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(submitted, 1);
      expect(find.text('Select a research type'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an explicit errorText outranks the validator',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphSelect<String>(
          initialValue: 'Thesis',
          items: _typeItems(),
          onChanged: (_) {},
          errorText: 'Submission failed',
          validator: (_) => 'Bad format',
        )),
      );
      await tester.pump();

      expect(find.text('Submission failed'), findsOneWidget);
      expect(find.text('Bad format'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled select cannot be opened', (tester) async {
      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: 'Thesis',
          items: _typeItems(),
          onChanged: null,
          enabled: false,
        )),
      );

      expect(
          tester
              .widget<DropdownButton<String>>(
                  find.byType(DropdownButton<String>))
              .onChanged,
          isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('NeumorphSelect well invariants', () {
    testWidgets('rest state is a recessed clay well with a rim',
        (tester) async {
      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: 'Thesis',
          items: _typeItems(),
          onChanged: (_) {},
          hintText: 'Select research type',
        )),
      );

      final well = _wellDecoration(tester);
      expect(well.color, CScholarMaterial.clayDeep);
      expect((well.border as Border).top.color, CScholarMaterial.rim);
      expect(find.text('Thesis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('focus thickens the rim to the gel brand colour',
        (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: 'Thesis',
          items: _typeItems(),
          onChanged: (_) {},
          focusNode: focus,
        )),
      );

      focus.requestFocus();
      await tester.pump();

      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarMaterial.gelTop);
      expect(border.top.width, 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an error tints the rim', (tester) async {
      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: null,
          items: _typeItems(),
          onChanged: (_) {},
          errorText: 'Select a research type',
        )),
      );

      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarColors.error);
      expect(find.text('Select a research type'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('high contrast drops the inset and strengthens the rim',
        (tester) async {
      await tester.pumpWidget(
        _host(
          NeumorphSelectField<String>(
            value: 'Thesis',
            items: _typeItems(),
            onChanged: (_) {},
          ),
          highContrast: true,
        ),
      );

      final border = _wellDecoration(tester).border as Border;
      expect(border.top.color, CScholarMaterial.rimStrong);

      final inset = tester.widget<InsetShadow>(
        find.descendant(
          of: find.byType(NeumorphSelectField<String>),
          matching: find.byType(InsetShadow),
        ),
      );
      expect(inset.shadows, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a hint shows when nothing is selected', (tester) async {
      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: null,
          items: const [
            DropdownMenuItem(value: 'Thesis', child: Text('Thesis')),
          ],
          onChanged: (_) {},
          hintText: 'Select research type',
        )),
      );

      expect(find.text('Select research type'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('NeumorphSelectField follows external resets', () {
    testWidgets('resetting the value to null updates the displayed label',
        (tester) async {
      // The repository's _clearFilters() shape: the screen owns the value and
      // sets it back to null; the well must follow.
      String? value = 'Thesis';
      late StateSetter setOuter;

      await tester.pumpWidget(
        _host(StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return NeumorphSelectField<String>(
              value: value,
              items: _typeItems(),
              onChanged: (v) => setState(() => value = v),
            );
          },
        )),
      );

      expect(find.text('Thesis'), findsOneWidget);

      setOuter(() => value = null);
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Thesis'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picks report through onChanged', (tester) async {
      String? picked;

      await tester.pumpWidget(
        _host(NeumorphSelectField<String>(
          value: null,
          items: _typeItems(),
          onChanged: (v) => picked = v,
        )),
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capstone').last);
      await tester.pump();

      expect(picked, 'Capstone');
      expect(tester.takeException(), isNull);
    });
  });
}
