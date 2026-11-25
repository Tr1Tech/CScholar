import 'package:frontend/services/api_service.dart';

/// Turns any thrown object into copy a person can act on (CNT-4).
///
/// Errors must say what happened and what to do next — never a stack trace,
/// a raw status code, or a JSON body. Screens should pass their own
/// [fallback] for the action they were attempting; this helper only maps the
/// cases whose advice is the same everywhere.
///
/// Server validation bodies are deliberately NOT surfaced. A screen that can
/// map field errors should do that itself (the thesis/user forms parse the
/// payload); this is the last-resort message for everything else.
String userFacingError(
  Object error, {
  required String fallback,
  String? unauthorized,
}) {
  if (error is ApiException) {
    final status = error.statusCode;
    if (status == 401) {
      return unauthorized ??
          'Your session has expired. Sign in again to continue.';
    }
    if (status == 403) {
      return 'You do not have permission to do that. Ask an administrator if you think this is a mistake.';
    }
    if (status == 404) {
      return 'That item is no longer available. It may have been removed.';
    }
    if (status == 409) {
      return 'That change conflicts with existing data. Refresh the page and try again.';
    }
    if (status == 408 || status == 429) {
      return 'The request timed out. Wait a moment, then try again.';
    }
    if (status >= 500) {
      return 'The server could not complete that request. Try again in a moment.';
    }
    if (status >= 400) {
      return 'Some details were not accepted. Check them and try again.';
    }
  }
  return fallback;
}
