"""Demo data for local development: one district, two ACs, three squads and one user per role.

The boundaries here are ROUGH RECTANGLES for testing only. Load the official district
and AC boundary GeoJSON before real use (see README: "Loading real boundaries").

    python -m scripts.seed_demo
All demo officials get password: Demo@12345
"""
from sqlalchemy import select

from app.core.security import hash_password, new_uuid
from app.db.session import SessionLocal
from app.models import Constituency, District, FlyingSquad, SquadArea, User
from app.services import geo

PASSWORD = "Demo@12345"


def box(lng1, lat1, lng2, lat2) -> dict:
    return {"type": "Polygon", "coordinates": [[[lng1, lat1], [lng2, lat1], [lng2, lat2], [lng1, lat2], [lng1, lat1]]]}


def seed(db=None) -> dict:
    own = db is None
    db = db or SessionLocal()
    if db.scalar(select(District).where(District.code == "BPL")):
        print("Demo data already present")
        return {}
    d = District(code="BPL", name_en="Bhopal", name_hi="भोपाल", state_code="MP")
    db.add(d)
    db.flush()
    geo.set_boundary(db, "districts", d.id, box(77.20, 23.05, 77.60, 23.45))
    ac1 = Constituency(district_id=d.id, ac_no=152, code="AC-152", name_en="Narela [demo]", name_hi="नरेला")
    ac2 = Constituency(district_id=d.id, ac_no=151, code="AC-151", name_en="Bhopal Madhya [demo]", name_hi="भोपाल मध्य")
    db.add_all([ac1, ac2])
    db.flush()
    geo.set_boundary(db, "constituencies", ac1.id, box(77.42, 23.22, 77.50, 23.30))
    geo.set_boundary(db, "constituencies", ac2.id, box(77.36, 23.22, 77.42, 23.30))

    squads = []
    for code, lat, lng in (("FS-01", 23.2400, 77.4500), ("FS-02", 23.2601, 77.4290), ("FS-03", 23.2800, 77.3900)):
        s = FlyingSquad(code=code, district_id=d.id, status="AVAILABLE", vehicle_no=f"MP04-{code[-2:]}00")
        s.last_location = geo.point(lat, lng)
        db.add(s)
        squads.append(s)
    db.flush()
    for s in squads:
        db.add_all([SquadArea(squad_id=s.id, ac_id=ac1.id), SquadArea(squad_id=s.id, ac_id=ac2.id)])

    pw = hash_password(PASSWORD)

    def official(role, username, mobile, name, **kw):
        u = User(uuid=new_uuid(), role=role, username=username, mobile=mobile, name=name, password_hash=pw,
                 preferred_lang="en", **kw)
        db.add(u)
        return u

    users = {
        "admin": official("ADMIN", "admin", "9000000001", "Demo Admin"),
        "dc": official("DC", "dc.bhopal", "9000000002", "Demo District Controller", district_id=d.id),
        "fs1": official("FS", "fs01.lead", "9000000003", "Demo FS-01 Magistrate", district_id=d.id, squad_id=squads[0].id),
        "fs2": official("FS", "fs02.lead", "9000000004", "Demo FS-02 Magistrate", district_id=d.id, squad_id=squads[1].id),
        "fs3": official("FS", "fs03.lead", "9000000005", "Demo FS-03 Magistrate", district_id=d.id, squad_id=squads[2].id),
        "ro1": official("RO", "ro.narela", "9000000006", "Demo RO Narela", district_id=d.id, ac_id=ac1.id),
        "ro2": official("RO", "ro.madhya", "9000000007", "Demo RO Madhya", district_id=d.id, ac_id=ac2.id),
        "deo": official("DEO", "deo.bhopal", "9000000008", "Demo DEO", district_id=d.id),
        "ceo": official("CEO", "ceo.mp", "9000000009", "Demo CEO"),
    }
    db.flush()
    for s, key in zip(squads, ("fs1", "fs2", "fs3")):
        s.leader_user_id = users[key].id
    db.commit()
    if own:
        db.close()
    print(f"Demo data created. Officials' password: {PASSWORD}")
    return {"district": d, "acs": (ac1, ac2), "squads": squads, "users": users}


if __name__ == "__main__":
    seed()
