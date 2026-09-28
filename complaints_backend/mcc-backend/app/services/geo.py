"""Location helpers using MySQL 8 spatial functions on SRID 4326 (WGS84).

Always build points as ST_SRID(POINT(lng, lat), 4326): longitude first.
"""
from datetime import timedelta

from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.timeutil import utcnow
from app.models import Complaint, Constituency, District, FlyingSquad


def point(lat: float, lng: float):
    return func.ST_SRID(func.POINT(lng, lat), 4326)


def resolve_district_ac(db: Session, lat: float, lng: float) -> tuple[District | None, Constituency | None]:
    """Find the AC (and its district) containing the point, using boundary polygons."""
    p = point(lat, lng)
    ac = db.scalar(select(Constituency).where(Constituency.is_active.is_(True),
                                               text("constituencies.boundary IS NOT NULL"),
                                               func.ST_Contains(text("constituencies.boundary"), p)).limit(1))
    if ac:
        return ac.district, ac
    district = db.scalar(select(District).where(District.is_active.is_(True), text("districts.boundary IS NOT NULL"),
                                                func.ST_Contains(text("districts.boundary"), p)).limit(1))
    return district, None


def distance_m_to_complaint(db: Session, complaint_id: int, lat: float, lng: float) -> float:
    return float(db.scalar(select(func.ST_Distance_Sphere(text("complaints.location"), point(lat, lng)))
                           .select_from(Complaint).where(Complaint.id == complaint_id)))


def find_possible_duplicate(db: Session, c: Complaint) -> Complaint | None:
    since = utcnow() - timedelta(minutes=settings.DUPLICATE_WINDOW_MIN)
    return db.scalar(
        select(Complaint).where(
            Complaint.id != c.id,
            Complaint.violation_type_id == c.violation_type_id,
            Complaint.status.not_in(("DRAFT", "WITHDRAWN", "DUPLICATE", "DROPPED_AT_DC")),
            Complaint.submitted_at >= since,
            func.ST_Distance_Sphere(text("complaints.location"), point(c.latitude, c.longitude))
            <= settings.DUPLICATE_RADIUS_M,
        ).order_by(Complaint.submitted_at).limit(1))


def nearby_squads(db: Session, c: Complaint, limit: int = 10, only_available: bool = True) -> list[dict]:
    dist = func.ST_Distance_Sphere(text("flying_squads.last_location"), point(c.latitude, c.longitude))
    q = (select(FlyingSquad, dist.label("dist_m"))
         .where(FlyingSquad.district_id == c.district_id, FlyingSquad.is_active.is_(True),
                text("flying_squads.last_location IS NOT NULL"))
         .order_by(dist).limit(limit))
    if only_available:
        q = q.where(FlyingSquad.status == "AVAILABLE")
    out = []
    for squad, dist_m in db.execute(q):
        km = round(float(dist_m) / 1000, 2)
        out.append({"squad": squad, "distance_km": km,
                    "eta_min": max(1, round(km / settings.SQUAD_AVG_SPEED_KMPH * 60))})
    return out


def squad_lat_lng(db: Session, squad_id: int) -> tuple[float | None, float | None]:
    row = db.execute(text("SELECT ST_Latitude(last_location), ST_Longitude(last_location) "
                          "FROM flying_squads WHERE id = :id AND last_location IS NOT NULL"), {"id": squad_id}).first()
    return (float(row[0]), float(row[1])) if row else (None, None)


def boundary_geojson(db: Session, table: str, row_id: int) -> dict | None:
    import json
    assert table in ("districts", "constituencies")
    val = db.scalar(text(f"SELECT ST_AsGeoJSON(boundary) FROM {table} WHERE id = :id"), {"id": row_id})
    return json.loads(val) if val else None


def set_boundary(db: Session, table: str, row_id: int, geojson: dict | None) -> None:
    import json
    assert table in ("districts", "constituencies")
    if geojson is None:
        return
    if geojson.get("type") == "Feature":
        geojson = geojson["geometry"]
    if geojson.get("type") == "Polygon":  # column is MULTIPOLYGON
        geojson = {"type": "MultiPolygon", "coordinates": [geojson["coordinates"]]}
    db.execute(text(f"UPDATE {table} SET boundary = ST_GeomFromGeoJSON(:g, 1, 4326) WHERE id = :id"),
               {"g": json.dumps(geojson), "id": row_id})
