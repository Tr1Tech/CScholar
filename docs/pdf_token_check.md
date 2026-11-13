# PDF token access check (Phase 4)

Date: 2026-11-04
Thesis: `15` (OCR-based Hybrid Image Text Summarizer, has `pdf_url` + full relations)
User: `demo@csu.edu.ph` (student)

## Why no code change was needed

Browsers cannot attach an `Authorization` header to a new-tab navigation, so the
frontend appends the JWT as `?token=` and the backend accepts either the Bearer
header or the query parameter.

### Frontend

`frontend/lib/presentation/screens/thesis/thesis_detail_screen.dart:1217-1236`

```dart
void _openPdfInNewTab(BuildContext context, WidgetRef ref, String url) async {
  // Browsers can't set Authorization headers, so the token travels as
  // ?token= (backend validates it exactly like the Bearer header).
  final token = ref.read(apiServiceProvider).token;
  final base = Uri.parse(url);
  final uri = token == null
      ? base
      : base.replace(queryParameters: {'token': token});
  ...
  await launchUrl(uri, webOnlyWindowName: '_blank');
```

Call site (`:1210-1214`) builds `${AppConfig.apiBaseUrl}/api/theses/$thesisId/pdf`
and routes it through `_openPdfInNewTab`.

### Backend

`backend/app/routes/auth.py:199-218`

```python
@router.get("/api/theses/{thesis_id}/pdf", tags=["Theses"])
def get_thesis_pdf(
    thesis_id: int,
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
):
    auth = request.headers.get("Authorization", "")
    raw_token = None
    if auth.startswith("Bearer "):
        raw_token = auth.split(" ", 1)[1]
    else:
        raw_token = request.query_params.get("token")
    if not raw_token:
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    try:
        payload = decode_token(raw_token)
        user = db.get_user_by_id(int(payload.get("sub")))
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
```

## Live verification

Student token obtained from `POST /api/auth/login` (`demo@csu.edu.ph` / `demo1234`),
length 233. The token itself is intentionally not committed here.

| Request | Status |
| --- | --- |
| `GET /api/theses/15/pdf?token=<student JWT>` | **200** |
| `GET /api/theses/15/pdf?token=invalid` | 401 |
| `GET /api/theses/15/pdf` (no token) | 401 |

Command used:

```bat
curl -o NUL -w "%{http_code}" "http://localhost:5000/api/theses/15/pdf?token=<student JWT>"
:: 200
```

Conclusion: the PDF new-tab flow authenticates through the query token as designed;
invalid or missing tokens are rejected. No mobile Phase 4 source change was required.
