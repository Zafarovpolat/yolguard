"""Смоук-тест ядра: регистрация -> авто -> дело -> право -> присоединение B -> подтверждения -> доказательство -> пакет."""
import json, urllib.request, urllib.error, io, random

BASE = "http://127.0.0.1:8000"
SUFFIX = f"{random.randint(0, 9999999):07d}"  # уникальные телефоны на каждый запуск
PHONE_A = "+99890" + SUFFIX
PHONE_B = "+99891" + SUFFIX


def call(method, path, token=None, json_body=None, multipart=None):
    url = BASE + path
    headers = {}
    data = None
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if json_body is not None:
        data = json.dumps(json_body).encode()
        headers["Content-Type"] = "application/json"
    if multipart is not None:
        boundary = "----yolg"
        buf = io.BytesIO()
        for k, v in multipart["fields"].items():
            buf.write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode())
        fn = multipart["file"]["filename"]
        fc = multipart["file"]["content"]
        buf.write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{fn}\"\r\nContent-Type: image/jpeg\r\n\r\n".encode())
        buf.write(fc)
        buf.write(f"\r\n--{boundary}--\r\n".encode())
        data = buf.getvalue()
        headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read().decode()
            return r.status, json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def ok(label, status, want=(200, 201)):
    mark = "OK " if status in want else "FAIL"
    print(f"[{mark}] {label} -> {status}")
    assert status in want, f"{label}: {status}"


# 1. Водитель A
st, a = call("POST", "/api/auth/register", json_body={"phone": PHONE_A, "password": "pass123", "full_name": "Driver A"})
ok("register A", st); ta = a["access_token"]

# 2. Авто A
st, va = call("POST", "/api/vehicles", token=ta, json_body={"make": "Chevrolet", "model": "Cobalt", "plate": "01A111AA", "year": 2021})
ok("vehicle A", st); va_id = va["id"]

# 3. Дело
st, case = call("POST", "/api/cases", token=ta, json_body={"vehicle_id": va_id, "address": "Ташкент, Чиланзар"})
ok("create case", st); cid = case["id"]; code = case["join_code"]
print("    join_code:", code, "status:", case["status"])

# 4. Вопросы визарда
st, q = call("GET", "/api/cases/eligibility-questions", token=ta)
ok("wizard questions", st); print("    questions:", len(q["questions"]))

# 5. Право — всё чисто -> green
answers = {"anyone_injured": False, "pedestrian_involved": False, "vehicle_count": 2,
           "third_party_property_damaged": False, "both_insured": True, "documents_valid": True,
           "intoxication_suspected": False, "damage_disagreement": False, "fault_accepted": True}
st, elig = call("POST", f"/api/cases/{cid}/eligibility", token=ta, json_body={"answers": answers})
ok("eligibility green", st); print("    result:", elig["result"], "rules:", elig["rules_version"])
assert elig["result"] == "green"

# 5b. Право — травма -> red
st, elig2 = call("POST", f"/api/cases/{cid}/eligibility", token=ta, json_body={"answers": {**answers, "anyone_injured": True}})
ok("eligibility red", st); print("    result:", elig2["result"], "reasons:", [r["code"] for r in elig2["reasons"]])
assert elig2["result"] == "red"
# вернём обратно green для дальнейшего флоу
call("POST", f"/api/cases/{cid}/eligibility", token=ta, json_body={"answers": answers})

# 6. Водитель B присоединяется по коду
st, b = call("POST", "/api/auth/register", json_body={"phone": PHONE_B, "password": "pass123", "full_name": "Driver B"})
ok("register B", st); tb = b["access_token"]
st, vb = call("POST", "/api/vehicles", token=tb, json_body={"make": "Daewoo", "model": "Nexia", "plate": "01B222BB"})
ok("vehicle B", st); vb_id = vb["id"]
st, joined = call("POST", "/api/cases/join", token=tb, json_body={"join_code": code, "vehicle_id": vb_id})
ok("B joins", st); print("    participants:", len(joined["participants"]))
assert len(joined["participants"]) == 2

# 7. Схема + подтверждения
st, _ = call("PUT", f"/api/cases/{cid}/diagram", token=ta, json_body={"diagram": {"vehicles": ["A", "B"], "impact": "rear"}})
ok("diagram", st)
st, _ = call("POST", f"/api/cases/{cid}/confirm", token=ta, json_body={"accepts_fault": False})
ok("A confirm", st)
st, cB = call("POST", f"/api/cases/{cid}/confirm", token=tb, json_body={"accepts_fault": True})
ok("B confirm", st); print("    case status:", cB["status"])

# 8. Доказательство (маленький файл -> должен зареджектиться по качеству)
st, ev = call("POST", f"/api/cases/{cid}/evidence", token=ta,
              multipart={"fields": {"category": "scene", "kind": "photo"},
                         "file": {"filename": "scene.jpg", "content": b"x" * 1000}})
ok("upload small photo", st); print("    quality:", ev["quality_status"], "sha:", ev["sha256"][:12])

# большой файл -> ok
st, ev2 = call("POST", f"/api/cases/{cid}/evidence", token=ta,
               multipart={"fields": {"category": "damage", "kind": "photo"},
                          "file": {"filename": "dmg.jpg", "content": b"y" * 60000}})
ok("upload big photo", st); print("    quality:", ev2["quality_status"])

# 9. Пакет для страховой
st, pkg = call("POST", f"/api/cases/{cid}/claim-package", token=ta)
ok("claim package", st)
print("    package: participants=%d evidence=%d eligibility=%s" % (
    len(pkg["participants"]), len(pkg["evidence"]), pkg["case"]["eligibility"]))

print("\nВСЕ ПРОВЕРКИ ПРОШЛИ")
