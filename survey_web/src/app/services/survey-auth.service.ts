import { Injectable, inject } from '@angular/core';
import { Observable, map, of, tap } from 'rxjs';

import { ApiClientService } from '../core/api-client.service';
import { APP_PARAMS } from '../core/app-params';
import { AuthTokenService } from '../core/auth-token.service';
import {
  SurveyLoginData,
  SurveyLoginRequest,
  SurveySession,
} from '../models/survey-auth.model';

/**
 * Survey officer authentication via `POST /api/Account/login-survey-pass`.
 *
 * Flutter normally passes `?token=&userId=&districtId=` in the WebView URL.
 * Credentials in the URL are supported as a fallback for standalone testing.
 */
@Injectable({ providedIn: 'root' })
export class SurveyAuthService {
  private readonly api = inject(ApiClientService);
  private readonly authToken = inject(AuthTokenService);

  private sessionState: SurveySession | null = this.readInitialSession();

  get session(): SurveySession | null {
    return this.sessionState;
  }

  get userId(): string {
    return this.sessionState?.userId || APP_PARAMS.userId.trim();
  }

  ensureAuthenticated(): Observable<SurveySession | null> {
    if (this.authToken.isAuthenticated && this.sessionState) {
      return of(this.sessionState);
    }

    if (this.authToken.isAuthenticated) {
      this.sessionState = this.readInitialSession();
      return of(this.sessionState);
    }

    if (!APP_PARAMS.userName || !APP_PARAMS.password) {
      return of(this.sessionState);
    }

    return this.loginSurveyPass({
      userName: APP_PARAMS.userName,
      password: APP_PARAMS.password,
    }).pipe(
      tap((data) => {
        this.authToken.setToken(data.AccessToken);
        this.sessionState = this.sessionFromLogin(data);
      }),
      map(() => this.sessionState),
    );
  }

  loginSurveyPass(payload: SurveyLoginRequest): Observable<SurveyLoginData> {
    return this.api.unwrapPost<SurveyLoginData>(
      '/api/Account/login-survey-pass',
      payload,
    );
  }

  private readInitialSession(): SurveySession | null {
    const userId = APP_PARAMS.userId.trim();
    const districtId = APP_PARAMS.districtId.trim();
    const bodyId = APP_PARAMS.bodyId.trim();
    const urbanRural = normalizeUrbanRural(APP_PARAMS.urbanRural);

    if (!userId && !districtId && !this.authToken.isAuthenticated) {
      return null;
    }

    return {
      userId,
      districtId,
      distName: APP_PARAMS.distName.trim(),
      bodyId,
      bodyName: APP_PARAMS.bodyName.trim(),
      urbanRural,
      electionId: APP_PARAMS.electionId,
      psId: APP_PARAMS.psId.trim(),
      lat: APP_PARAMS.boothLat ?? null,
      long: APP_PARAMS.boothLong ?? null,
    };
  }

  private sessionFromLogin(data: SurveyLoginData): SurveySession {
    const electionIdRaw = Number(data.ElectionId);
    const electionId =
      Number.isFinite(electionIdRaw) && electionIdRaw > 0 ? electionIdRaw : null;

    return {
      userId: data.UserId?.trim() ?? '',
      districtId: data.DistID?.trim() ?? APP_PARAMS.districtId.trim(),
      distName: data.DistName?.trim() ?? APP_PARAMS.distName.trim(),
      bodyId: data.BodyID?.trim() ?? APP_PARAMS.bodyId.trim(),
      bodyName:
        data.UBName?.trim() ??
        data.BlockName?.trim() ??
        APP_PARAMS.bodyName.trim(),
      urbanRural: normalizeUrbanRural(data.UrbanRural),
      electionId,
      psId: data.PSID?.trim() ?? APP_PARAMS.psId.trim(),
      lat: parseCoord(data.Lat ?? data.lat),
      long: parseCoord(data.Long ?? data.long),
    };
  }
}

function parseCoord(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : null;
}

function normalizeUrbanRural(value: string | null | undefined): 'U' | 'R' | null {
  const normalized = (value ?? '').trim().toUpperCase();
  if (normalized === 'U' || normalized === 'URBAN') {
    return 'U';
  }
  if (normalized === 'R' || normalized === 'RURAL') {
    return 'R';
  }
  return null;
}
