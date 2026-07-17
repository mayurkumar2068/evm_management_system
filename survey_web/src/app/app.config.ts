import {
  ApplicationConfig,
  provideZoneChangeDetection,
} from '@angular/core';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { APP_ROUTES } from './app.routes';
import { apiInterceptor } from './core/api.interceptor';
import { provideServiceWorker } from '@angular/service-worker';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(APP_ROUTES, withComponentInputBinding()),
    provideHttpClient(withInterceptors([apiInterceptor])),
    provideAnimationsAsync(),
    // Disabled: SW hangs InAppWebView load on GitHub Pages / IIS deep links.
    provideServiceWorker('ngsw-worker.js', {
      enabled: false,
      registrationStrategy: 'registerWhenStable:30000',
    }),
  ],
};
