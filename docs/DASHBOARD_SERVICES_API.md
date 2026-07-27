# Dashboard Services API — Dynamic Service Tiles

> Proposed contract for backend-driven dashboard configuration.
> The mobile app currently builds service tiles locally in `DashboardController._rebuildAsync()`.
> When this API is live, the app will fetch tiles at login / dashboard refresh and render them
> under the **Voter Services** / **About Elections** category toggle.

- Document version: 1.0
- Status: Proposed (not yet wired in app)
- Last updated: 2026-07-27

---

## 1. Overview

The dashboard shows service tiles grouped into two categories:

| Category key | UI label (en) | UI label (hi) | Current services |
|---|---|---|---|
| `voterServices` | Voter Services | मतदाता सेवाएँ | Voter Search Engine, Booth Survey, Candidate Expenditure |
| `aboutElections` | About Elections | निर्वाचन के बारे में | Presiding Officer, Online Nomination |

Each tile can open either a **native Flutter route** or an **external URL** in the in-app WebView.
Some tiles require a per-service officer login before opening.

---

## 2. Endpoint

```
GET /Dashboard/GetServices
```

### 2.1 Authentication

| Header | Required | Description |
|---|---|---|
| `Authorization` | Optional | `Bearer <access_token>` when signed in. Guest users may call without a token. |
| `Accept` | Yes | `application/json` |
| `Accept-Language` | Optional | `en` or `hi`. Falls back to `languageCode` query param. |

### 2.2 Query parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `languageCode` | string | No | `en` or `hi`. Default: `hi`. |
| `platform` | string | No | `android` or `ios`. |
| `appVersion` | string | No | e.g. `1.2.0`. Hides unsupported tiles on old builds. |
| `districtId` | string | No | Scope tiles to officer district when available. |

### 2.3 Example request

```http
GET /Dashboard/GetServices?languageCode=hi&platform=android&appVersion=1.0.0
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Accept: application/json
Accept-Language: hi
```

---

## 3. Response

### 3.1 Envelope

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "categories": [
      { "id": "voterServices", "label": "मतदाता सेवाएँ", "sortOrder": 1 },
      { "id": "aboutElections", "label": "निर्वाचन के बारे में", "sortOrder": 2 }
    ],
    "services": []
  }
}
```

### 3.2 `DashboardServiceItem` fields

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | Stable id, e.g. `voter_search`, `booth_survey`. |
| `category` | string | Yes | `voterServices` or `aboutElections`. |
| `title` | string | Yes | Localized tile title. |
| `desc` | string | Yes | Localized short description. |
| `iconName` | string | Yes | Material icon name, e.g. `manage_search_outlined`. |
| `colorHex` | string | Yes | Tile tint, e.g. `#1565C0`. |
| `url` | string | No | External URL. Empty when using `routeName`. |
| `routeName` | string | No | Native route, e.g. `/presiding`, `/online-nomination`. |
| `requiresServiceLogin` | boolean | No | Default `true`. Gates behind service login. |
| `passSessionContext` | boolean | No | Default `true`. Inject session into WebView URL. |
| `openAsExternalPortal` | boolean | No | Default `false`. Plain WebView, no bridge. |
| `sortOrder` | integer | Yes | Order within category (ascending). |
| `isActive` | boolean | Yes | Hidden when `false`. |
| `minAppVersion` | string | No | Minimum app version to show tile. |
| `roles` | string[] | No | Visibility by role; empty = all. |

**Navigation rule:**

1. `requiresServiceLogin` and no session → service login screen.
2. Non-empty `routeName` → native Flutter route.
3. Non-empty `url` → in-app WebView.
4. Otherwise → misconfigured; app skips tile.

---

## 4. Sample services (Hindi)

See full JSON in section 3.1 with five current tiles: voter search, booth survey, expenditure, presiding officer, online nomination.

---

## 5. Error responses

| HTTP | When |
|---|---|
| 200 | Success (services may be empty). |
| 401 | Invalid token. |
| 403 | Role not allowed. |
| 500 | Server error — app uses bundled default tiles. |

---

## 6. Mobile integration

- **Fetch on:** app launch, dashboard refresh, language change.
- **Fallback:** hardcoded list in `DashboardController._rebuildAsync()` if API fails.
- **Toggle:** filter `services` by `category`; labels from `categories[].label`.

### App mapping

| API field | Flutter model |
|---|---|
| `category` | `DashboardCategory` |
| `iconName` | `IconData` via lookup |
| `colorHex` | `Color` |
| `routeName` | `routeName` |
| Other flags | same field names on `DashboardService` |

---

## 7. Related files

- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart`
- `lib/features/dashboard/presentation/models/dashboard_models.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_widgets.dart`
- `assets/translations/en.json` / `hi.json`
