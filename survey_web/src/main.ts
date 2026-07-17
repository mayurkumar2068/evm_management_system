import { bootstrapApplication } from '@angular/platform-browser';

// Capture the WebView launch params (?token, ?lang) before the router rewrites
// the URL. Importing first guarantees the module evaluates at load time.
import './app/core/app-params';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig).catch((err) =>
  // eslint-disable-next-line no-console
  console.error(err),
);
