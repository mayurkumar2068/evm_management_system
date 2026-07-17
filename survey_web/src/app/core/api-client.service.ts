import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../../environments/environment';

/** Standard `{ Status, Message, Data }` envelope from POElection / PSSurvey APIs. */
export interface ApiEnvelope<T> {
  Status: boolean;
  Message?: string;
  Data: T;
}

@Injectable({ providedIn: 'root' })
export class ApiClientService {
  private readonly http = inject(HttpClient);
  readonly baseUrl = environment.apiBaseUrl.replace(/\/+$/, '');

  get useMockData(): boolean {
    return environment.useMockData || !this.baseUrl;
  }

  /** Builds a fully-qualified API URL under the configured base. */
  url(path: string): string {
    const normalized = path.startsWith('/') ? path : `/${path}`;
    return `${this.baseUrl}${normalized}`;
  }

  get<T>(path: string, options?: Parameters<HttpClient['get']>[1]): Observable<T> {
    return this.http.get<T>(this.url(path), options);
  }

  post<T>(
    path: string,
    body: unknown,
    options?: Parameters<HttpClient['post']>[2],
  ): Observable<T> {
    return this.http.post<T>(this.url(path), body, options);
  }

  /** Unwraps `{ Status, Data }` and throws when `Status` is false. */
  unwrap<T>(res: ApiEnvelope<T>): T {
    if (!res?.Status) {
      throw new Error(res?.Message || 'API request failed');
    }
    return res.Data;
  }

  unwrapGet<T>(path: string): Observable<T> {
    return this.get<ApiEnvelope<T>>(path).pipe(map((res) => this.unwrap(res)));
  }

  unwrapPost<T>(path: string, body: unknown): Observable<T> {
    return this.post<ApiEnvelope<T>>(path, body).pipe(map((res) => this.unwrap(res)));
  }

  toUserMessage(error: unknown, fallback = 'Request failed'): string {
    if (error instanceof HttpErrorResponse) {
      const body = error.error;
      if (body && typeof body === 'object' && 'Message' in body) {
        const message = (body as { Message?: string }).Message;
        if (message?.trim()) {
          return message.trim();
        }
      }
      if (error.status === 0) {
        return 'Network error — check connection';
      }
      return error.message || fallback;
    }
    if (error instanceof Error && error.message) {
      return error.message;
    }
    return fallback;
  }

  fail(error: unknown, fallback = 'Request failed'): Observable<never> {
    return throwError(() => new Error(this.toUserMessage(error, fallback)));
  }
}
