// Result card arrangement.
//
// The card carries the study's state and actions down its RIGHT edge — type
// badge at the top, the semantic match directly underneath it, and the save in
// the bottom-right corner — while "Related Research" stays on the left of the
// bottom row. The match lives in that rail rather than on the author line: a
// two-line badge on the author line pushed the authors, program and keywords
// down, leaving gaps a keyword card does not have. The title/authors/program
// rhythm must stay compact in both states, so this is measured, not eyeballed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/result_card.dart';

Thesis _thesis({List<Keyword> keywords = const []}) => Thesis(
  id: 12,
  title:
      'Tracking and Monitoring Systems of Tools, Equipments and Materials '
      'in Del Pilar National High School',
  abstract: 'Abstract.',
  researchType: 'Capstone',
  status: 'published',
  programId: 1,
  academicYearId: 1,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  keywords: keywords,
  program: Program(
    id: 1,
    code: 'BSCpE',
    name: 'Bachelor of Science in Computer Engineering',
    createdAt: DateTime(2024),
  ),
  authors: [
    Author(
      id: 1,
      firstName: 'Caesy B.',
      lastName: 'Benegildo',
      createdAt: DateTime(2024),
    ),
  ],
);

Keyword _kw(int id, String term) =>
    Keyword(id: id, term: term, createdAt: DateTime(2024));

Widget _host(Widget card, {double width = 900, double textScale = 1}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: CScholarMaterial.canvas,
          // A scroll view, like the results list: the card is content-sized,
          // never stretched to the viewport.
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(width: width, child: card),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The pill that CONTAINS [label] (its nearest decorated container).
Rect _pill(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
);

void main() {
  testWidgets('badge, match and save stack down the right edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ResultCard(
          thesis: _thesis(
            keywords: [_kw(1, 'web-based system'), _kw(2, 'tool tracking')],
          ),
          isSaved: false,
          similarity: 0.49,
          onToggleSave: () {},
        ),
        width: 860,
      ),
    );
    // Entrance animations (the badge's pop) must finish before measuring.
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(ResultCard));
    final badge = _pill(tester, 'Capstone');
    final match = _pill(tester, 'MATCH');
    final save = _pill(tester, 'Save');
    final related = _pill(tester, 'Related Research');
    final title = tester.getRect(
      find.textContaining('Tracking and Monitoring'),
    );
    final authors = tester.getRect(find.text('Caesy B. Benegildo'));
    final program = tester.getRect(
      find.textContaining('Bachelor of Science in Computer Engineering'),
    );

    // The three sit on the card's inner right edge (16px padding).
    for (final (name, pill) in [
      ('badge', badge),
      ('match', match),
      ('save', save),
    ]) {
      expect(
        pill.right,
        moreOrLessEquals(card.right - 16, epsilon: 2),
        reason: '$name is not flushed to the right edge',
      );
    }

    // The match is the rail's second item: directly under the type badge, on
    // the same right edge.
    expect(
      match.right,
      moreOrLessEquals(badge.right, epsilon: 2),
      reason: 'match must line up under the type badge',
    );
    expect(
      match.top,
      greaterThan(badge.bottom),
      reason: 'match is under the badge',
    );

    // ...and read top-to-bottom: badge, then match, then the save.
    expect(
      save.top,
      greaterThan(match.bottom),
      reason: 'save is under the match',
    );

    // The semantic badge must NOT stretch the left column: title, authors and
    // program keep the same compact rhythm as a keyword-only card.
    expect(
      authors.top - title.bottom,
      lessThanOrEqualTo(6),
      reason: 'title → authors keeps the compact gap',
    );
    expect(
      program.top - authors.bottom,
      lessThanOrEqualTo(6),
      reason: 'authors → program keeps the compact gap',
    );

    // The save owns the bottom-right corner.
    expect(
      save.bottom,
      moreOrLessEquals(card.bottom - 16, epsilon: 2),
      reason: 'the save must sit in the card’s bottom-right corner',
    );

    // Related Research keeps the left of that bottom row.
    expect(
      related.left,
      moreOrLessEquals(card.left + 16 + 92 + 16, epsilon: 2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a score the match is gone and the save still lands '
      'bottom-right', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ResultCard(
          thesis: _thesis(keywords: [_kw(1, 'IoT')]),
          isSaved: true,
          onToggleSave: () {},
        ),
        width: 860,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MATCH'), findsNothing);
    final card = tester.getRect(find.byType(ResultCard));
    final saved = _pill(tester, 'Saved');
    expect(saved.right, moreOrLessEquals(card.right - 16, epsilon: 2));
    expect(saved.bottom, moreOrLessEquals(card.bottom - 16, epsilon: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% text on a phone width stacks the actions instead of '
      'overflowing', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ResultCard(
          thesis: _thesis(
            keywords: [
              _kw(1, 'machine learning'),
              _kw(2, 'equipment inventory'),
            ],
          ),
          isSaved: false,
          similarity: 0.86,
          onToggleSave: () {},
        ),
        width: 380,
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The save is still the rightmost thing on the card, on its own line.
    final card = tester.getRect(find.byType(ResultCard));
    final save = _pill(tester, 'Save');
    expect(save.right, moreOrLessEquals(card.right - 16, epsilon: 2));
    expect(
      save.top,
      greaterThan(_pill(tester, 'Related Research').bottom),
      reason: 'at 200% text the actions stack, save below the related pill',
    );
  });
}
