import os
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
import psycopg
conn = psycopg.connect(os.environ["DATABASE_URL"], options="-c search_path=ceit_repo")
cur = conn.cursor()
cur.execute("SELECT id, length(abstract), (abstract ~ '[\\n\\r]') FROM theses WHERE abstract IS NOT NULL AND abstract <> '' ORDER BY id")
for r in cur.fetchall():
    print(r)
cur.execute("SELECT id, abstract FROM theses WHERE abstract ~ '[\\n\\r]' LIMIT 1")
row = cur.fetchone()
print('---SAMPLE---')
if row:
    print('thesis id:', row[0])
    print(repr(row[1][:800]))
else:
    print('no multiline abstract')
conn.close()
