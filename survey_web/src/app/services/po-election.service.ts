import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map, of, switchMap, tap } from 'rxjs';

import { environment } from '../../environments/environment';
import { APP_PARAMS } from '../core/app-params';
import { AuthTokenService } from '../core/auth-token.service';
import { resolveApiBaseUrl } from '../core/resolve-api-base';
import {
  PoActionRequest,
  PoActionResponse,
  PoApiResponse,
  PoContext,
  PoCountRequest,
  PoLoginData,
  PoLoginRequest,
  PoPollLiveRequest,
  PoStatusData,
} from '../models/po-election.model';

@Injectable({ providedIn: 'root' })
export class PoElectionService {
  private readonly http = inject(HttpClient);
  private readonly authToken = inject(AuthTokenService);
  private readonly base = resolveApiBaseUrl(environment.apiBaseUrl);

  private contextState: PoContext | null = this.readInitialContext();

  get context(): PoContext | null {
    return this.contextState;
  }

  ensureAuthenticated(): Observable<PoContext | null> {
    const current = this.contextState;
    if (this.authToken.isAuthenticated && current) {
      return of(current);
    }

    if (this.authToken.isAuthenticated) {
      return of(current);
    }

    if (!APP_PARAMS.userName || !APP_PARAMS.password) {
      return of(current);
    }

    return this.loginPoPass({
      userName: APP_PARAMS.userName,
      password: APP_PARAMS.password,
    }).pipe(
      tap((data) => {
        this.authToken.setToken(data.AccessToken);
        this.contextState = {
          userId: data.UserId,
          electionId: Number(data.ElectionId) || APP_PARAMS.electionId || 0,
          psId: data.PSID || APP_PARAMS.psId,
        };
      }),
      map(() => this.contextState),
    );
  }

  loginPoPass(payload: PoLoginRequest): Observable<PoLoginData> {
    return this.http
      .post<PoApiResponse<PoLoginData>>(this.endpoint('/api/Account/login-po-pass'), payload)
      .pipe(map((res) => this.unwrap(res)));
  }

  getPoStatus(userId: string): Observable<PoStatusData> {
    return this.http
      .get<PoApiResponse<PoStatusData>>(this.endpoint('/api/POElection/get-po-status'), {
        params: { id: userId },
      })
      .pipe(map((res) => this.unwrap(res)));
  }

  insertDepartFromHome(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-depart-from-home', payload);
  }

  insertReachedToPs(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-reached-to-ps', payload);
  }

  insertMaterialReceived(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-material-received', payload);
  }

  insertMockPollConducted(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-mock-poll-conducted', payload);
  }

  insertPollStarted(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-poll-started', payload);
  }

  insertPollEnded(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-poll-ended', payload);
  }

  insertMachineSealed(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-machine-sealed', payload);
  }

  insertMaterialSubmitted(payload: PoActionRequest): Observable<PoActionResponse> {
    return this.postAction('/api/POElection/insert-material-submitted', payload);
  }

  insert09AmCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-09am-count', payload);
  }

  insert11AmCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-11am-count', payload);
  }

  insert01PmCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-01pm-count', payload);
  }

  insert03PmCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-03pm-count', payload);
  }

  insert05PmCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-05pm-count', payload);
  }

  insertLineCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-line-count', payload);
  }

  insertFinalCount(payload: PoCountRequest): Observable<number> {
    return this.postCount('/api/POElection/insert-final-count', payload);
  }

  savePollLive(payload: PoPollLiveRequest): Observable<number> {
    return this.http
      .post<number>(this.endpoint('/api/POElection/save-poll-live'), payload)
      .pipe(map((res) => Number(res)));
  }

  syncStatusIfPossible(): Observable<PoStatusData | null> {
    return this.ensureAuthenticated().pipe(
      switchMap((ctx) => {
        if (!ctx?.userId) {
          return of(null);
        }
        return this.getPoStatus(ctx.userId).pipe(
          tap((status) => {
            this.contextState = {
              userId: ctx.userId,
              electionId: status.ElectionId || ctx.electionId,
              psId: status.PSId || ctx.psId,
            };
          }),
        );
      }),
    );
  }

  private postAction(path: string, payload: PoActionRequest): Observable<PoActionResponse> {
    return this.http.post<PoActionResponse>(this.endpoint(path), payload);
  }

  private postCount(path: string, payload: PoCountRequest): Observable<number> {
    return this.http.post<number>(this.endpoint(path), payload).pipe(map((res) => Number(res)));
  }

  private endpoint(path: string): string {
    const normalized = path.startsWith('/') ? path : `/${path}`;
    return `${this.base}${normalized}`;
  }

  private unwrap<T>(res: PoApiResponse<T>): T {
    if (!res?.Status) {
      throw new Error(res?.Message || 'PO API error');
    }
    return res.Data;
  }

  private readInitialContext(): PoContext | null {
    const userId = APP_PARAMS.userId.trim();
    const psId = APP_PARAMS.psId.trim();
    const electionId = APP_PARAMS.electionId;

    if (!userId || !psId || !electionId) {
      return null;
    }

    return { userId, psId, electionId };
  }
}
