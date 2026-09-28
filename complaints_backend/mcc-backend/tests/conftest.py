import io
import os
import tempfile
from datetime import datetime, timezone

import pytest

TEST_DB_URL = os.environ.get("TEST_DATABASE_URL",
                             "mysql+pymysql://root:@127.0.0.1:3307/mcc_test?charset=utf8mb4")
os.environ.update({
    "DATABASE_URL": TEST_DB_URL,
    "ENV": "test",
    "STORAGE_DIR": tempfile.mkdtemp(prefix="mcc_media_"),
    "OTP_MAX_PER_15_MIN": "1000",
    "CITIZEN_MAX_COMPLAINTS_PER_HOUR": "1000",
    "ENABLE_SLA_WORKER": "false",
})

from fastapi.testclient import TestClient  # noqa: E402

from scripts import init_db, seed_demo  # noqa: E402

API = "/api/v1"
NARELA = (23.2687, 77.4352)          # inside demo AC-152 Narela
MADHYA = (23.2600, 77.4000)          # inside demo AC-151 Bhopal Madhya
OUTSIDE = (22.7196, 75.8577)         # Indore, outside demo district


@pytest.fixture(scope="session", autouse=True)
def database():
    init_db.run(TEST_DB_URL, reset=True)
    from app.db.session import SessionLocal
    db = SessionLocal()
    seed_demo.seed(db)
    db.close()
    yield


@pytest.fixture(scope="session")
def client(database):
    from app.main import app
    with TestClient(app) as c:
        yield c


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def jpeg_bytes(color=(200, 30, 30)) -> bytes:
    from PIL import Image
    buf = io.BytesIO()
    Image.new("RGB", (64, 48), color).save(buf, format="JPEG")
    return buf.getvalue()


class Api:
    def __init__(self, client: TestClient):
        self.c = client
        self._tokens: dict[str, dict] = {}

    def official(self, username: str, password: str = seed_demo.PASSWORD) -> dict:
        if username not in self._tokens:
            r = self.c.post(f"{API}/auth/login", json={"username": username, "password": password})
            assert r.status_code == 200, r.text
            ref = r.json()
            r = self.c.post(f"{API}/auth/otp/verify", json={"otp_ref": ref["otp_ref"], "otp": ref["debug_otp"]})
            assert r.status_code == 200, r.text
            self._tokens[username] = r.json()
        return {"Authorization": f"Bearer {self._tokens[username]['access']}"}

    def citizen(self, mobile: str) -> dict:
        key = f"citizen:{mobile}"
        if key not in self._tokens:
            r = self.c.post(f"{API}/auth/otp/send", json={"mobile": mobile})
            assert r.status_code == 200, r.text
            ref = r.json()
            r = self.c.post(f"{API}/auth/otp/verify",
                            json={"mobile": mobile, "otp_ref": ref["otp_ref"], "otp": ref["debug_otp"]})
            assert r.status_code == 200, r.text
            self._tokens[key] = r.json()
        return {"Authorization": f"Bearer {self._tokens[key]['access']}"}

    def get(self, path, h, **kw):
        return self.c.get(f"{API}{path}", headers=h, **kw)

    def post(self, path, h, **kw):
        return self.c.post(f"{API}{path}", headers=h, **kw)

    def patch(self, path, h, **kw):
        return self.c.patch(f"{API}{path}", headers=h, **kw)

    def put(self, path, h, **kw):
        return self.c.put(f"{API}{path}", headers=h, **kw)

    # ---- flow helpers
    def new_complaint(self, mobile="9800000001", where=NARELA, vtype="LIQUOR_DISTRIBUTION", submit=True,
                      anonymous=True) -> dict:
        h = self.citizen(mobile)
        r = self.post("/complaints", h, json={"violation_type": vtype, "description": "Liquor handed out from a van",
                                               "latitude": where[0], "longitude": where[1], "gps_accuracy_m": 8,
                                               "captured_at": now_iso(), "is_anonymous": anonymous})
        assert r.status_code == 201, r.text
        cid = r.json()["id"]
        r = self.post(f"/complaints/{cid}/media", h, files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")},
                      data={"media_type": "PHOTO", "captured_at": now_iso()})
        assert r.status_code == 201, r.text
        out = {"id": cid, "h": h}
        if submit:
            r = self.post(f"/complaints/{cid}/submit", h)
            assert r.status_code == 200, r.text
            out.update(r.json())
        return out

    def squad_id(self, code: str) -> int:
        r = self.get("/dc/squads", self.official("dc.bhopal"))
        return next(s["id"] for s in r.json()["results"] if s["code"] == code)

    def to_report_submitted(self, squad="FS-02", fs_user="fs02.lead", **kw) -> dict:
        c = self.new_complaint(**kw)
        dc = self.official("dc.bhopal")
        r = self.post(f"/dc/complaints/{c['id']}/assign", dc, json={"squad_id": self.squad_id(squad)})
        assert r.status_code == 200, r.text
        c["assignment_id"] = r.json()["assignment_id"]
        fs = self.official(fs_user)
        a = c["assignment_id"]
        for step in ("accept", "start"):
            r = self.post(f"/fs/assignments/{a}/{step}", fs)
            assert r.status_code == 200, r.text
        lat, lng = kw.get("where", NARELA)
        r = self.post(f"/fs/assignments/{a}/reached", fs, json={"lat": lat + 0.0005, "lng": lng})
        assert r.status_code == 200, r.text
        r = self.post(f"/fs/assignments/{a}/report", fs, json={
            "finding": "VIOLATION_CONFIRMED", "summary": "Liquor cartons found in the van, seized on the spot",
            "actions_taken": ["SEIZURE", "PANCHNAMA"], "recommendation": "DISPOSE",
            "seizure": {"made": True, "items": [{"type": "LIQUOR", "quantity": 48, "unit": "bottle",
                                                 "value_inr": 19200}]}})
        assert r.status_code == 200, r.text
        return c


@pytest.fixture(scope="session")
def api(client) -> Api:
    return Api(client)
