import {
  HttpErrorResponse,
  HttpInterceptorFn,
  HttpResponse,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, from, of, switchMap, throwError } from 'rxjs';

import { environment } from '../../environments/environment';
import { AuthTokenService } from './auth-token.service';
import { nativeApiRequest, shouldUseNativeApiBridge } from './bridge-api.util';

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

  if (shouldUseNativeApiBridge(cloned.url)) {
    return from(nativeApiRequest(cloned)).pipe(
      switchMap((result) => {
        if (result.status >= 400 || result.status === 0) {
          return throwError(
            () =>
              new HttpErrorResponse({
                error: result.body,
                status: result.status || 0,
                statusText: result.statusText,
                url: cloned.url,
              }),
          );
        }
        return of(
          new HttpResponse({
            body: result.body,
            status: result.status,
            url: cloned.url,
          }),
        );
      }),
      catchError((error: unknown) => {
        // eslint-disable-next-line no-console
        console.error(`[API] ${cloned.method} ${cloned.urlWithParams}`, error);
        return throwError(() => error);
      }),
    );
  }

  return next(cloned).pipe(
    catchError((error: HttpErrorResponse) => {
      // eslint-disable-next-line no-console
      console.error(
        `[API] ${cloned.method} ${cloned.urlWithParams}`,
        error.status,
        error.error,
      );
      return throwError(() => error);
    }),
  );
};
