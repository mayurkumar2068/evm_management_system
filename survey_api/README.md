# MPSECIEMS Survey API

Small Express + mysql2 service that feeds the Angular survey dropdowns from the
**MPSECIEMS** MySQL database. Angular cannot talk to MySQL directly, so it calls
this API; `ng serve` proxies `/api` → this server (see `survey_web/proxy.conf.json`).

## Setup

```bash
cd survey_api
npm install
cp .env.example .env      # then fill in DB_PASSWORD etc.
```

## Discover your schema (one time)

```bash
node inspect.js           # prints every table + columns in MPSECIEMS
```

Use the output to edit the **SCHEMA** block at the top of `server.js` — set the
correct `table`, `id`, `name`, and parent FK columns for each level.

## Run

```bash
npm run dev               # auto-reload  (or: npm start)
# verify:
curl http://localhost:3000/api/health
curl http://localhost:3000/api/locations/districts
```

Then start Angular normally (`cd ../survey_web && npm start`) — dropdowns now
come from MySQL. For a physical phone over USB also run: `adb reverse tcp:4200 tcp:4200`.

## Endpoints

| Method | Path | Returns |
| ------ | ---- | ------- |
| GET | `/api/locations/districts` | `[{id,name}]` |
| GET | `/api/locations/blocks?districtId=` | `[{id,name}]` |
| GET | `/api/locations/panchayats?blockId=` | `[{id,name}]` |
| GET | `/api/locations/body-types?districtId=` | `[{id,name}]` |
| GET | `/api/locations/bodies?bodyTypeId=` | `[{id,name}]` |
| GET | `/api/locations/booths?parentId=` | `[{id,name}]` |
| GET | `/api/survey/checklist?boothId=` | `{maxImages, items[]}` |
| POST | `/api/survey/submit` | `{success, referenceId, message}` |
