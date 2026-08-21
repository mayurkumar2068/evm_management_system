# Store release checklist — MPSeCNet

Package IDs (do not change without a new store listing):

| Platform | Identifier |
| --- | --- |
| Google Play | `com.mpsec.mpsecnet` |
| Apple App Store | `com.mpsec.mpsecnet` |
| Dev sideload (Android) | `com.mpsec.mpsecnet.dev` |

Display name: **MPSeCNet**. Current candidate version in `pubspec.yaml`: `1.0.0+2` (versionName `1.0.0`, versionCode / CFBundleVersion `2`).

This checklist covers packaging and console steps. It does **not** create Play / Apple accounts, privacy-policy legal text, or upload credentials for you.

---

## 0. One-time Android upload keystore

Secrets must stay off git (`android/key.properties`, `*.jks` / `*.keystore` are gitignored).

```bash
cp android/key.properties.example android/key.properties
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# Edit android/key.properties: storePassword, keyPassword, keyAlias=upload, storeFile=upload-keystore.jks
```

Back up `upload-keystore.jks` and `key.properties` in an org password vault. Losing the upload key blocks Play updates unless you use Play App Signing recovery.

If a keystore was already generated on this machine for first packaging, reuse that file — do not create a second upload key for the same Play app.

---

## 1. Google Play Console

1. Create the app (or open existing) with package name **`com.mpsec.mpsecnet`**.
2. Complete **Store listing**: short description, full description, screenshots, feature graphic, icon, contact email, privacy policy URL (org must provide the URL).
3. Complete **Content rating**, **Target audience**, **News apps** / **COVID** declarations as applicable.
4. **Data safety** — declare data collected/shared to match the app. Permissions in `android/app/src/main/AndroidManifest.xml` that typically need answers:

   | Permission | Typical use in MPSeCNet |
   | --- | --- |
   | `INTERNET` | API / survey WebView |
   | `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Booth survey GPS tagging |
   | `CAMERA` | EVM barcode scan + survey **camera** capture |
   | `POST_NOTIFICATIONS` | Local reminders / turnout alerts |
   | `VIBRATE` | Notification / scan feedback |
   | `RECEIVE_BOOT_COMPLETED` | Reschedule local notifications after reboot |
   | `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Exact local notification timing |

   **Photos / media (important):** Do **not** declare or request `READ_MEDIA_IMAGES`,
   `READ_EXTERNAL_STORAGE`, or Photos permission. Gallery selection uses the
   [Android Photo Picker](https://developer.android.com/training/data-storage/shared/photopicker)
   (`useAndroidPhotoPicker = true`). Play Data safety: photos are user-selected
   via the system picker / camera, not broad library access.

5. Enable **Play App Signing** (recommended). Upload the AAB signed with your **upload** keystore.
6. Build and upload:

   ```bash
   ./scripts/build_prod_aab.sh
   # or:
   flutter build appbundle --release --flavor prod --dart-define=APP_FLAVOR=prod
   ```

   Artifact: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

7. Create a production (or internal/closed testing) release, attach the AAB, roll out after review.

---

## 2. Apple App Store Connect

1. Create the app with bundle ID **`com.mpsec.mpsecnet`**.
2. In Xcode → Runner target → **Signing & Capabilities**: select your Team, enable **Automatically manage signing** for the **prod** scheme / Release-prod configuration.
3. Privacy strings live in `ios/Runner/Info.plist` (camera, photos, location, Face ID, microphone). Align App Privacy nutrition labels with actual collection (location, photos, identifiers/auth as used).
4. Export options template: copy `ios/ExportOptions.plist.example` → `ios/ExportOptions.plist`, set `teamID` (ExportOptions.plist is gitignored).
5. Build:

   ```bash
   ./scripts/build_prod_ipa.sh
   # or:
   flutter build ipa --release --flavor prod --dart-define=APP_FLAVOR=prod \
     --export-options-plist=ios/ExportOptions.plist
   ```

   Or: Xcode → Product → Archive → Distribute App → App Store Connect.

6. Upload to **TestFlight**, smoke-test, then submit for **App Review** (screenshots, export compliance, review notes for election field use).

---

## 3. Pre-upload smoke test (signed build)

On a physical device install of the signed prod build:

- [ ] Login / logout
- [ ] Presiding Officer flow (turnout, party details)
- [ ] Survey WebView load + photo / location prompts
- [ ] Camera barcode scan (if used on that role)
- [ ] Notifications permission prompt (Android 13+)
- [ ] Offline / poor network behavior if required for your release

---

## 4. Versioning reminder

Bump `pubspec.yaml` `version:` (`name+build`) before each store upload that replaces a previous binary. First store candidate in this repo prep is **`1.0.0+2`**.

See also `docs/DEPLOYMENT.md` for flavor env files and CI notes.
