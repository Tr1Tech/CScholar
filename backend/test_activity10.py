import json, urllib.request, os, time

BASE = "http://localhost:5000"
RESULTS = []
TS = str(int(time.time()))

def req(method, path, data=None, token=None, form=None, files=None):
    url = BASE + path
    headers = {}
    if token:
        headers["Authorization"] = "Bearer " + token
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
        r = urllib.request.Request(url, data=body, headers=headers, method=method)
    elif files:
        boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        body = b""
        for k, v in (form or {}).items():
            body += ("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" % (boundary, k, v)).encode()
        for fn, fb in files.items():
            body += ("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\nContent-Type: application/pdf\r\n\r\n" % (boundary, fn)).encode() + fb + b"\r\n"
        body += ("--%s--\r\n" % boundary).encode()
        headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
        r = urllib.request.Request(url, data=body, headers=headers, method=method)
    else:
        r = urllib.request.Request(url, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read().decode(errors="replace")
            try: bodyj = json.loads(raw)
            except: bodyj = raw[:300]
            return resp.status, bodyj
    except urllib.error.HTTPError as e:
        raw = e.read().decode(errors="replace")
        try: bodyj = json.loads(raw)
        except: bodyj = raw[:300]
        return e.code, bodyj
    except Exception as e:
        return 0, str(e)

def R(fid, method, path, **kw):
    st, body = req(method, path, **kw)
    RESULTS.append({"id": fid, "method": method, "path": path, "status": st, "body": (body if not isinstance(body, str) else body[:200])})
    print(f"{fid}: {method} {path} -> {st}")
    return st, body

# Health
R("H1", "GET", "/health")
R("H2", "GET", "/api/health")
R("H3", "GET", "/api/db-test")

# Auth
st, body = req("POST", "/api/auth/login", {"email": "admin@csu.edu.ph", "password": "admin123"})
admin_token = body.get("token") if isinstance(body, dict) else None
R("A1", "POST", "/api/auth/login", data={"email": "admin@csu.edu.ph", "password": "admin123"})
R("A2", "GET", "/api/auth/me", token=admin_token)
R("A3", "GET", "/api/users", token=admin_token)

uname = "testuser_" + TS
R("A4", "POST", "/api/auth/register", data={"username": uname, "email": uname + "@csu.edu.ph", "password": "test1234"})
st, body = req("POST", "/api/auth/login", {"email": uname + "@csu.edu.ph", "password": "test1234"})
test_token = body.get("token") if isinstance(body, dict) else None

fname = "faculty_" + TS
R("A5", "POST", "/api/users", data={"username": fname, "email": fname + "@csu.edu.ph", "password": "secret123", "role": "faculty"}, token=admin_token)
st, users = req("GET", "/api/users", token=admin_token)
faculty_user = None
if isinstance(users, list):
    for u in users:
        if u.get("username") == fname:
            faculty_user = u
faculty_user_id = faculty_user["id"] if faculty_user else None
if faculty_user_id:
    R("A6", "PUT", f"/api/users/{faculty_user_id}", data={"role": "faculty"}, token=admin_token)
    R("A7", "PUT", f"/api/users/{faculty_user_id}/active", data={"is_active": True}, token=admin_token)

st, body = req("POST", "/api/auth/login", {"email": fname + "@csu.edu.ph", "password": "secret123"})
faculty_token = body.get("token") if isinstance(body, dict) else None

# Meta GETs
for p, fid in [("/api/programs", "M1"), ("/api/academic-years", "M2"), ("/api/categories", "M3"), ("/api/keywords", "M4"), ("/api/authors", "M5"), ("/api/advisers", "M6"), ("/api/research-types", "M7")]:
    R(fid, "GET", p)

st, programs = req("GET", "/api/programs")
st, years = req("GET", "/api/academic-years")
st, categories = req("GET", "/api/categories")
st, authors = req("GET", "/api/authors")
st, advisers = req("GET", "/api/advisers")
program_id = programs[0]["id"] if isinstance(programs, list) and programs else 1
year_id = years[0]["id"] if isinstance(years, list) and years else 1
category_id = categories[0]["id"] if isinstance(categories, list) and categories else 1
author_id = authors[0]["id"] if isinstance(authors, list) and authors else 1
adviser_id = advisers[0]["id"] if isinstance(advisers, list) and advisers else 1

# Meta CRUD
st, b = R("M8", "POST", "/api/authors", data={"first_name": "Test", "last_name": "Author", "email": "testauthor_" + TS + "@csu.edu.ph"}, token=admin_token)
new_author_id = b.get("id") if isinstance(b, dict) else None
if new_author_id:
    R("M9", "PUT", f"/api/authors/{new_author_id}", data={"last_name": "AuthorUpdated"}, token=admin_token)
    R("M10", "DELETE", f"/api/authors/{new_author_id}", token=admin_token)

st, b = R("M11", "POST", "/api/advisers", data={"first_name": "Test", "last_name": "Adviser", "email": "testadviser_" + TS + "@csu.edu.ph"}, token=admin_token)
new_adv = b.get("id") if isinstance(b, dict) else None
if new_adv:
    R("M12", "PUT", f"/api/advisers/{new_adv}", data={"last_name": "AdviserUpdated"}, token=admin_token)
    R("M13", "DELETE", f"/api/advisers/{new_adv}", token=admin_token)

st, b = R("M14", "POST", "/api/categories", data={"name": "TestCategory_" + TS, "description": "desc"}, token=admin_token)
new_cat = b.get("id") if isinstance(b, dict) else None
if new_cat:
    R("M15", "PUT", f"/api/categories/{new_cat}", data={"description": "updated"}, token=admin_token)
    R("M16", "DELETE", f"/api/categories/{new_cat}", token=admin_token)

st, b = R("M17", "POST", "/api/programs", data={"name": "TestProg_" + TS, "code": "TPA", "description": "desc"}, token=admin_token)
new_prog = b.get("id") if isinstance(b, dict) else None
if new_prog:
    R("M18", "PUT", f"/api/programs/{new_prog}", data={"description": "updated"}, token=admin_token)
    R("M19", "DELETE", f"/api/programs/{new_prog}", token=admin_token)

st, b = R("M20", "POST", "/api/academic-years", data={"name": "2099-2100", "start_year": 2099, "end_year": 2100, "is_active": False}, token=admin_token)
new_year = b.get("id") if isinstance(b, dict) else None
if new_year:
    R("M21", "PUT", f"/api/academic-years/{new_year}", data={"is_active": True}, token=admin_token)
    R("M22", "DELETE", f"/api/academic-years/{new_year}", token=admin_token)

# Theses
R("T1", "GET", "/api/theses")
st, theses = req("GET", "/api/theses")
thesis_id = None
if isinstance(theses, dict) and theses.get("theses"):
    thesis_id = theses["theses"][0]["id"]
elif isinstance(theses, list) and theses:
    thesis_id = theses[0]["id"]
if thesis_id:
    R("T2", "GET", f"/api/theses/{thesis_id}")
    R("T3", "GET", f"/api/theses/{thesis_id}/recommend")
    R("T4", "GET", f"/api/theses/{thesis_id}/pdf", token=admin_token)

st, b = R("T5", "POST", "/api/theses", data={
    "title": "Activity10 Test Thesis",
    "abstract": "This is a test thesis for activity 10.",
    "research_type": "Capstone",
    "program_id": program_id,
    "academic_year_id": year_id,
    "status": "draft",
    "author_ids": [author_id],
    "adviser_id": adviser_id,
    "category_ids": [category_id],
    "keyword_terms": ["testing", "activity10"],
}, token=admin_token)
new_thesis_id = b.get("id") if isinstance(b, dict) else None

if new_thesis_id:
    R("T6", "PUT", f"/api/theses/{new_thesis_id}", data={"title": "Activity10 Test Thesis Updated"}, token=admin_token)
    # upload a PDF to this thesis, then fetch it
    try:
        import fitz
        doc = fitz.open(); pg = doc.new_page(); pg.insert_text((72, 72), "activity10 pdf"); pdfb = doc.tobytes(); doc.close()
        boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        body = ("--" + boundary + "\r\nContent-Disposition: form-data; name=\"file\"; filename=\"a.pdf\"\r\nContent-Type: application/pdf\r\n\r\n").encode() + pdfb + ("\r\n--" + boundary + "\r\nContent-Disposition: form-data; name=\"thesis_id\"\r\n\r\n" + str(new_thesis_id) + "\r\n--" + boundary + "--\r\n").encode()
        rr = urllib.request.Request("http://localhost:5000/api/upload/pdf", data=body, headers={"Authorization": "Bearer " + admin_token, "Content-Type": "multipart/form-data; boundary=" + boundary}, method="POST")
        urllib.request.urlopen(rr).read()
    except Exception as e:
        print("upload-to-thesis err", e)
    R("TPDF", "GET", f"/api/theses/{new_thesis_id}/pdf", token=admin_token)
    R("E1", "POST", f"/api/embeddings/generate/{new_thesis_id}", token=admin_token)
    R("T7", "DELETE", f"/api/theses/{new_thesis_id}", token=admin_token)

R("E2", "GET", "/api/embeddings/bulk-status", token=admin_token)
R("E3", "POST", "/api/embeddings/generate-bulk", token=admin_token)
R("E4", "POST", "/api/embeddings/search", data={"query": "machine learning", "limit": 5}, token=admin_token)

# Dashboard
R("D1", "GET", "/api/dashboard/stats", token=admin_token)
R("D2", "GET", "/api/dashboard/recent-activity", token=admin_token)
R("D3", "GET", "/api/stats/summary")

# Faculty
if faculty_token:
    R("F1", "GET", "/api/faculty/dashboard", token=faculty_token)
    R("F2", "GET", "/api/faculty/activity", token=faculty_token)
    R("F3", "GET", "/api/faculty/theses", token=faculty_token)
    R("F4", "GET", "/api/faculty/advisees", token=faculty_token)
    R("F5", "GET", "/api/faculty/analytics", token=faculty_token)

# Upload (real PDF)
try:
    import fitz
    doc = fitz.open(); pg = doc.new_page(); pg.insert_text((72, 72), "activity10 pdf"); pdfb = doc.tobytes(); doc.close()
    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    body = ("--" + boundary + "\r\nContent-Disposition: form-data; name=\"file\"; filename=\"activity10.pdf\"\r\nContent-Type: application/pdf\r\n\r\n").encode() + pdfb + ("\r\n--" + boundary + "--\r\n").encode()
    st, body = req("POST", "/api/upload/pdf", files={"activity10.pdf": pdfb}, token=admin_token)
    RESULTS.append({"id": "U1", "method": "POST", "path": "/api/upload/pdf", "status": st, "body": (body if not isinstance(body, str) else body[:200])})
    print(f"U1: POST /api/upload/pdf -> {st}")
except Exception as e:
    RESULTS.append({"id": "U1", "method": "POST", "path": "/api/upload/pdf", "status": 0, "body": str(e)})
    print("U1 error", e)

# OCR
try:
    import fitz
    doc = fitz.open(); pg = doc.new_page(); pg.insert_text((72, 72), "activity10 ocr"); pdfb = doc.tobytes(); doc.close()
    st, body = req("POST", "/api/ocr/pdf", files={"activity10.pdf": pdfb}, token=admin_token)
    RESULTS.append({"id": "O1", "method": "POST", "path": "/api/ocr/pdf", "status": st, "body": (body if not isinstance(body, str) else body[:200])})
    print(f"O1: POST /api/ocr/pdf -> {st}")
except Exception as e:
    RESULTS.append({"id": "O1", "method": "POST", "path": "/api/ocr/pdf", "status": 0, "body": str(e)})
    print("O1 error", e)

out_dir = os.path.join(os.path.dirname(__file__), "..", "evidence")
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "test_results.json"), "w") as f:
    json.dump(RESULTS, f, indent=2, default=str)
print("Total tests:", len(RESULTS))
for r in RESULTS:
    if not (200 <= r["status"] < 300):
        print("NON-2XX:", r["id"], r["method"], r["path"], r["status"], str(r["body"])[:150])