import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/thesis.dart';

/// The detail payload is the only one that selects the approval trail, so the
/// model must carry it and still tolerate list rows that omit it.
void main() {
  Map<String, dynamic> baseJson() => {
    'id': 32,
    'title': 'Edge-Driven Crop Disease Detection',
    'abstract': 'Abstract.',
    'research_type': 'Thesis',
    'status': 'approved',
    'program_id': 2,
    'academic_year_id': 1,
    'created_at': '2026-11-06T10:00:00',
    'updated_at': '2026-11-06T10:00:00',
  };

  test('parses the approval trail and review notes', () {
    final thesis = Thesis.fromJson({
      ...baseJson(),
      'approved_by': 5,
      'approved_by_name': 'admin1',
      'approved_at': '2026-11-07T00:53:13.875080',
      'review_notes': 'Tighten the methodology.',
    });

    expect(thesis.status, 'approved');
    expect(thesis.approvedBy, 5);
    expect(thesis.approvedByName, 'admin1');
    expect(thesis.approvedAt, DateTime.parse('2026-11-07T00:53:13.875080'));
    expect(thesis.reviewNotes, 'Tighten the methodology.');
  });

  test('parses the review history, newest first', () {
    final thesis = Thesis.fromJson({
      ...baseJson(),
      'review_notes': 'Tighten the methodology.',
      'reviews': [
        {
          'id': 3,
          'decision': 'draft',
          'notes': 'Tighten the methodology.',
          'reviewer_id': 5,
          'reviewer_name': 'admin1',
          'created_at': '2026-11-07T01:00:00',
        },
        {
          'id': 2,
          'decision': 'approved',
          'notes': null,
          'reviewer_id': 5,
          'reviewer_name': 'admin1',
          'created_at': '2026-11-06T12:00:00',
        },
      ],
    });

    final reviews = thesis.reviews!;
    expect(reviews, hasLength(2));
    expect(reviews.first.decision, 'draft');
    expect(reviews.first.notes, 'Tighten the methodology.');
    expect(reviews.first.reviewerName, 'admin1');
    expect(reviews.first.createdAt, DateTime.parse('2026-11-07T01:00:00'));
    expect(reviews.last.notes, isNull);
  });

  test('list rows without the approval columns parse to nulls', () {
    final thesis = Thesis.fromJson(baseJson());

    expect(thesis.approvedBy, isNull);
    expect(thesis.approvedByName, isNull);
    expect(thesis.approvedAt, isNull);
    expect(thesis.reviewNotes, isNull);
    expect(thesis.reviews, isNull);
    // A payload that predates the retention columns is deletable-as-before.
    expect(thesis.retained, isFalse);
    expect(thesis.everPublished, isNull);
    expect(thesis.accessionNo, isNull);
  });

  test('parses the retention facts behind a withheld delete', () {
    final thesis = Thesis.fromJson({
      ...baseJson(),
      'ever_published': true,
      'accession_no': '0142',
      'retained': true,
    });

    expect(thesis.retained, isTrue);
    expect(thesis.everPublished, isTrue);
    expect(thesis.accessionNo, '0142');
  });

  test('names why a draft may or may not be deleted', () {
    expect(
      Thesis.fromJson({...baseJson(), 'status': 'draft'}).draftOrigin,
      'NEVER PUBLISHED',
    );
    expect(
      Thesis.fromJson({
        ...baseJson(),
        'status': 'draft',
        'retained': true,
        'ever_published': true,
      }).draftOrigin,
      'PUBLISHED BEFORE',
    );
    expect(
      Thesis.fromJson({
        ...baseJson(),
        'status': 'draft',
        'retained': true,
        'ever_published': false,
        'accession_no': '0142',
      }).draftOrigin,
      'ACCESSIONED',
    );
    // Non-drafts carry no origin note; the status chip says it.
    expect(Thesis.fromJson(baseJson()).draftOrigin, isNull);
  });
}
