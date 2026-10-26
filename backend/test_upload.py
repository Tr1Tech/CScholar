import fitz, json, urllib.request

doc = fitz.open()
p = doc.new_page()
p.insert_text((72, 72), "test upload")
b = doc.tobytes()
doc.close()

req = urllib.request.Request(
    "http://localhost:5000/api/auth/login",
    data=json.dumps({"email": "admin@csu.edu.ph", "password": "admin123"}).encode(),
    headers={"Content-Type": "application/json"},
)
token = json.loads(urllib.request.urlopen(req).read())["token"]

boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
body = (
    ("--" + boundary + "\r\n"
     "Content-Disposition: form-data; name=\"file\"; filename=\"t.pdf\"\r\n"
     "Content-Type: application/pdf\r\n\r\n").encode()
    + b
    + ("\r\n--" + boundary + "--\r\n").encode()
)

r = urllib.request.Request(
    "http://localhost:5000/api/upload/pdf",
    data=body,
    headers={"Authorization": "Bearer " + token, "Content-Type": "multipart/form-data; boundary=" + boundary},
    method="POST",
)
try:
    resp = urllib.request.urlopen(r)
    print(resp.status, resp.read().decode()[:300])
except Exception as e:
    print("ERR", e.code, e.read().decode()[:500])
