# MCC Complaint System — Backend (FastAPI + MySQL 8)

Citizen → District Controller → Flying Squad → Returning Officer → DEO / CEO, with a 100-minute SLA
(5 min allocation, 15 min travel, 30 min enquiry, 50 min RO decision).

**55 APIs**: 54 REST + 1 WebSocket. Swagger UI at `/docs`, ReDoc at `/redoc`.

## Quick start (local)

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env            # set DATABASE_URL and JWT_SECRET

python -m scripts.init_db        # creates tables, triggers, seed data from db/schema.sql
python -m scripts.seed_demo      # OPTIONAL demo district, ACs, squads, one user per role
python -m scripts.create_admin --username admin --mobile 9XXXXXXXXX   # real first admin

uvicorn app.main:app --reload    # http://localhost:8000/docs
python -m app.workers.sla_worker # separate terminal, exactly ONE instance
```

Demo logins (after `seed_demo`), password `Demo@12345`:
`admin`, `dc.bhopal`, `fs01.lead`, `fs02.lead`, `fs03.lead`, `ro.narela`, `ro.madhya`, `deo.bhopal`, `ceo.mp`.
Citizens log in with any mobile number via OTP. In dev the OTP is returned as `debug_otp`.

### Docker

```bash
cp .env.example .env
docker compose up --build        # MySQL runs db/schema.sql on first start
docker compose exec api python -m scripts.seed_demo
```

### Tests

The suite runs the whole flow against a real MySQL 8 server (it creates and drops a `mcc_test` database):

```bash
TEST_DATABASE_URL="mysql+pymysql://root:pass@127.0.0.1:3306/mcc_test?charset=utf8mb4" pytest
```

## Login flow

| Who | Steps |
|---|---|
| Citizen | `A1 POST /auth/otp/send {mobile}` → `A2 POST /auth/otp/verify {mobile, otp_ref, otp}` |
| Official | `A3 POST /auth/login {username, password}` → `A2 POST /auth/otp/verify {otp_ref, otp}` |

Use `Authorization: Bearer <access>`. Access token lasts 15 min; `A4` rotates the refresh token (7 days).

## All 55 APIs

Base path `/api/v1`. `{id}` for a complaint accepts its UUID or its number (e.g. `BPL-26-0001`).

| # | Method | Path | Role |
|---|---|---|---|
| A1 | POST | /auth/otp/send | Public |
| A2 | POST | /auth/otp/verify | Public |
| A3 | POST | /auth/login | Official |
| A4 | POST | /auth/token/refresh | All |
| A5 | POST | /auth/logout | All |
| A6 | GET | /users/me | All |
| C1 | GET | /violation-types | All |
| C2 | POST | /complaints | Citizen |
| C3 | POST | /complaints/{id}/media | Citizen |
| C4 | POST | /complaints/{id}/submit | Citizen |
| C5 | POST | /complaints/{id}/withdraw | Citizen |
| C6 | GET | /citizen/complaints | Citizen |
| C7 | GET | /citizen/complaints/{id} | Citizen |
| D1 | GET | /dc/complaints | DC |
| D2 | GET | /complaints/{id} | Officials (scoped) |
| D3 | GET | /dc/complaints/{id}/nearby-squads | DC |
| D4 | POST | /dc/complaints/{id}/assign | DC |
| D5 | POST | /dc/complaints/{id}/reassign | DC |
| D6 | POST | /dc/complaints/{id}/mark-duplicate | DC |
| D7 | POST | /dc/complaints/{id}/drop | DC |
| D8 | GET | /dc/squads | DC, DEO |
| F1 | GET | /fs/assignments | FS |
| F2 | POST | /fs/assignments/{aid}/accept | FS |
| F3 | POST | /fs/assignments/{aid}/start | FS |
| F4 | POST | /fs/location | FS |
| F5 | POST | /fs/assignments/{aid}/reached | FS |
| F6 | POST | /fs/assignments/{aid}/media | FS |
| F7 | POST | /fs/assignments/{aid}/report | FS |
| F8 | PATCH | /fs/me/status | FS |
| R1 | GET | /ro/complaints | RO |
| R2 | GET | /ro/complaints/{id}/field-report | RO |
| R3 | POST | /ro/complaints/{id}/decision | RO |
| R4 | POST | /ro/complaints/{id}/send-back | RO |
| R5 | GET | /ro/decisions | RO |
| E1 | GET | /escalations | DEO, CEO |
| E2 | GET | /escalations/{eid} | DEO, CEO |
| E3 | POST | /escalations/{eid}/action | DEO, CEO |
| B1 | GET | /dashboard/summary | DC, RO, DEO, CEO |
| B2 | GET | /dashboard/sla-pipeline | DC, RO, DEO, CEO |
| B3 | GET | /dashboard/outcomes | DC, RO, DEO, CEO |
| B4 | GET | /reports/sla?format=json\|csv\|xlsx | DC, DEO, CEO |
| B5 | GET | /complaints/{id}/audit-log | DC, RO, DEO, CEO |
| M1 | GET | /admin/users | Admin |
| M2 | POST | /admin/users | Admin |
| M3 | PATCH | /admin/users/{uid} | Admin |
| M4 | GET | /admin/squads | Admin |
| M5 | POST | /admin/squads | Admin |
| M6 | PATCH | /admin/squads/{sid} | Admin |
| M7 | GET | /masters/districts | All |
| M8 | GET | /masters/constituencies | All |
| M9 | PUT | /admin/sla-config | Admin |
| N1 | POST | /devices | All |
| N2 | GET | /notifications | All |
| N3 | POST | /notifications/{nid}/read | All |
| N4 | WS | /ws/live?token=<access> | Officials |

Two extra routes are not part of the 55: `GET /health` and `GET /media/{key}` (signed, expiring evidence links for local storage).

## Status flow

| From | Allowed next status (API) |
|---|---|
| DRAFT | RECEIVED (C4), WITHDRAWN (C5) |
| RECEIVED | ASSIGNED (D4), DUPLICATE (D6), DROPPED_AT_DC (D7), WITHDRAWN (C5) |
| ASSIGNED | ACCEPTED (F2), ASSIGNED again on reassign (D5) |
| ACCEPTED | EN_ROUTE (F3), REACHED (F5), ASSIGNED (D5) |
| EN_ROUTE | REACHED (F5), ASSIGNED (D5) |
| REACHED | REPORT_SUBMITTED (F7) |
| REPORT_SUBMITTED | DISPOSED / DROPPED / ESCALATED (R3), REPORT_RETURNED (R4) |
| REPORT_RETURNED | REPORT_SUBMITTED (F7) |
| ESCALATED | RESOLVED (E3 RESOLVE), REPORT_SUBMITTED (E3 RETURN_TO_RO) |


All changes go through `app/services/state_machine.py`, which rejects anything else with `409 INVALID_STATE`,
starts and stops SLA timers, writes `status_history` + `audit_log`, notifies the citizen and sends a WebSocket event.

## Main rules built in

- Live capture only: evidence older than 5 minutes is rejected. Photo ≤ 10 MB, video ≤ 25 MB, max 5 citizen files.
- The original file is kept unchanged with its SHA-256; an EXIF-stripped copy is shown in the UI.
- On submit the GPS point is matched to a district and AC with `ST_Contains`. Outside every district → `422 GEO_MISMATCH`.
- Possible duplicates (same type within 200 m in 60 min) are flagged for the DC.
- A squad can mark "reached" only within 200 m of the complaint (`ST_Distance_Sphere`).
- Every list and detail query is filtered by the caller's scope: DC/DEO by district, RO by AC, FS by own squad, citizen by own complaints.
- Anonymous complaints never expose the citizen's name or mobile. The citizen view never shows officer identity.
- `audit_log` is append-only (MySQL triggers block UPDATE and DELETE).
- SLA worker: `sla.warning` at 80% of a stage's time, `sla.breached` at 100% (alerts the stage owner plus DC or DEO).

## Project layout

```
app/
  core/        config, JWT/OTP/password security, auth dependencies, error format, UTC time
  db/          engine, session, "publish events after commit" hook
  models/      SQLAlchemy models for the 22 tables
  services/    state machine, SLA, geo (MySQL spatial), media/storage, notifications, websocket broadcaster
  routers/     auth, citizen, dc, fs, ro, escalation, dashboard, admin, notifications
  workers/     SLA watcher
db/schema.sql  MySQL DDL: tables, spatial indexes, checks, triggers, seed data, view
scripts/       init_db, create_admin, seed_demo, load_boundaries
tests/         end-to-end tests (13 tests, real MySQL)
```

## Loading real boundaries

`seed_demo` uses rough rectangles only for testing. Load official boundaries before real use:

```bash
python -m scripts.load_boundaries districts districts.geojson   # properties: code, name_en, name_hi
python -m scripts.load_boundaries acs acs.geojson               # properties: code, ac_no, name_en, district_code
```

## Before production

These parts are stubs or dev-only and need your setup:

1. **SMS gateway**: send the OTP in `app/routers/auth.py::_issue_otp` (DLT-registered template). Set `OTP_DEBUG_RETURN=false` and `ENV=prod`.
2. **Push notifications**: implement `FcmPushSender.send` in `app/services/notify.py` with the Firebase Admin SDK. Until then notifications are stored in-app only (`push_status = SKIPPED`).
3. **File storage**: replace `LocalStorage` in `app/services/storage.py` with S3/MinIO presigned URLs, and remove the `/media` route.
4. **More than one API instance**: the WebSocket broadcaster is in-process. Add Redis pub/sub in `app/services/realtime.py` before running several instances. Keep exactly one SLA worker.
5. **Secrets and network**: a long random `JWT_SECRET`, HTTPS termination, and CORS origins set for your web domains.
6. **Reverse geocoding**: `address_text` is taken from the app. Add a geocoder if the server should fill it.
