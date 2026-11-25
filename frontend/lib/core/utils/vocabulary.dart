/// One vocabulary for status-like values (DS-11).
///
/// A role or active flag must read the same everywhere: chips, tables, detail
/// rows, settings, and screen-reader labels. Screens should call these helpers
/// instead of capitalising ad hoc, which is how the same value ended up as
/// `ADMIN`, `admin`, and `Administrator` on three screens.
library;

/// Human label for a user role. Unknown roles fall back to a neutral label
/// rather than exposing a raw database value.
String roleLabel(String? role) {
  switch ((role ?? '').trim().toLowerCase()) {
    case 'student':
      return 'Student';
    case 'faculty':
      return 'Faculty';
    case 'admin':
      return 'Administrator';
    default:
      return 'Member';
  }
}

/// Human label for an account's active flag.
String activeLabel(bool isActive) => isActive ? 'Active' : 'Inactive';

/// Title-cased label for a thesis status. Prefer
/// `ThesisStatusStyle.of(status).displayLabel` when a colour/icon is also
/// needed; this is the plain-text form for tables and spoken labels.
String thesisStatusLabel(String? status) {
  final value = (status ?? '').trim().toLowerCase();
  if (value.isEmpty) return 'Unknown';
  const canonical = {
    'published': 'Published',
    'approved': 'Approved',
    'draft': 'Draft',
    'archived': 'Archived',
  };
  return canonical[value] ?? value[0].toUpperCase() + value.substring(1);
}
