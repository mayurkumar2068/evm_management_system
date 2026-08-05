# Monthly Work Progress Report

## Project: MPSeCNet — Mobile Application for Election Field Services

| Field | Detail |
|:------|:-------|
| **Project name** | MPSeCNet |
| **Prepared by** | Mayur Bobade, Associate Engineer |
| **Document type** | Monthly Work Progress Report |
| **Reporting period** | 18 June 2026 – 31 July 2026 |
| **Report date** | 31 July 2026 |
| **Prepared for** | Election Department / concerned reviewing authority |
| **Classification** | Internal — for official review |

---

## Document control

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 31 July 2026 | Mayur Bobade | Initial draft |
| 1.1 | 31 July 2026 | Mayur Bobade | Status wording corrected; Election Department assigned work only |
| 1.2 | 31 July 2026 | Mayur Bobade | EVM scanning module recorded as starting work |
| 1.3 | 31 July 2026 | Mayur Bobade | Open items framed as department dependency |
| 1.4 | 31 July 2026 | Mayur Bobade | Professional rewrite for formal submission |
| 1.5 | 31 July 2026 | Mayur Bobade, Associate Engineer | Documentation polish for official departmental submission |

---

## Status terminology

The following status terms are used consistently throughout this report:

| Term | Definition |
|------|------------|
| **Developed** | Application code, user interface, or integration work has been implemented |
| **Configured** | Environment, URL, or permission settings have been applied |
| **In Testing** | Undergoing device or API checks; not presented as final acceptance |
| **Partial** | Work has been started or partly delivered; remaining scope exists |
| **Open** | Awaiting inputs, decisions, or confirmation from the Election Department |

**Disclaimer:** This report does not state that the application is fully complete, publicly released, or formally accepted for statewide use.

---

## 1. Executive Summary

During the reporting period **18 June 2026 to 31 July 2026**, development work was carried out on the **MPSeCNet** mobile application in support of Election Department field services.

Work began with an **EVM scanning / Control Unit (CU) – Ballot Unit (BU) module** and was subsequently expanded, under departmental direction, to include booth survey access, Presiding Officer screens, urban online nomination, home service portals, branding and profile updates, and local notification setup.

Major areas of progress include:

- Establishment of the mobile application foundation and environment configuration (DEV / UAT / PROD)
- Development of EVM CU / BU registration and scanning as the starting module
- Integration of survey access through in-app WebView, with urban and rural master-data fixes
- Development of Presiding Officer milestones and live मतदान entry using login elector counts
- Development of the urban online nomination path using OLINAPI
- Configuration of related portals (search, expenditure, claim / objection)
- Generation of a PROD-flavour APK on **27 July 2026** for internal checking
- Resolution of local notification display issues on iOS and Android

Status is reported factually as **Developed**, **Configured**, **In Testing**, **Partial**, or **Open**. Formal UAT acceptance, public distribution, and statewide rollout are **not** claimed.

---

## 2. Objectives of the Assignment

The assignment covers digital application support for Election Department / State Election Commission field services through a single mobile application.

### 2.1 Starting objective

Enable EVM-related field capture within the application, including:

- Control Unit (CU) registration
- Ballot Unit (BU) registration
- Barcode / QR scanning
- Inventory-style screens

### 2.2 Expanded objectives (as directed)

1. Officer access to election-related digital services  
2. Booth / polling-station survey  
3. Presiding Officer (पीठासीन अधिकारी) election-day related screens  
4. Online nomination (urban masters)  
5. Related web portals (search, expenditure, claim / objection)  
6. Hindi–English user interface and MPSEC branding  

---

## 3. Technology Stack Used

| Layer | Technology / component |
|-------|------------------------|
| Mobile framework | Flutter application structure |
| Application runtime | GetX (current runtime for state / routing) |
| Survey UI | Angular survey UI hosted for in-app WebView use |
| Local storage | Local JSON database (including device / inventory collections) |
| Environments | DEV / UAT / PROD flavour configuration |
| Secure storage | Secure token storage |
| In-app browsing | WebView for survey and external portals |
| Offline support | Offline sync queue and WebView form submission queue |
| Localisation | English / Hindi translation keys |
| Continuous integration | CI scripts for build / analyse |
| Notifications | Local notification scheduling (iOS / Android) |

**Note:** Items not expressly listed in the source progress record are marked as Not Available.

| Item | Detail |
|------|--------|
| Backend database platform (department-owned) | Not Available |
| Public app store listing status | Not Available (not claimed) |

---

## 4. Major Deliverables

| # | Deliverable | Status |
|---|-------------|--------|
| 1 | EVM scanning module start (CU / BU registration, barcode scanner, inventory UI scaffolding) | Developed |
| 2 | Mobile application base (structure, flavours, API client, local storage) | Developed |
| 3 | Officer / service login (survey login and Presiding Officer login) | Developed |
| 4 | मतदान केंद्र / booth survey (WebView + master-data fixes; `/pssurvey/` in prod flavour) | Developed / Configured |
| 5 | Presiding Officer flow (milestones, booth map, live मतदान with elector-based percentages) | Developed / In Testing |
| 6 | Online nomination — urban path (OLINAPI masters, form steps, local draft save) | Developed |
| 7 | Online nomination — panchayat path | Partial |
| 8 | Home services list (search, survey, व्यय लेखा, दावा / आपत्ति, Presiding Officer, nomination) | Developed |
| 9 | Branding / splash / profile updates | Developed |
| 10 | Claim / objection access via `https://mpsecerms.mp.gov.in/secforms` | Configured |
| 11 | Local reminder notification technical setup | Developed |
| 12 | PROD-flavour APK (`app-prod-release.apk`) dated 27 July 2026 | Available for internal install / test |

---

## 5. Key Achievements

The following achievements are recorded for the reporting period. They reflect implemented work and do not imply formal departmental go-live.

1. **Single-application approach:** EVM scanning was established as the starting module; survey, Presiding Officer, nomination, and portals were added on the same application base.  
2. **Survey usability improvements:** District → body → booth cascade fixes; urban master-call fallbacks; rural जनपद / booth empty-dropdown correction using login BodyID.  
3. **Presiding Officer support:** Milestone and live मतदान screens developed; percentages derived from Male / Female / Other / Total electors in the login response.  
4. **Urban nomination path:** Election / post selection and area cascade via OLINAPI, with multi-step form and local draft save.  
5. **Home and branding alignment:** MPSeCNet naming, MPSEC logo, Hindi service titles, and profile field corrections as instructed.  
6. **Internal build artefact:** PROD-flavour APK generated on 27 July 2026 for internal checking.  
7. **Notification reliability fix:** iOS notification-centre delegate and Android permission / receiver configuration corrected after diagnostic investigation.

---

## 6. Summary of Work Requested versus Work Carried Out

| # | Work area | Work carried out | Current status |
|---|-----------|------------------|----------------|
| 1 | EVM scanning module (starting module) | CU / BU registration screens; barcode scanner module; device / inventory UI scaffolding | Developed (starting module); presently held behind a feature flag while survey / Presiding Officer / nomination services were prioritised. Not presented as finished field rollout |
| 2 | Mobile application base | Flutter structure; environment flavours (dev / uat / prod); API client; local storage | Developed |
| 3 | Officer / service login | Survey login and Presiding Officer login connected to election APIs | Developed; verified with credentials available during development |
| 4 | मतदान केंद्र / booth survey | Angular survey UI inside in-app WebView; district / body / booth master fixes; prod flavour URL set to `/pssurvey/` | Developed and Configured; runtime depends on server / API availability |
| 5 | Presiding Officer (पीठासीन अधिकारी) flow | Milestones; booth map entry; live मतदान entry with percentages from login elector counts | Developed; In Testing with Presiding Officer login response fields |
| 6 | Online nomination (urban) | OLINAPI masters; form steps; local draft save | Developed for urban path; panchayat path remains Partial |
| 7 | Home services list | Tiles for search, survey, व्यय लेखा, दावा / आपत्ति, Presiding Officer, nomination | Developed as per department UI instructions |
| 8 | Branding / splash / profile | MPSEC logo; titles; profile fields (UserName, Urban / Rural, निकाय label) | Developed as per instructions received |
| 9 | Claim / objection access | Tile opens `https://mpsecerms.mp.gov.in/secforms` in WebView | Configured; behaviour depends on the external website |
| 10 | Local reminder notification | Scheduling logic; iOS / Android permission setup fixes | Developed; official reminder timings await department confirmation (Open) |
| 11 | Internal APK for checking | PROD-flavour APK built on 27 July 2026 | Available for internal install / test — not a public store release |

---

## 7. Week-wise Progress

### 7.1 Week 1 — 18 to 22 June 2026

**Focus:** Application foundation, beginning from the EVM scanning / CU–BU module

**Work carried out**

- Project setup and application structure  
- Network client and secure token storage  
- Design system and shared UI components  
- Auth and dashboard scaffolding  
- EVM starting screens: Control Unit (CU) and Ballot Unit (BU) registration scaffolding  
- Local JSON database (including device / inventory collections)  
- Environment files for DEV / UAT / PROD  
- Baseline project documentation  

**Status:** Developed — foundation and EVM scanning module start. Later weeks expanded the same application for survey / Presiding Officer / nomination as directed.

---

### 7.2 Week 2 — 23 to 29 June 2026

**Focus:** Continue EVM capture path; survey access from mobile; Hindi / English; offline support

**Work carried out**

- English / Hindi translation keys  
- Continued scanner capability on the EVM module track  
- WebView module for survey / portals inside the application  
- Service login screen (officer gate before services)  
- Offline sync queue and WebView form submission queue  
- Profile, settings, and onboarding screens  
- CI scripts for build / analyse  

**Status:** Developed — EVM module track continued alongside survey-in-app path and offline queue.

---

### 7.3 Week 3 — 30 June to 6 July 2026

**Focus:** Application navigation shell and first Presiding Officer screens

**Work carried out**

- Bottom navigation (Dashboard / Profile)  
- Language and theme preference handling  
- Presiding Officer data layer and local milestone / turnout UI (first version)  
- Offline status UI  
- Dashboard structure cleanup  

**Status:** Developed — Presiding Officer screens (first version); later weeks connected additional API / login data.

---

### 7.4 Week 4 — 7 to 13 July 2026

**Focus:** Connect application to Election Commission APIs and present required home services

**Work carried out**

- Application state / routing moved to GetX (current runtime)  
- Environment URLs pointed to POElectionAPI / related MPSEC services used in this project  
- Home tiles expanded for voter search, booth survey, Presiding Officer, nomination, expenditure  
- Profile display of session-based officer data  

**Status:** Developed — API wiring for development / testing environments. Formal departmental acceptance remains a separate step.

---

### 7.5 Week 5 — 14 to 20 July 2026

**Focus:** Booth survey master-data issues (urban / rural) and stable survey opening from the application

**Work carried out**

- Code published to the project repository  
- Survey web staging support for checking  
- Fixes for district → body → booth cascade  
- Urban body / polling-station master call fallbacks  
- Rural जनपद / booth empty-dropdown fix (prefer login BodyID)  
- Theme alignment for login / survey screens  
- Survey WebView base URL set to production host path `/pssurvey/` in prod flavour configuration  

**Status:** Developed and Configured — survey integration fixes. Runtime opening depends on server response and network. Statewide rollout approval is not claimed.

---

### 7.6 Week 6 — 21 to 27 July 2026

**Focus:** Online nomination (urban) and Presiding Officer / home changes as instructed

#### A. Online nomination

- Urban election / post selection from OLINAPI  
- District → urban body → ward (ward only where post rule requires)  
- Multi-step form and local draft save  
- Entry UI for urban / panchayat  

**Status:** Developed for urban path. Panchayat full API parity remains **Partial**. Nomination registration (userid / password) is not presented as a finished, department-accepted feature.

#### B. Home / branding / Presiding Officer changes

- Application display name set as MPSeCNet  
- Splash logo updated with the provided MPSEC logo asset  
- Home titles updated:
  - मतदान केंद्र सर्वे  
  - निर्वाचन व्यय लेखा  
  - दावा / आपत्ति आवेदन (opens secforms URL)  
- Smaller home service cards  
- Presiding Officer login kept separate from survey login (fresh login)  
- Milestone Hindi text and order updates  
- Live मतदान screen: percentages based on Male / Female / Other / Total electors from login response  
- Profile: UserName instead of UserId GUID; role text पीठासीन अधिकारी; Urban / Rural; जनपद for R / नगरीय निकाय for U; खाता heading and offline-storage row removed as instructed  
- PROD-flavour APK generated for internal checking  

**Status:** Developed — UI / API wiring as instructed. APK is for internal install / test only.

---

### 7.7 Week 7 — 28 to 31 July 2026

**Focus:** Local notification check (turnout reminder test)

**Work carried out**

- Investigated why schedule appeared in logs but notification did not display  
- Identified missing iOS notification-centre delegate configuration  
- Updated iOS AppDelegate and Android notification permissions / receivers  
- Adjusted schedule code (timezone, present flags, notification channel)  

**Status:** Developed — technical fix completed. Official reminder timings and message policy remain **Open** (awaiting department confirmation).

---

## 8. Technical Challenges and Resolutions

| Challenge | Resolution | Period |
|-----------|------------|--------|
| Rural जनपद / booth dropdowns appearing empty | Prefer login BodyID in master resolution | Week 5 (14–20 July 2026) |
| Urban body / polling-station master call failures | Path and query fallbacks for master calls | Week 5 (14–20 July 2026) |
| District → body → booth cascade instability | Cascade fixes for full district list and child masters | Week 5 (14–20 July 2026) |
| Presiding Officer session reuse with survey login | Fresh Presiding Officer login enforced (separate from survey login) | Week 6 (21–27 July 2026) |
| Local notification scheduled in logs but not displayed | iOS notification-centre delegate set; Android permissions / receivers updated; schedule presentation flags adjusted | Week 7 (28–31 July 2026) |

---

## 9. Systems and Integrations Referred

| System / URL area | Purpose |
|-------------------|---------|
| POElectionAPI | Survey / Presiding Officer related APIs and login |
| OLINAPI | Urban nomination masters |
| SECSearch / mpsecerms | Voter search opened in WebView |
| CandidateExpenditure | व्यय लेखा opened in WebView |
| secforms (`https://mpsecerms.mp.gov.in/secforms`) | दावा / आपत्ति आवेदन opened in WebView |
| `/pssurvey/` | Survey web base URL in prod flavour configuration |

---

## 10. Repository / Build Activity Summary

| Date | Update |
|------|--------|
| 17 July 2026 | Survey-related fixes and code publish |
| 20 July 2026 | Code publish |
| 22 July 2026 | Code publish |
| 24 July 2026 | Online nomination related work publish |
| 27 July 2026 | Presiding Officer / home / branding changes; PROD-flavour APK built locally |
| 29 July 2026 | Local notification related changes publish |

### Internal APK note

| Item | Detail |
|------|--------|
| Artefact | `app-prod-release.apk` |
| Flavour | PROD |
| Build date | 27 July 2026 |
| Intended use | Internal testing |
| Public store publishing | Not claimed |
| Formal go-live declaration | Not claimed |

---

## 11. Testing and Validation Summary

| Activity | Detail | Status |
|----------|--------|--------|
| Officer / service login verification | Verified with credentials available during development | Developed (development-time verification) |
| Survey opening and master-data paths | Urban / rural cascade and BodyID-related fixes exercised during development | Developed / Configured; runtime depends on server / API |
| Presiding Officer live मतदान percentages | Exercised with Presiding Officer login response fields | In Testing |
| Local notification schedule test | Schedule visible in logs; display issue diagnosed and fixed | Developed (technical fix); official policy still Open |
| Formal UAT by Election Department | Schedule, credentials, and written acceptance | Open |
| Independent QA sign-off pack | Not Available | Not Available |

---

## 12. Risks / Dependencies

| Risk / dependency | Nature | Impact if unresolved |
|-------------------|--------|----------------------|
| Formal UAT / acceptance | Dependency on Election Department | Application cannot be treated as formally accepted |
| Public or enterprise distribution | Dependency on Election Department | Internal APK remains limited to install / test use |
| Official release signing | Dependency on organisation / department | Store or enterprise packaging cannot proceed |
| Panchayat nomination full API flow | Dependency on Election Department / backend | Urban–panchayat parity remains Partial |
| Official notification schedule | Dependency on Election Department | Reminder service cannot be treated as policy-complete |
| EVM scanning field enablement | Dependency on Election Department priority decision | Module remains behind feature flag |
| Backend / hosting stability | Dependency on Election Department backend / hosting | Login, masters, and survey responses may fail at runtime |

---

## 13. Pending Activities (Open Items)

The following items remain **Open**. Closure depends on Election Department inputs, decisions, or confirmation, and not only on further mobile development.

| Open item | Dependency on Election Department |
|-----------|-----------------------------------|
| Formal UAT / acceptance of the application build | UAT schedule, test credentials, and written acceptance |
| Public or enterprise distribution | Distribution decision, store / enterprise account, and release approval |
| Official release signing (keystore / certificate) | Signing credentials and release-process ownership |
| Panchayat nomination full API flow (parity with urban) | Confirmed API readiness, field rules, and go-ahead for remaining steps |
| Official local-notification schedule (election-day reminder policy) | Approved reminder timings, message text, and trigger rules |
| EVM scanning module enablement for field use | Priority decision to re-enable CU / BU scanning (module already started; presently held behind feature flag while other services were prioritised) |
| Stable master data / login / survey responses during use | Backend / hosting uptime, correct master data, and officer environment access |

**Note:** Mobile-side work for assigned items has been carried out as listed in this report. Closure of the above items requires department-side action or confirmation.

---

## 14. Recommendations

The following recommendations are limited to enabling closure of items already identified in this report:

1. Schedule formal UAT with nominated credentials and written acceptance criteria.  
2. Confirm distribution approach (enterprise package versus store) and release signing ownership.  
3. Provide go-ahead and API readiness confirmation for remaining panchayat nomination steps, if required.  
4. Finalise election-day local-notification timings and message text, if reminders are to be used operationally.  
5. Confirm whether the EVM scanning module should be re-enabled for field use or remain deferred.  
6. Ensure backend / hosting availability for officer login, masters, and survey during validation windows.

---

## 15. Conclusion

During **18 June 2026 – 31 July 2026**, work on MPSeCNet was carried out for Election Department mobile application tasks. Engagement **started from an EVM scanning / CU–BU module**, and the same application was expanded for survey access, Presiding Officer screens, urban nomination integration, home service tiles / portals, branding and profile corrections as instructed, and local notification setup fixes.

Status throughout this document is reported as **Developed**, **Configured**, **In Testing**, **Partial**, or **Open**, as applicable. This document does **not** claim that the solution is fully complete, publicly live for all users, or formally accepted for statewide production use.

Any go-live declaration should follow formal acceptance by the Election Department.

---

## Appendix A — Glossary of Module and Service Names

| Name | Usage in this report |
|------|----------------------|
| MPSeCNet | Mobile application project name |
| EVM | Electronic Voting Machine related module (CU / BU) |
| CU | Control Unit |
| BU | Ballot Unit |
| Presiding Officer / पीठासीन अधिकारी | Election-day officer flow |
| POElectionAPI | Survey / Presiding Officer APIs and login |
| OLINAPI | Urban nomination masters |
| `/pssurvey/` | Survey web base path in prod flavour configuration |
| secforms | Claim / objection portal path under mpsecerms |

---

## Appendix B — Document Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 31 July 2026 | Mayur Bobade | Initial draft |
| 1.1 | 31 July 2026 | Mayur Bobade | Status wording corrected; Election Department assigned work only |
| 1.2 | 31 July 2026 | Mayur Bobade | EVM scanning module recorded as starting work |
| 1.3 | 31 July 2026 | Mayur Bobade | Open items framed as department dependency |
| 1.4 | 31 July 2026 | Mayur Bobade | Professional rewrite for formal submission |
| 1.5 | 31 July 2026 | Mayur Bobade, Associate Engineer | Polished Monthly Work Progress Report for official submission |

---

**Prepared by**

**Mayur Bobade**  
Associate Engineer  

**Date:** 31 July 2026  

---

*End of report*
