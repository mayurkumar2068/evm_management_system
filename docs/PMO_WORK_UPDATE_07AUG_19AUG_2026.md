# Work Progress Update

## Project: MPSeCNet — Mobile Application for Election Field Services

| Field | Detail |
|:------|:-------|
| **Project name** | MPSeCNet |
| **Prepared by** | Mayur Bobade, Associate Engineer |
| **Document type** | Period Work Progress Update |
| **Reporting period** | **7 August 2026 – 19 August 2026** |
| **Report date** | 19 August 2026 |
| **Prepared for** | Election Department / concerned reviewing authority |
| **Classification** | Internal — for official review |

---

## Status terminology

| Term | Definition |
|------|------------|
| **Developed** | Application code, user interface, or integration work has been implemented |
| **Configured** | Environment, URL, or permission settings have been applied |
| **In Testing** | Undergoing device or API checks; not presented as final acceptance |
| **Partial** | Work has been started or partly delivered; remaining scope exists |
| **Open** | Awaiting inputs, decisions, or confirmation from the Election Department |

**Disclaimer:** This update does not state that the application is fully complete, publicly released, or formally accepted for statewide use.

---

## 1. Executive summary

During **7–19 August 2026**, work continued on MPSeCNet with focus on:

1. **Voter search (Find Voter / Search Engine)** completion for field use  
2. **Presiding Officer (पीठासीन अधिकारी)** election-day flow — officer profile, polling-party (P1–P4) details, 2–2 hourly turnout, live poll, PDF report  
3. **Booth survey (`survey_web`)** — dynamic answer types and photo rule  
4. **Home / unused EVM inventory screens** held behind feature flags so field officers see assigned services only  
5. **Internal PROD APKs** for device checking (not a store release)

---

## 2. Work carried out in this period

### 2.1 Voter search (7–10 August)

- Search Engine module completed in the application (district / search path, slip-related flow).  
- Home tile and routing aligned for officer use.  
**Status:** Developed / In Testing.

### 2.2 Presiding Officer — officer and party details (10–14 August)

- Post-login **PO name and mobile** screen (OTP when new or mobile changed).  
- **मतदान दल की जानकारी (P1–P4)** form on the PO dashboard (mandatory before later actions).  
- Party save moved to **offline-capable sync** (no OTP on party save); pending upload when network returns.  
**Status:** Developed / In Testing.

### 2.3 Booth survey web (13 August)

- Survey checklist rendering by `ANS_TYPE` (dynamic question types).  
- Length / width fields for relevant items.  
- Photo upload **optional when the answer is No** on Yes/No questions (previously treated as always mandatory).  
**Status:** Developed / In Testing (depends on survey API / hosting).

### 2.4 Home screen cleanup (14 August)

- Unused inventory modules deactivated from officer home: Control Unit, Ballot Unit, Scanner, Master Stock Register, Audit Trail (held by feature flag).  
- Assigned field services remain visible (search, survey, Presiding Officer, nomination, expenditure, claim / objection).  
**Status:** Configured.

### 2.5 Presiding Officer — turnout, lock rules, report (14–19 August)

- **2–2 hourly** entry: later saved slot locks earlier unfilled slots; rural **3 PM** / urban **5 PM** must be saved before queue and final turnout cards.  
- Live poll and 2–2 hourly **disabled after poll end**.  
- Dashboard order: live poll above 2–2 hourly.  
- **PDF report:** PO name, mobile, मतदान केंद्र; “चरण / Milestones” heading removed; footer **MPSEC द्वारा जारी की गई** (not MPSeCNet).  
- Login elector counts (total / male / female / other) shown on PO header.  
- OTP boxes on PO details: backspace deletes **one digit at a time**.  
- Party (P1–P4) entry remains visible after save so officers can view / update.  
**Status:** Developed / In Testing on internal APKs.

### 2.6 Production-oriented Android settings (18 August)

- Backup / data-extraction exclusions; HTTPS for production; WebView no-cache; bundled fonts (no runtime Google Fonts fetch).  
**Status:** Configured for internal PROD-flavour builds.

---

## 3. Deliverables in this period

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | Voter search (Search Engine) in-app path | Developed / In Testing |
| 2 | PO officer profile (name / mobile + OTP when required) | Developed / In Testing |
| 3 | Polling-party P1–P4 details with offline sync | Developed / In Testing |
| 4 | Survey web dynamic answers + optional photo on “No” | Developed / In Testing |
| 5 | Unused EVM inventory tiles hidden from home | Configured |
| 6 | 2–2 hourly / live / queue lock rules | Developed / In Testing |
| 7 | PO election-day PDF report (MPSEC footer) | Developed / In Testing |
| 8 | Internal PROD-flavour APKs (debug and release) for device check | Available internally — **not** a public store release |

---

## 4. Week-wise progress (this window)

### 4.1 7–10 August 2026

**Focus:** Voter search completion and PO party / officer profile start  

- Search Engine completed in application.  
- PO details screen, P1–P4 party form, party sheet / banner on dashboard.  

**Status:** Developed; In Testing.

### 4.2 11–14 August 2026

**Focus:** Survey web, home cleanup, PO API alignment  

- Dynamic survey answer types; length/width fields.  
- Unused CU / BU / scanner / stock / audit trail deactivated on home.  
- JWT / login and party API adjustments for field login.  

**Status:** Developed / Configured.

### 4.3 15–19 August 2026

**Focus:** Election-day PO rules, report, device APKs  

- Hourly slot locking; 3 PM / 5 PM gate for queue and final count.  
- PDF report content as instructed (officer identity, मतदान केंद्र, MPSEC issue line).  
- Header elector counts; OTP delete fix; party banner kept visible.  
- Internal `app-prod-release.apk` / `app-prod-debug.apk` generated for checking.  

**Status:** Developed / In Testing. Formal UAT sign-off remains **Open**.

---

## 5. Open / dependent items

| Item | Note |
|------|------|
| Formal UAT / departmental acceptance | Open — not claimed |
| Public or store release | Open — internal APKs only |
| Party / PO / turnout APIs on production host | In Testing; depends on server availability |
| Survey photo / question types on live survey host | In Testing after Angular deploy |
| Official reminder timings | Open — department confirmation |

---

## 6. Note on earlier period

Work from **18 June 2026 to 7 August 2026** is recorded separately in the monthly report and timesheet (`docs/PMO_WEEKLY_WORK_REPORT.md`, `docs/TIMESHEET_TASK_MPSeCNet_18Jun_07Aug_2026.md`). This document covers **only 7–19 August 2026**.
