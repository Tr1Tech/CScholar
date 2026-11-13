import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/common/status_chips.dart';

/// The client-side transition map must mirror the API's `THESIS_STATUS_SOURCES`
/// and the DB's `fn_can_transition_status`; a drift shows the admin a menu
/// entry the server rejects with a 409.
void main() {
  test('archived is reversible (draft/published) but not approvable', () {
    expect(ThesisStatusTransitions.targetsFrom('archived'), {
      'draft',
      'published',
    });
    expect(ThesisStatusTransitions.allows('archived', 'draft'), isTrue);
    expect(ThesisStatusTransitions.allows('archived', 'published'), isTrue);
    expect(ThesisStatusTransitions.allows('archived', 'approved'), isFalse);
    expect(ThesisStatusTransitions.allows('archived', 'archived'), isFalse);
  });

  test('the forward lifecycle edges are unchanged', () {
    expect(ThesisStatusTransitions.targetsFrom('draft'), {
      'approved',
      'archived',
    });
    expect(ThesisStatusTransitions.allows('draft', 'approved'), isTrue);
    expect(ThesisStatusTransitions.allows('draft', 'archived'), isTrue);
    expect(ThesisStatusTransitions.targetsFrom('approved'), {
      'draft',
      'published',
    });
    expect(ThesisStatusTransitions.targetsFrom('published'), {'archived'});
  });
}
