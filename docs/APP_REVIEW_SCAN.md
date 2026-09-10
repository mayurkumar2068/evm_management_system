# App Review scan — MPSeCNet (`1.0.0+2`)

Mapped against Apple App Review Guidelines (Safety / Performance / Legal) + Play Data Safety.

## Ready

| Item | Status |
| --- | --- |
| Bundle IDs `com.mpsec.mpsecnet` (Play + iOS) | OK |
| Version `1.0.0+2` | OK |
| Privacy policy URL (in-app + stores) | OK — `https://mplocalelection.mp.gov.in/privacystatement.aspx` |
| `PrivacyInfo.xcprivacy` (9 types, no tracking, no Sensitive Info / Email) | OK |
| Camera / Location / Photos usage strings | OK — field-work wording |
| Android: no broad photo library (`READ_MEDIA_*` removed) | OK |
| Guest dashboard usable without officer login | OK — reduces 2.1 login-gate risk |
| Online Nomination / EMS / Expenditure hidden | OK — incomplete flows off |
| Android upload keystore present | OK |

## Before submit (you must do in consoles)

| Risk | Guideline | Action |
| --- | --- | --- |
| **Demo officer login** | 2.1 Completeness | Put **PS Survey + PO** demo credentials in App Review / Play review notes. Backend must stay live. |
| **Accurate metadata** | 2.3 / Play listing | Screenshots of real dashboard (not splash). Description must match guest + officer services shown. |
| **Contact / Support URL** | 1.5 | App Store + Play: working support email / URL. |
| **App Privacy / Data safety** | 5.1 / Play | Match the 9 types: Name, Phone, Physical Address, Precise Location, Photos, Other User Content, Search History, User ID, Device ID. Do **not** claim Email or Sensitive Info. |
| **Apple Distribution cert** | Signing | This Mac currently has **Development** identities only — create/install **Apple Distribution** + App Store profile for `com.mpsec.mpsecnet` before IPA export. |

## Artifacts

| Store | Command | Output | Status |
| --- | --- | --- | --- |
| Google Play | `./scripts/build_prod_aab.sh` | `build/app/outputs/bundle/prodRelease/app-prod-release.aab` (75MB) | **Built** |
| App Store | `./scripts/build_prod_ipa.sh` | `build/ios/ipa/MPSeCNet.ipa` (27MB) | **Built** |

Prod iOS signing team: `TL9438U9T3` (aligned with Release config). Upload IPA via [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) or `xcrun altool`.

**Warning from build:** default Flutter launch image — replace before final review if Apple flags 2.3 / placeholder assets.

## Suggested App Review notes (paste)

```
MPSeCNet — Madhya Pradesh State Election Commission field app.

Guest mode: dashboard opens without login. Voter Search and Claims & Objections
(WebView) work without officer credentials.

Officer login (review credentials below):
- Polling Station Survey: <USER> / <PASS or OTP mobile>
- Presiding Officer: <USER> / <PASS>

Location/camera/photos are requested only when the officer uses survey capture
or barcode scan — not at launch.

Privacy policy: https://mplocalelection.mp.gov.in/privacystatement.aspx
```
