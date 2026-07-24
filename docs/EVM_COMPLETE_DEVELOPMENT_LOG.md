# EVM Management System — Complete Development Log

**Document type:** End-to-end work chronicle (mobile + survey + APIs + local DB)  
**Project:** `evm_management_system`  
**Client / domain:** Madhya Pradesh State Election Commission / ECI-style EVM & election operations  
**Coverage window:** **18 Jun 2026 → 24 Jul 2026** (and continuing)  
**Last updated:** 24 Jul 2026  

> Yeh document **shuru se ab tak** jo kaam hua — architecture, mobile local database, offline sync, auth, dashboard, survey WebView, online nomination (OLINAPI), theme/settings, iOS build fixes — **ek jagah** detail me record karta hai.  
> Sources: codebase, `docs/`, git commits (17–22 Jul), Cursor agent sessions, aur pehle ka enterprise timesheet (18 Jun–3 Jul).

---

## Table of contents

1. [Project at a glance](#1-project-at-a-glance)
2. [Technology stack (current)](#2-technology-stack-current)
3. [Phase timeline — kya kab hua](#3-phase-timeline--kya-kab-hua)
4. [Mobile local database — full detail](#4-mobile-local-database--full-detail)
5. [Offline sync & queue](#5-offline-sync--queue)
6. [Security & session](#6-security--session)
7. [Feature modules — status & kaam](#7-feature-modules--status--kaam)
8. [Survey stack (WebView + Angular)](#8-survey-stack-webview--angular)
9. [Online nomination (OLINAPI)](#9-online-nomination-olinapi)
10. [Environment & API endpoints](#10-environment--api-endpoints)
11. [UI / theme / localization work](#11-ui--theme--localization-work)
12. [iOS / build / tooling issues](#12-ios--build--tooling-issues)
13. [Git publish history (remote)](#13-git-publish-history-remote)
14. [Database & sync — verification checklist](#14-database--sync--verification-checklist)
15. [What is done vs pending](#15-what-is-done-vs-pending)
16. [Key file map](#16-key-file-map)

---

## 1. Project at a glance

### 1.1 Purpose

Flutter mobile app jisme:

| Area | Goal |
|------|------|
| EVM inventory | Control Unit / Ballot Unit registration, barcode scan, stock |
| Field ops | Offline-first work jab network na ho |
| Survey | Polling station survey Angular WebView + POElectionAPI |
| Nomination | Urban online nomination masters (OLINAPI) + multi-step form |
| Presiding | Election-day milestones / turnout (local-first) |
| Audit | Activity log, audit trail surfaces |

### 1.2 High-level architecture (current)

```
Flutter App (GetX + Dio)
├── Presentation  → screens, GetxControllers
├── Data          → repositories, remote datasources, DTOs
├── Core
│   ├── JsonLocalDatabase (file JSON under app support dir)
│   ├── SyncQueue / SyncManager / OfflineSyncService
│   ├── TokenVault + SecureStorage
│   ├── ApiClient (Dio interceptors)
│   └── InAppWebView (survey / portals)
├── Features      → auth, dashboard, scanner, nomination, …
└── Design system → tokens + shared widgets

survey_web/       → Angular survey UI (hosted /pssurvey/ or Pages)
survey_api/       → REMOVED (unused local Node API; POElectionAPI used instead)
```

### 1.3 Important evolution note

Early docs / README abhi bhi **Riverpod + GoRouter** mention karte hain.  
**Current running code GetX** use karta hai (`get`, `GetMaterialApp`, `Get.find` / `Get.put` via `AppServices`).  
Is document me **current reality = GetX** maani gayi hai.

---

## 2. Technology stack (current)

| Layer | Choice |
|-------|--------|
| Mobile | Flutter / Dart (`sdk: ^3.9.0`) |
| State / DI | **GetX** (`get: ^4.7.2`) + `AppServices` composition root |
| HTTP | Dio + interceptors (auth, retry, logging, connectivity) |
| Config | `flutter_dotenv` — `assets/env/dev.env`, `uat.env`, `prod.env` |
| Local DB | `LocalDatabase` interface → **`JsonLocalDatabase`** (JSON files) |
| Secure secrets | `flutter_secure_storage` (TokenVault) |
| Biometrics | `local_auth` |
| Scanner | `mobile_scanner` |
| WebView | `flutter_inappwebview` |
| i18n | `easy_localization` (EN + HI) |
| Charts | `fl_chart` |
| Survey UI | Angular (`survey_web/`) |
| Urban nomination API | OLINAPI (`/Master/*`) |
| Survey / PO APIs | POElectionAPI |

---

## 3. Phase timeline — kya kab hua

### Phase A — Foundation (≈ 18–22 Jun 2026)

**Kaam:**

- Flutter project scaffold, Clean Architecture / feature-first folders
- `bootstrap()` composition root
- Env flavors (DEV / UAT / PROD)
- Dio `ApiClient` + interceptor stack
- Security stubs: TokenVault, SSL pinning hooks, biometrics, session timeout, screen security
- Design tokens + shared widgets (button, card, text field, loaders, empty/error)
- Auth domain + login flow scaffolding
- Dashboard domain scaffolding
- Docs: ARCHITECTURE, CODING_STANDARDS, STATE_MANAGEMENT, SECURITY, DEPLOYMENT, BACKEND_API_SPEC

**Database milestone:**

- `LocalDatabase` interface define
- **`JsonLocalDatabase` implement** — app support directory me `evm_db/*.json`
- Collections define (`LocalCollections`)

### Phase B — Auth, devices, i18n, survey start (≈ 23–25 Jun 2026)

**Kaam:**

- Auth repository wiring, splash, session restore
- Locale keys + EN/HI translations
- ErrorMapper / Result pattern
- CU / BU registration screens scaffold
- Scanner module with reusable scanner widget
- FVM / Flutter pin (historical docs)
- **survey_api** (Express + MySQL) + **survey_web** (Angular) start — baad me local API hata diya gaya

### Phase C — Offline, WebView, service auth (≈ 29 Jun – 3 Jul 2026)

**Kaam:**

- Durable **`SyncQueue`** on `pending_sync` collection
- **`SyncManager`** + retry / conflict hooks
- **`OfflineSyncService`** + `web_submissions` for Angular → Flutter bridge forms
- Presiding concern local store (`presiding_concern`)
- Service Auth (district password gate before WebView services)
- InAppWebView wrapper, warmer, cookie / session helpers
- Enterprise timesheet doc generated (3 Jul)

### Phase D — GetX migration, MPSEC integration, portals (≈ early–mid Jul 2026)

**Kaam (codebase evidence):**

- State/routing shift toward **GetX** + named routes (`AppRoute`)
- POElectionAPI / MPSEC live endpoints in env
- Dashboard service tiles: voter search, booth, presiding, online nomination, candidate expenditure
- Profile linked to real `ServiceSession` / `AuthUser` (guest display fixed)
- Settings: language, theme, notifications, offline — clutter removed
- Theme-aware surfaces (`AppThemeColors`) across major screens
- Offline status as **bottom sheet**
- Logout simplified (local-first; dispose/nav crash fixes)
- WebView chrome theme-aware; host/URL hidden; zoom disabled later

### Phase E — Survey WebView hardening (≈ 17 Jul 2026) — git commits

Published / fixed in rapid succession:

| Commit theme | Detail |
|--------------|--------|
| GitHub Pages deploy | `survey_web` Pages + CI |
| District cascade | Full district list then child masters |
| Urban body / PS masters | Path + query fallback |
| Rural जनपद/बूथ | Prefer login `BodyID` |
| Proxy / CI Flutter SDK | WebView proxy to mpsec API |
| Soft blue–mint theme | Login / PO / survey staging unify |
| Production survey URL | Back to `/pssurvey/` |
| Full code publish | 17 Jul, 20 Jul, 22 Jul |

### Phase F — Online nomination + polish (≈ 20–24 Jul 2026)

**Kaam:**

- Urban nomination selection: Election → Post from OLINAPI
- Workflow area cascade: District → Urban Body → Ward (conditional)
- Nomination drafts in local DB (`nomination_drafts`)
- Start sheet: Login / Registration → Urban / Panchayat (animated same sheet)
- **API flow fix:** Ward only if `postId == 3`; always `GetUtbanBody` (no name-based ward gate; optional `electionId`)
- DTO fix: parse lowercase `ubid` so निकाय नाम dropdown fill ho
- Candidate Expenditure tile + URL
- AuthController register order fix (dashboard crash)
- Unused **`survey_api/`** removed
- iOS: disable Swift Package Manager, CocoaPods-only, release build green
- WebView: `supportZoom: false`

---

## 4. Mobile local database — full detail

### 4.1 Design decision

| Decision | Detail |
|----------|--------|
| Abstraction | `LocalDatabase` interface — features JSON pe depend nahi karti |
| Default impl | `JsonLocalDatabase` — zero codegen, easy debug |
| Future | Isar / SQLite adapter same interface pe swap (docs me planned) |
| Why not only secure storage | Large lists / queues / watch streams ke liye file DB better |

### 4.2 Storage location

```
Application Support Directory
└── evm_db/
    ├── user_session.json
    ├── pending_sync.json
    ├── control_units.json
    ├── ballot_units.json
    ├── audit_logs.json
    ├── notifications.json
    ├── web_submissions.json
    ├── presiding_concern.json
    └── nomination_drafts.json
```

Path code: `path_provider` → `getApplicationSupportDirectory()` + `/evm_db`.

### 4.3 Interface API

```dart
// lib/core/database/local_database.dart
abstract interface class LocalDatabase {
  Future<void> init();
  Future<void> put(String collection, String id, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> get(String collection, String id);
  Future<List<Map<String, dynamic>>> getAll(String collection);
  Future<void> delete(String collection, String id);
  Future<void> clear(String collection);
  Stream<List<Map<String, dynamic>>> watch(String collection);
}
```

### 4.4 Write safety (important)

`JsonLocalDatabase._flush`:

1. Memory cache update  
2. Write sibling `*.json.tmp`  
3. `rename` over target file  

Crash mid-write pe corrupt JSON avoid — atomic replace pattern.

### 4.5 Collections (tables)

| Collection constant | File | Purpose | Primary consumers |
|---------------------|------|---------|-------------------|
| `user_session` | `user_session.json` | Cached auth / session snapshot | Auth local datasource |
| `pending_sync` | `pending_sync.json` | Durable sync FIFO queue | `SyncQueue` / `SyncManager` |
| `control_units` | `control_units.json` | CU offline cache | Device / CU flows |
| `ballot_units` | `ballot_units.json` | BU offline cache | Device / BU flows |
| `audit_logs` | `audit_logs.json` | Local audit entries | Audit trail / activity |
| `notifications` | `notifications.json` | Cached notifications | Notifications feature |
| `web_submissions` | `web_submissions.json` | Queued WebView/Angular form posts | `OfflineSyncService` |
| `presiding_concern` | `presiding_concern.json` | Milestones + turnout local | Presiding feature |
| `nomination_drafts` | `nomination_drafts.json` | In-progress nomination form | `NominationDraftRepository` |

Defined in: `lib/core/database/local_database.dart` → `LocalCollections`.

### 4.6 Init lifecycle

Bootstrap (`lib/bootstrap/bootstrap.dart` / `AppServices`):

1. Load flavor `.env`  
2. `LocalDatabase.init()` → create `evm_db` if missing  
3. Register GetX services: DB, secure storage, sync, API, controllers  

### 4.7 Nomination draft example (local DB usage)

- User area / candidate fields fill karta hai  
- Controller debounce (~500ms) → `NominationDraftRepository.save`  
- Draft JSON `nomination_drafts` collection me  
- Home screen “resume draft” card se wapas workflow  

### 4.8 What mobile DB is **not**

- Remote MySQL / PostgreSQL nahi — sirf **on-device**  
- Server survey tables pehle `survey_api` me the; ab submissions **POElectionAPI** pe jaati hain (WebView / upload service)  
- OLINAPI masters **live HTTP** se aate hain; unka cache abhi dedicated collection me nahi (optional future)

---

## 5. Offline sync & queue

### 5.1 Components

| Component | Role |
|-----------|------|
| `SyncQueue` | Durable queue backed by `pending_sync` |
| `SyncManager` | Drain queue, retry policy, conflict hooks |
| `SyncService` | Transport / task execution |
| `OfflineSyncService` | Web submissions offline → online push |
| `ConnectivityService` | Online/offline detection |
| Sync Management screen | Queue depth / status UI |
| Offline status sheet | Settings se bottom sheet status |

### 5.2 Typical flow

```
User action (offline)
  → write local collection / enqueue SyncTask
  → pending_sync.json update
Network back
  → SyncManager processes queue
  → success → remove / mark done
  → fail → retry up to SYNC_MAX_RETRY (env)
```

### 5.3 Env knobs

From `dev.env` (example):

- `SYNC_INTERVAL_SECONDS=60`  
- `SYNC_MAX_RETRY=5`  
- `SESSION_TIMEOUT_MINUTES=15`  

---

## 6. Security & session

| Piece | What was done |
|-------|----------------|
| TokenVault | Access/refresh in secure storage |
| Auth interceptors | Bearer inject + 401 refresh path |
| Biometric | Optional unlock hooks |
| SSL pinning | Flagged per env (`ENABLE_SSL_PINNING`) |
| Screen security | Handler hooks (platform may log “not registered”) |
| Guest user | Hardcoded fake name hataaya; localized guest label |
| Logout | Local clear + safe navigation (dispose double-nav fix) |
| Service Auth | District password before some WebView services |

---

## 7. Feature modules — status & kaam

| Module | Path | Kaam summary |
|--------|------|--------------|
| **auth** | `lib/features/auth/` | Login, session restore, guest, biometric hooks |
| **dashboard** | `lib/features/dashboard/` | KPIs, service grid, WebView launchers, expenditure tile |
| **scanner** | `lib/features/scanner/` | QR/barcode for device IDs |
| **control_unit / ballot_unit** | device features | Registration UI scaffolds + local cache collections |
| **master_stock_register** | MSR | Inventory summary UI |
| **search** | search | Device / record search |
| **reports** | reports | Charts surface (`fl_chart`) |
| **notifications** | notifications | List / cache |
| **audit_trail** | audit_trail | Local audit viewing |
| **profile** | profile | Real session user display |
| **settings** | settings | Language, theme, notifications, offline sheet |
| **offline** | offline | Sync progress + status sheet |
| **sync_management** | sync_management | Queue management UI |
| **service_auth** | service_auth | Gate before portal WebViews |
| **web_portal** | web_portal | Generic portal hosting |
| **polling_survey** | polling_survey | Survey WebView entry |
| **presiding_concern** | presiding_concern | Dashboard / turnout / live poll (local-first) |
| **online_nomination** | online_nomination | Urban OLIN cascade + full workflow + drafts |
| **onboarding** | onboarding | First-run store |
| **help_support / about** | — | Static / support screens |
| **device_detail** | — | Device detail surface |

---

## 8. Survey stack (WebView + Angular)

### 8.1 What you built

1. **Angular `survey_web`** — polling station checklist UI  
2. Initially **Node `survey_api` + MySQL** — later **removed** as unused; Flutter points to **POElectionAPI**  
3. Flutter **InAppWebView** embeds survey with session / theme / bridge  
4. GitHub Pages staging + production `/pssurvey/` switching (17 Jul commits)  
5. Masters cascade fixes (district → body → PS; rural BodyID preference)  
6. Soft blue–mint staging theme alignment  

### 8.2 Current env (DEV example)

```
PO_ELECTION_API_BASE_URL=http://10.115.197.192/POElectionAPI
SURVEY_API_BASE_URL=http://10.115.197.192/POElectionAPI/api
SURVEY_WEB_BASE_URL=http://10.115.197.192/pssurvey/
```

### 8.3 Offline angle

Angular submissions bridge → Flutter → `web_submissions` → sync when online (`OfflineSyncService` / `SurveyApiUploadService`).

---

## 9. Online nomination (OLINAPI)

### 9.1 Product flow (UI — unchanged structure)

```
Online Nomination Home
  → Start sheet: Login | Registration
  → Registration → Urban | Panchayat
  → Urban: Election cards → Post cards
  → Workflow (multi-step):
       Area (District → UB → Ward?)
       Candidate details
       Address
       Summary
       Documents
       Preview
       Declaration
  → Success / Receipt / Track status
```

### 9.2 Master API sequence (current business rules)

```
GET /Master/GetElectionUrban
  → user picks election (eid)

GET /Master/GetPostUrban?electionId=
  → user picks post (postid)

GET /Master/GetDistrictUrban?electionId=&postId=
  → user picks district (dstid)

GET /Master/GetUtbanBody?postId=&dstId=&electionId?(optional)
  → user picks urban body (ubid)

IF postId == 1 OR postId == 2
  → DO NOT call Ward; continue existing workflow

IF postId == 3
  → GET /Master/GetUrbanWard?postId=&dstId=&ubId=
  → user picks ward; continue existing workflow
```

### 9.3 Fixes done in this module

| Issue | Fix |
|-------|-----|
| निकाय नाम empty | Parse API `ubid` (lowercase) in DTO |
| Ward by post **name** | Gate on numeric `postId == 3` only |
| `Get_UB_President` branch | Removed from repo path; always `GetUtbanBody` |
| Start UX | Login/Registration then Urban/Panchayat same sheet, animated |
| Drafts | Local `nomination_drafts` collection |

### 9.4 Explicitly **not** done (scoped out)

- Registration API with userid/password  
- New registration-only screen replacing multi-step workflow  

Docs: `docs/OLINAPI_URBAN_MASTER_API.md`

---

## 10. Environment & API endpoints

### 10.1 Flavor files

| File | Use |
|------|-----|
| `assets/env/dev.env` | Local / LAN DEV |
| `assets/env/uat.env` | UAT |
| `assets/env/prod.env` | Production |

### 10.2 Key DEV URLs (as of last edit)

| Key | Value (DEV) |
|-----|-------------|
| `API_BASE_URL` | `http://10.115.197.192/POElectionAPI/api` |
| `PO_ELECTION_API_BASE_URL` | `http://10.115.197.192/POElectionAPI` |
| `OLIN_API_BASE_URL` | `http://10.115.197.192/OLINAPI` |
| `SURVEY_WEB_BASE_URL` | `http://10.115.197.192/pssurvey/` |
| `VOTER_SEARCH_ENGINE_URL` | SEC search portal |
| `CANDIDATE_EXPENDITURE_URL` | Candidate Expenditure portal |

### 10.3 OLIN master paths

```
/Master/GetElectionUrban
/Master/GetPostUrban
/Master/GetDistrictUrban
/Master/GetUtbanBody
/Master/GetUrbanWard
/Master/Get_UB_President   (datasource kept; urban body flow no longer prefers it)
```

### 10.4 Ops note

503 on OLIN/POElection = **server/IIS down** — app request shape sahi ho sakta hai; infra check required.

---

## 11. UI / theme / localization work

| Item | Detail |
|------|--------|
| Theme | Light/dark aware surfaces via `AppThemeColors` |
| Login / staging | Soft blue–mint unify (17 Jul) |
| Locale | Persist + apply; stop force-Hindi every boot |
| Guest label | Localized Guest Officer / अतिथि अधिकारी |
| WebView header | Theme-aware; URL/host hidden |
| WebView zoom | Disabled (`supportZoom: false`, no zoom controls) |
| Nomination start | Animated multi-step bottom sheet |
| i18n debt | Some dashboard/service keys still missing in logs (warnings) — known |

---

## 12. iOS / build / tooling issues

| Symptom | Resolution path |
|---------|-----------------|
| Dart VM Service / SIGKILL | Device debug attach / USB / Developer Mode |
| `Unable to find module dependency: 'Flutter'` (Profile/Release) | Disable SPM; CocoaPods-only; remove `FlutterGeneratedPluginSwiftPackage` from Xcode project |
| `flutter_inappwebview` no SPM | Expected warning; pods path works |
| CocoaPods UTF-8 crash | `export LANG=en_US.UTF-8` |
| Concurrent Xcode builds | Kill `xcodebuild`, clear DerivedData |
| Release verify | `flutter build ios --release` succeeded after SPM cleanup |

Project flag:

```yaml
# pubspec.yaml
flutter:
  config:
    enable-swift-package-manager: false
```

---

## 13. Git publish history (remote)

| Date | Notable commits |
|------|-----------------|
| 17 Jul 2026 | Survey Pages, masters cascade fixes, theme, CI, full publish |
| 20 Jul 2026 | Full code publish |
| 22 Jul 2026 | Full code publish |

Earlier Jun–early Jul work pehle local/filesystem timeline se enterprise timesheet me reconstruct hua tha; baad me git remote publish.

---

## 14. Database & sync — verification checklist

Use this when QA / handover:

- [ ] Fresh install creates `evm_db/` under app support  
- [ ] Login persists session (`user_session` / secure token)  
- [ ] Airplane mode: draft nomination saves; resume works  
- [ ] Airplane mode: survey / web submission queues in `web_submissions` or `pending_sync`  
- [ ] Online: sync drains queue; Sync Management depth drops  
- [ ] Logout clears sensitive session without crash  
- [ ] OLIN Election → Post → District → UB loads when server 200  
- [ ] `postId` 2: no Ward API in logs  
- [ ] `postId` 3: Ward API after UB select  
- [ ] Theme / locale survive app restart  

---

## 15. What is done vs pending

### Done (high level)

- Mobile app shell + feature modules  
- **Local JSON DB + collections + atomic writes**  
- Offline sync queue infrastructure  
- Auth / dashboard / scanner / portals / survey WebView  
- OLIN urban master cascade + workflow + drafts  
- Theme, settings cleanup, guest/profile fixes  
- iOS CocoaPods release path  
- Docs pack under `docs/`  

### Pending / partial

- Full remote ECI PostgreSQL backend (mostly **spec**)  
- Isar/SQLite adapter swap (optional performance)  
- Nomination **Registration API** (userid/password) — not implemented by design yet  
- Some i18n keys still missing (dashboard.guest, services.*, etc.)  
- README still mentions Riverpod/GoRouter — docs drift  
- `Get_UB_President` / unused paths cleanup optional  
- Stronger empty-state UX when OLIN returns 503  

---

## 16. Key file map

| Concern | Path |
|---------|------|
| DB interface + collections | `lib/core/database/local_database.dart` |
| JSON DB impl | `lib/core/database/json_local_database.dart` |
| Sync queue | `lib/core/sync/sync_queue.dart` |
| Sync manager | `lib/core/sync/sync_manager.dart` |
| Offline sync | `lib/core/offline/offline_sync_service.dart` |
| DI / services | `lib/core/di/app_services.dart` |
| Bootstrap | `lib/bootstrap/bootstrap.dart` |
| Env DEV | `assets/env/dev.env` |
| OLIN datasource | `lib/features/online_nomination/data/datasources/urban_nomination_remote_datasource.dart` |
| OLIN repository | `lib/features/online_nomination/data/repositories/urban_nomination_master_repository.dart` |
| Nomination workflow | `lib/features/online_nomination/presentation/controllers/nomination_workflow_controller.dart` |
| Nomination drafts | `lib/features/online_nomination/data/repositories/nomination_draft_repository.dart` |
| WebView widget | `lib/core/webview/widget/app_webview.dart` |
| OLIN API doc | `docs/OLINAPI_URBAN_MASTER_API.md` |
| Earlier enterprise pack | `docs/ENTERPRISE_PROJECT_DOCUMENTATION_TIMESHEET.md` |
| This chronicle | `docs/EVM_COMPLETE_DEVELOPMENT_LOG.md` |

---

## Appendix A — Day-wise reconstruction (18 Jun – 3 Jul)

Pehle ka detailed day log (screens, hours, inferred commits) already hai:

→ **`docs/ENTERPRISE_PROJECT_DOCUMENTATION_TIMESHEET.md`**

Us document ko **June foundation + early Jul** ke liye reference maano; **is file ko Jul mid–late (GetX reality, OLIN, survey production, iOS SPM, DB collections including nomination_drafts)** ke liye source of truth maano.

---

## Appendix B — One-line “itne din me kya karwaya”

1. Poora Flutter EVM app scaffold + design system + security/network core  
2. **Mobile local database (`evm_db` JSON) + 9 collections + atomic writes**  
3. Offline sync queue + WebView submission queue  
4. Auth, dashboard, scanner, stock, reports, settings, profile  
5. Survey Angular + WebView + POElectionAPI integration (local survey_api later removed)  
6. Presiding local workflows  
7. Online nomination urban masters (OLIN) + multi-step form + drafts + postId Ward rule  
8. Theme/locale polish, expenditure portal, start-sheet UX  
9. iOS SPM→CocoaPods fix so Profile/Release build  
10. Docs + env flavors + repeated full code publish  

---

**End of document**
