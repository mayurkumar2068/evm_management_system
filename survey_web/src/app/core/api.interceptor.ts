import {
  HttpInterceptorFn,
  HttpErrorResponse,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

import { environment } from '../../environments/environment';
import { AuthTokenService } from './auth-token.service';

const API_SEGMENT = '/api/';

function isApiRequest(url: string): boolean {
  return url.includes(API_SEGMENT);
}

export const apiInterceptor: HttpInterceptorFn = (req, next) => {
  if (!isApiRequest(req.url)) {
    return next(req);
  }

  const token = inject(AuthTokenService).token;
  const cloned = req.clone({
    setHeaders: token ? { Authorization: `Bearer ${token}` } : {},
    setParams: {
      ...(token && !req.params.has('token') ? { token } : {}),
    },
  });

  if (!environment.production) {
    // eslint-disable-next-line no-console
    console.debug(`[API] ${cloned.method} ${cloned.urlWithParams}`);
  }

  return next(cloned).pipe(
    catchError((error: HttpErrorResponse) => {
      // eslint-disable-next-line no-console
      console.error(`[API] ${cloned.method} ${cloned.urlWithParams}`, error.status, error.error);
      return throwError(() => error);
    }),
  );
};
