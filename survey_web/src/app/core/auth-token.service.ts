import { Injectable, signal } from '@angular/core';

import { APP_PARAMS } from './app-params';

/**
 * Holds the session token passed by the Flutter WebView as `?token=`.
 * Attached to every API request by {@link apiInterceptor}.
 */
@Injectable({ providedIn: 'root' })
export class AuthTokenService {
  private readonly tokenState = signal<string>(APP_PARAMS.token);

  get token(): string {
    return this.tokenState();
  }

  setToken(value: string): void {
    this.tokenState.set((value ?? '').trim());
  }

  get isAuthenticated(): boolean {
    return this.token.length > 0;
  }
}
