# MP Election – Survey Micro-App (Angular 18)

A standalone, mobile-first Angular 18 application for the **मतदान केंद्र चेकलिस्ट
(Polling Booth Survey)**. It is designed to be embedded inside the Flutter app
through `flutter_inappwebview`.

> Note: this folder lives under `lib/survey/` per project convention. It is
> **not** Dart code — it is excluded from the Flutter analyzer via
> `analysis_options.yaml` (`exclude: lib/survey/**`).

## Features

- Standalone components + lazy-loaded routes
- Angular Material (M3 theme tuned to the Election palette `#4338CA`)
- Reactive Forms with strict TypeScript
- Cascading location dropdowns: District → Block → Panchayat → Village → Booth
- Dynamic checklist from API (mock fallback bundled for offline demo)
- Per-row checkbox + camera/gallery upload with on-device JPEG downscaling
- Horizontal uploaded-image gallery with tap-to-enlarge / remove
- Auto geolocation (loading + permission-denied handling, retry)
- Sticky submit button, disabled until validation passes

## Folder structure

```
src/app/
├── pages/
│   ├── location-selection/      # Screen 1 – cascading dropdowns
│   └── survey-checklist/        # Screen 2 – checklist + uploads + submit
├── components/
│   ├── app-header/              # Blue rounded header card (reused)
│   ├── location-card/           # Two-column location details
│   ├── survey-card/             # Checklist container
│   ├── checklist-item/          # Title · checkbox · camera
│   ├── image-upload/            # Camera/gallery + compress + preview
│   └── coordinates-card/        # Dark GPS card
├── services/
│   ├── survey.service.ts        # API stubs + mock data + state carry-over
│   └── geolocation.service.ts   # navigator.geolocation wrapper
├── models/
│   ├── location.model.ts
│   └── survey.model.ts
└── survey.routes.ts
```

## Develop

```bash
cd lib/survey
npm install
npm start            # http://localhost:4200
```

## Build for the WebView

```bash
npm run build:webview   # ng build --configuration production --base-href ./
# output -> lib/survey/dist/mp-election-survey/browser
```

## Connect a real backend

Edit `src/environments/environment.ts`:

```ts
export const environment = {
  production: true,
  apiBaseUrl: 'https://your-api.example.gov.in/api',
  useMockData: false,
};
```

Expected endpoints (see `survey.service.ts`):

| Method | Endpoint                       | Returns               |
| ------ | ------------------------------ | --------------------- |
| GET    | `/locations/districts`         | `LocationOption[]`    |
| GET    | `/locations/blocks?districtId` | `LocationOption[]`    |
| GET    | `/locations/panchayats?blockId`| `LocationOption[]`    |
| GET    | `/locations/villages?panchayatId` | `LocationOption[]` |
| GET    | `/locations/booths?villageId`  | `LocationOption[]`    |
| GET    | `/survey/checklist?boothId`    | `SurveyConfig`        |
| POST   | `/survey/submit`               | `SurveySubmitResponse`|

### Submit payload

```json
{
  "districtId": "",
  "blockId": "",
  "panchayatId": "",
  "villageId": "",
  "boothId": "",
  "latitude": "",
  "longitude": "",
  "surveyItems": [{ "surveyId": "", "checked": true, "image": "base64-image" }]
}
```

## Loading inside Flutter (`flutter_inappwebview`)

**Option A – Hosted/served URL** (simplest): serve the production build on your
server and open it with the existing `WebViewScreen`:

```dart
context.pushNamed(
  AppRoute.webView.name,
  extra: const WebViewArgs(
    title: 'मतदान केंद्र चेकलिस्ट',
    url: 'https://your-host/survey/',
  ),
);
```

**Option B – Bundled offline assets**: copy the built `browser/` output into the
Flutter `assets/` folder, register it in `pubspec.yaml`, and load it via
`InAppWebView`'s asset loading:

```dart
InAppWebView(
  initialUrlRequest: URLRequest(
    url: WebUri('file:///android_asset/flutter_assets/assets/survey/index.html'),
  ),
  initialSettings: InAppWebViewSettings(
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    geolocationEnabled: true,
  ),
)
```

> Geolocation + camera require the host app to grant runtime permissions
> (`ACCESS_FINE_LOCATION`, `CAMERA`) and to handle
> `onGeolocationPermissionsShowPrompt` / `onPermissionRequest` in the
> InAppWebView so the browser APIs resolve.
```
