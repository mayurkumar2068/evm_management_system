# POElectionAPI — DEV & PROD curl (copy-paste)

Replace `{token}`, `{distId}`, `{bodyId}` from login response.

## Bases

| Env | API base | Survey web | Voter search |
|-----|----------|------------|--------------|
| **DEV** | `http://10.115.197.192/POElectionAPI` | `http://10.115.197.192/pssurvey/` | `https://mpsecerms.mp.gov.in/SECSearchEngine` |
| **PROD** | `https://mpsecerms.mp.gov.in/POElectionAPI` | `https://mpsecerms.mp.gov.in/pssurvey/` | `https://mpsecerms.mp.gov.in/SECSearchEngine` |

---

## 1. Survey login (मतदान केंद्र — urban test user `su1`)

**DEV**
```bash
curl -X POST 'http://10.115.197.192/POElectionAPI/api/Account/login-survey-pass' -H 'Content-Type: application/json' -H 'Accept: application/json' -d '{"userName":"su1","password":"su1"}'
```

**PROD**
```bash
curl -X POST 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Account/login-survey-pass' -H 'Content-Type: application/json' -H 'Accept: application/json' -d '{"userName":"su1","password":"su1"}'
```

## 2. PO login (Presiding officer — release prod flow)

**DEV**
```bash
curl -X POST 'http://10.115.197.192/POElectionAPI/api/Account/login-po-pass' -H 'Content-Type: application/json' -H 'Accept: application/json' -d '{"userName":"<po_user>","password":"<po_pass>"}'
```

**PROD**
```bash
curl -X POST 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Account/login-po-pass' -H 'Content-Type: application/json' -H 'Accept: application/json' -d '{"userName":"<po_user>","password":"<po_pass>"}'
```

---

## 3. Masters — urban cascade (after survey login)

**District**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/Masters/districts/{distId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Masters/districts/{distId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

**Urban body list**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/Masters/ub-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Masters/ub-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

**Urban polling stations (मतदान केंद्र dropdown)**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/Masters/ups-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Masters/ups-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

---

## 4. Masters — rural cascade (test user `sr1`)

**Block list**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/Masters/block-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Masters/block-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

**Rural polling stations**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/Masters/rps-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/Masters/rps-list/{bodyId}' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

---

## 5. Survey checklist

**Questions**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/PSSurvey/survey_questions' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/PSSurvey/survey_questions' -H 'Authorization: Bearer {token}' --data-urlencode 'token={token}'`

**Save answer**

DEV: `curl -X POST 'http://10.115.197.192/POElectionAPI/api/PSSurvey/save_survey_answer' -H 'Content-Type: application/json' -H 'Authorization: Bearer {token}' -d '{"questionId":"<id>","answerYN":true,"answerText":"Yes","remark":"","psType":"U","psId":"<psId>","lat":23.25,"long":77.41,"userId":"<userId>"}'`

PROD: `curl -X POST 'https://mpsecerms.mp.gov.in/POElectionAPI/api/PSSurvey/save_survey_answer' -H 'Content-Type: application/json' -H 'Authorization: Bearer {token}' -d '{"questionId":"<id>","answerYN":true,"answerText":"Yes","remark":"","psType":"U","psId":"<psId>","lat":23.25,"long":77.41,"userId":"<userId>"}'`

---

## 5b. Survey reports (district / PS / urban–rural)

Full request/response: [`docs/SURVEY_REPORTS_API.md`](SURVEY_REPORTS_API.md)

**DEV**
```bash
curl -G 'http://10.115.197.192/POElectionAPI/api/PSSurvey/survey_reports' \
  -H 'Authorization: Bearer {token}' -H 'Accept: application/json' \
  --data-urlencode 'token={token}' \
  --data-urlencode 'from=2026-07-01' \
  --data-urlencode 'to=2026-07-21' \
  --data-urlencode 'areaType=all'
```

**PROD**
```bash
curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/PSSurvey/survey_reports' \
  -H 'Authorization: Bearer {token}' -H 'Accept: application/json' \
  --data-urlencode 'token={token}' \
  --data-urlencode 'from=2026-07-01' \
  --data-urlencode 'to=2026-07-21' \
  --data-urlencode 'areaType=all'
```

---

## 6. PO Election milestones (sample)

**Get PO status**

DEV: `curl -G 'http://10.115.197.192/POElectionAPI/api/POElection/get-po-status' --data-urlencode 'id={userId}' -H 'Authorization: Bearer {token}'`

PROD: `curl -G 'https://mpsecerms.mp.gov.in/POElectionAPI/api/POElection/get-po-status' --data-urlencode 'id={userId}' -H 'Authorization: Bearer {token}'`

---

## Swagger / OpenAPI

Import in Swagger UI or Postman:

`docs/po-election-api.openapi.yaml`
