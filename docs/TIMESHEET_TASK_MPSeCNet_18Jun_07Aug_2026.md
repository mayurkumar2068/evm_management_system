# New Task — Timesheet Entry

| Field | Value |
|:------|:------|
| **Project** | MPSeCNet — Mobile Application for Election Field Services |
| **Resource** | Mayur Bobade |
| **Activity** | Other Project Support - Development |
| **Hours Aligned** | 8 |
| **Plan Start Date** | 18 June 2026 |
| **Plan End Date** | 07 August 2026 |

---

## Task Description

*(Copy below into the Task Description field)*

---

**MPSeCNet — End-to-end mobile development for Election Field Services (18 Jun 2026 – 07 Aug 2026)**

Development of the **MPSeCNet** Flutter mobile application supporting Madhya Pradesh State Election Commission field services. Work follows the real application workflow: **Login → Dashboard → Modules**. Scope covers application foundation, officer login, home dashboard, and election field modules delivered from Day 1 through current date.

### Application workflow delivered

1. **Login** — App / officer / service login; separate Presiding Officer login  
2. **Dashboard** — Home service tiles (Voter Services + About Elections)  
3. **Voter Services** — EMS portal, Find Voter (native), Claim / Objection portal  
4. **About Elections** — Online Nomination, Polling Station Survey, Presiding Officer, Expenditure (priority-based)  
5. **Support** — Offline / sync, English–Hindi, profile / branding, notifications  

### Month-wise real work (detail)

#### June 2026 (from 18 June — Day 1)

**18–22 Jun — Foundation & EVM start**
- Flutter project setup, Clean Architecture folders, DEV / UAT / PROD environments  
- API client, secure token storage, design system / shared UI  
- Auth and Dashboard scaffolding  
- **Day-1 starting module:** EVM Control Unit (CU) / Ballot Unit (BU) registration screens and barcode scanner path  
- Local JSON database for device / inventory collections  

**23–29 Jun — Login path, Survey WebView, Offline, i18n**
- English / Hindi localisation keys  
- In-app WebView engine for survey and external portals  
- Officer service-login gate before opening services  
- Offline sync queue and WebView form submission queue  
- Profile, settings, onboarding screens  
- CI build / analyse scripts  

**30 Jun – early Jul — Navigation & PO start**
- Bottom navigation (Dashboard / Profile)  
- Language and theme preferences  
- First Presiding Officer milestone / turnout UI (local)  
- Offline status hub UI  

#### July 2026

**7–13 Jul — API wiring & Dashboard modules**
- GetX state / routing as runtime  
- POElectionAPI and related MPSEC service URLs in environments  
- Dashboard tiles for voter search, booth survey, Presiding Officer, nomination, expenditure  
- Profile display of officer session fields  

**14–20 Jul — Polling Station Survey (urban / rural) stabilisation**
- Repository publish and survey staging checks  
- District → body → booth cascade fixes  
- Urban body / polling-station master call fallbacks  
- Rural block / booth empty-dropdown fix (login BodyID)  
- Theme alignment across login / survey  
- Production survey path configured to `/pssurvey/`  

**21–27 Jul — Online Nomination (Urban) + PO / home / branding**
- Urban nomination via OLINAPI (election / post, district → urban body → ward)  
- Multi-step nomination form with local draft save  
- Urban / Panchayat entry UI  
- MPSeCNet branding, splash logo, Hindi home titles  
- Claim / Objection tile → secforms portal  
- Presiding Officer login separated from survey login  
- Live turnout percentages from login elector counts (Male / Female / Other / Total)  
- Profile field corrections (UserName, Urban / Rural, body labels)  
- PROD-flavour APK generated for internal checking (27 Jul)  

**28–31 Jul — Notifications**
- Local reminder notification investigation (scheduled but not shown)  
- iOS notification-centre delegate and Android permission / receiver fixes  
- Schedule / timezone / channel presentation corrections  

#### August 2026 (till 07 Aug)

**1–5 Aug — Presiding Officer finalisation**
- Milestone flow, booth map, two-hourly / live turnout entry  
- `po-status` API sync, session locks, offline / online behaviour  
- PO module marked complete for internal use (05 Aug)  

**6 Aug — Find Voter (native)**
- Native voter search on SECSearchAPI (replacing portal-only approach)  
- District / urban–rural search, filters, Hindi transliteration  
- Voter slip generation (preview / share)  
- Module completed for internal use (06 Aug)  

**7 Aug — Dashboard additions for UAT**
- **EMS** home tile — opens IEMS EMS Login page in WebView  
- **Online Nomination** available on Dashboard for department UAT  
- Urban nomination path for UAT; Panchayat path continues (masters / submit remaining)  
- Module-wise work track sheet prepared for progress review  

### Current module status (as of 07 Aug 2026)

| Module | Status | Target / notes |
|:-------|:-------|:---------------|
| Login (App / Officer / PO) | Ready | Completed |
| Dashboard | Ready | Completed |
| EMS | UAT | Target 08–12 Aug 2026 |
| Find Voter | Ready | Completed 06 Aug |
| Claim / Objection | UAT | Target 08–15 Aug 2026 |
| Online Nomination (Urban) | UAT | Target 10–20 Aug 2026 |
| Online Nomination (Panchayat) | In Progress | Target 25 Aug – 05 Sep 2026 |
| Polling Station Survey | UAT | Target 10–18 Aug 2026 |
| Presiding Officer | Ready | Completed 05 Aug |
| Election Expenditure | Not Started | As per department priority |
| EVM Scanning (CU / BU) | In Progress | Day-1 module; resume on priority |
| Offline / Sync, Profile / i18n | Ready | Completed |
| Notifications | Pending Dept | Timings / message confirmation |

### Technology stack (this assignment)

Flutter mobile app · GetX · WebView (survey / portals) · POElectionAPI / OLINAPI / SECSearchAPI · local JSON store · DEV/UAT/PROD flavours · English–Hindi localisation · local notifications  

### Outcome

Single mobile application (MPSeCNet) delivering Login → Dashboard → election field modules for internal checking and department UAT. Formal statewide go-live / UAT sign-off remains with the Election Department.

---

## Short version (if form has character limit)

MPSeCNet Flutter app development (18 Jun–07 Aug 2026): Login → Dashboard → modules. Delivered app foundation & EVM start (Jun); service login, WebView survey, offline, i18n; Presiding Officer milestones & live turnout; urban Online Nomination (OLINAPI); survey urban/rural master fixes; branding & PROD APK; notifications fix; PO finalisation (05 Aug); native Find Voter (06 Aug); EMS home WebView + Nomination on Dashboard for UAT (07 Aug). Stack: Flutter, GetX, POElectionAPI/OLINAPI/SECSearchAPI, WebView, EN/HI.
