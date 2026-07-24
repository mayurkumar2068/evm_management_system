# Survey Reports API (District / Polling Station / Urban–Rural)

Mobile **Reports** screen needs aggregated survey counts by district, polling station, and urban/rural area.

Use this contract so Flutter can later replace local queue analytics with live server data.

---

## Endpoint

```http
GET /api/PSSurvey/survey_reports
```

**Auth:** `Authorization: Bearer {token}` (same survey login token as other PSSurvey APIs).

**Base URLs**

| Env | Base |
|-----|------|
| DEV | `http://10.115.197.192/POElectionAPI` |
| PROD | `https://mpsecerms.mp.gov.in/POElectionAPI` |

---

## Request query parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `token` | string | Yes* | Same as other Masters/PSSurvey GETs (query token), if your gateway requires it |
| `from` | string (ISO-8601 date) | No | Start date inclusive, e.g. `2026-07-01` |
| `to` | string (ISO-8601 date) | No | End date inclusive, e.g. `2026-07-21` |
| `districtId` | string | No | Filter one district (`DistID`) |
| `areaType` | string | No | `U` / `urban` / `R` / `rural` / `all` (default `all`) |
| `page` | int | No | Default `1` |
| `pageSize` | int | No | Default `50`, max `200` |

\*Follow the same auth pattern as `GET /api/PSSurvey/survey_questions`.

### Example (DEV)

```bash
curl -G 'http://10.115.197.192/POElectionAPI/api/PSSurvey/survey_reports' \
  -H 'Authorization: Bearer {token}' \
  -H 'Accept: application/json' \
  --data-urlencode 'token={token}' \
  --data-urlencode 'from=2026-07-01' \
  --data-urlencode 'to=2026-07-21' \
  --data-urlencode 'areaType=all' \
  --data-urlencode 'page=1' \
  --data-urlencode 'pageSize=50'
```

### Example (PROD)

```bash
curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/PSSurvey/survey_reports' \
  -H 'Authorization: Bearer {token}' \
  -H 'Accept: application/json' \
  --data-urlencode 'token={token}' \
  --data-urlencode 'from=2026-07-01' \
  --data-urlencode 'to=2026-07-21' \
  --data-urlencode 'areaType=all'
```

---

## Expected response (200)

```json
{
  "Success": true,
  "Message": null,
  "Data": {
    "overview": {
      "totalSurveys": 128,
      "synced": 110,
      "pending": 12,
      "failed": 6,
      "urban": 74,
      "rural": 54,
      "today": 9
    },
    "byDistrict": [
      {
        "districtId": "23",
        "districtName": "Bhopal",
        "totalSurveys": 42,
        "urban": 30,
        "rural": 12,
        "pollingStationCount": 18,
        "pollingStations": [
          {
            "psId": "UPS-1001",
            "psName": "Govt. Primary School, Ward 5",
            "areaType": "U",
            "surveyCount": 4,
            "lastSurveyAt": "2026-07-20T14:22:00Z"
          },
          {
            "psId": "RPS-2201",
            "psName": "Gram Panchayat Bhawan, Village X",
            "areaType": "R",
            "surveyCount": 2,
            "lastSurveyAt": "2026-07-19T09:10:00Z"
          }
        ]
      }
    ],
    "daily": [
      { "date": "2026-07-15", "count": 5 },
      { "date": "2026-07-16", "count": 8 }
    ],
    "weekly": [
      { "weekStart": "2026-06-09", "count": 21 },
      { "weekStart": "2026-06-16", "count": 19 }
    ],
    "paging": {
      "page": 1,
      "pageSize": 50,
      "totalDistricts": 1
    }
  }
}
```

### Field notes

| Field | Meaning |
|-------|---------|
| `areaType` | `U` = Urban (UPSBUILDINGS), `R` = Rural (RPSBUILDINGS) |
| `psId` | Booth / मतदान केंद्र id (`UPSBUILDINGS.ID` or `RPSBUILDINGS.ID`) |
| `districtId` | `Districts` / login `DistID` |
| `overview.*` | KPI boxes on Reports screen |
| `byDistrict[]` | Expandable district list + nested polling stations |
| `daily` / `weekly` | Charts (last 7 days / last 6 weeks) |

---

## Error responses

| Status | Body |
|--------|------|
| 401 | `{ "Success": false, "Message": "Unauthorized" }` |
| 400 | `{ "Success": false, "Message": "Invalid from/to date" }` |
| 500 | `{ "Success": false, "Message": "Server error" }` |

---

## Suggested SQL source (existing schema)

Aggregate from booth survey submissions on the POElection / PSSurvey backend
(distinct booth survey, not one row per checklist question).

- `AREA_TYPE` → urban / rural  
- `DIST_ID` → district  
- `BOOTH_ID` → polling station  
- Join district / UPS / RPS master tables for display names  

If answers are saved per question via `save_survey_answer`, count **distinct `(psType, psId, userId, DATE(created))`** or a dedicated submission header — report counts must match “one booth survey”, not one question row.

---

## Flutter mapping (when API is ready)

| UI | Response path |
|----|---------------|
| KPI Total / Today / Synced | `Data.overview` |
| KPI Urban / Rural | `Data.overview.urban` / `.rural` |
| Daily bar chart | `Data.daily` |
| Weekly line chart | `Data.weekly` |
| District cards | `Data.byDistrict[]` |
| Polling station rows | `Data.byDistrict[].pollingStations[]` |

Until this API is live, the app shows the same layout from **local offline survey queue** payloads (`psType`, `psId`, `districtId`, …).
