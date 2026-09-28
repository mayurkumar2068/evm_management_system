"""Load official district / AC boundaries from a GeoJSON FeatureCollection.

    python -m scripts.load_boundaries districts  path/to/districts.geojson
    python -m scripts.load_boundaries acs        path/to/acs.geojson

Feature properties used:
  districts: code (e.g. BPL), name_en, name_hi (optional), state_code (optional, default MP)
  acs:       code (e.g. AC-152), ac_no, name_en, name_hi (optional), district_code
Existing rows (matched by code) are updated; new ones are inserted.
"""
import json
import sys

from sqlalchemy import select

from app.db.session import SessionLocal
from app.models import Constituency, District
from app.services import geo


def load(kind: str, path: str) -> int:
    fc = json.load(open(path, encoding="utf-8"))
    db = SessionLocal()
    n = 0
    for f in fc["features"]:
        p = f["properties"]
        if kind == "districts":
            row = db.scalar(select(District).where(District.code == p["code"])) or District(code=p["code"])
            row.name_en, row.name_hi = p["name_en"], p.get("name_hi")
            row.state_code = p.get("state_code", row.state_code or "MP")
            table = "districts"
        else:
            d = db.scalar(select(District).where(District.code == p["district_code"]))
            if d is None:
                raise SystemExit(f"Unknown district_code {p['district_code']} for AC {p['code']}")
            row = db.scalar(select(Constituency).where(Constituency.code == p["code"])) or Constituency(code=p["code"])
            row.district_id, row.ac_no = d.id, int(p["ac_no"])
            row.name_en, row.name_hi = p["name_en"], p.get("name_hi")
            table = "constituencies"
        db.add(row)
        db.flush()
        geo.set_boundary(db, table, row.id, f["geometry"])
        n += 1
    db.commit()
    db.close()
    return n


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in ("districts", "acs"):
        raise SystemExit(__doc__)
    print(f"Loaded {load(sys.argv[1], sys.argv[2])} {sys.argv[1]}")
