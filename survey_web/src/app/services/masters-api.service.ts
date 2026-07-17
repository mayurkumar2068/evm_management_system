import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, delay, map, switchMap, tap } from 'rxjs/operators';

import { ApiClientService } from '../core/api-client.service';
import { APP_PARAMS } from '../core/app-params';
import { SurveyOfflineCacheService } from '../core/survey-offline-cache.service';
import { LocationOption } from '../models/location.model';
import { SurveyAuthService } from './survey-auth.service';

interface DistrictDto {
  ID?: string;
  DistID?: string;
  DistName?: string;
  DistNameEn?: string;
}

interface BlockDto {
  ID?: string;
  BlockID?: string;
  BlockName?: string;
  BlockNameEn?: string;
}

interface UrbanBodyDto {
  ID?: string;
  UrbanBodyID?: string;
  BodyID?: string;
  UrbanBodyName?: string;
  UrbanBodyNameEn?: string;
}

interface UrbanPsDto {
  ID?: string;
  PSID?: string;
  PSName?: string;
  PSNoName?: string;
}

interface RuralPsDto {
  ID?: string;
  PSID?: string;
  PSName?: string;
  PSNoName?: string;
}

/**
 * mpsec login-scoped Masters (Postman):
 * Urban: districts/{DistID} → ub-list/{BodyID} → ups-list/{BodyID}
 * Rural: districts/{DistID} → block-list/{BodyID|DistID} → rps-list/{BodyID}
 */
@Injectable({ providedIn: 'root' })
export class MastersApiService {
  private readonly api = inject(ApiClientService);
  private readonly cache = inject(SurveyOfflineCacheService);
  private readonly surveyAuth = inject(SurveyAuthService);

  getDistricts(): Observable<LocationOption[]> {
    const distId = this.loginDistrictId();
    const cacheKey = distId ? `districts:${distId}` : 'districts:all';

    if (distId) {
      return this.cachedFetch<DistrictDto>(
        cacheKey,
        `/api/Masters/districts/${encodeURIComponent(distId)}`,
        mapDistrict,
        this.loginDistrictFallback(),
      );
    }

    const listPaths = [
      '/api/Masters/district-list-all',
      '/api/Masters/districts/list-all',
      '/api/Masters/districts/list',
    ];
    return this.tryListPaths<DistrictDto>(listPaths, mapDistrict, cacheKey);
  }

  /** Rural only — never called from urban cascade. */
  getBlocks(): Observable<LocationOption[]> {
    // Urban login BodyID is a municipal body, not a block — never call block-list with it.
    if (this.isUrbanLogin()) {
      const distId = this.loginDistrictId();
      if (!distId) {
        return of([]);
      }
      return this.cachedFetch<BlockDto>(
        `blocks:dist:${distId}`,
        `/api/Masters/block-list/${encodeURIComponent(distId)}`,
        mapBlock,
        [],
      );
    }

    const distId = this.loginDistrictId();
    const blockId = this.loginRuralBlockId();
    const fallback = this.loginBlockFallback();

    if (blockId) {
      return this.cachedFetch<BlockDto>(
        `blocks:body:${blockId}`,
        `/api/Masters/block-list/${encodeURIComponent(blockId)}`,
        mapBlock,
        fallback,
      ).pipe(
        switchMap((rows) => {
          if (rows.length > 0 || !distId) {
            return of(rows);
          }
          return this.cachedFetch<BlockDto>(
            `blocks:dist:${distId}`,
            `/api/Masters/block-list/${encodeURIComponent(distId)}`,
            mapBlock,
            fallback,
          );
        }),
      );
    }

    if (distId) {
      return this.cachedFetch<BlockDto>(
        `blocks:dist:${distId}`,
        `/api/Masters/block-list/${encodeURIComponent(distId)}`,
        mapBlock,
        [],
      );
    }

    return of([]);
  }

  /** Rural only — booth list for selected block. */
  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    const id = blockId?.trim();
    if (!id) {
      return of([]);
    }
    return this.cachedFetch<RuralPsDto>(
      `rps:${id}`,
      `/api/Masters/rps-list/${encodeURIComponent(id)}`,
      mapRuralPs,
      [],
    );
  }

  /**
   * Urban only — login BodyID → ub-list/{BodyID}.
   * Unchanged from working urban flow (su1).
   */
  getBodies(): Observable<LocationOption[]> {
    const bodyId = this.loginUrbanBodyId();
    if (!bodyId) {
      return of(this.loginBodyFallback());
    }
    return this.cachedFetch<UrbanBodyDto>(
      `ub:${bodyId}`,
      `/api/Masters/ub-list/${encodeURIComponent(bodyId)}`,
      mapUrbanBody,
      this.loginBodyFallback(),
    );
  }

  /** Urban only — booth list for selected body. */
  getUrbanBooths(bodyId: string): Observable<LocationOption[]> {
    const id = bodyId?.trim();
    if (!id) {
      return of([]);
    }
    return this.cachedFetch<UrbanPsDto>(
      `ups:${id}`,
      `/api/Masters/ups-list/${encodeURIComponent(id)}`,
      mapUrbanPs,
      [],
    );
  }

  private cachedFetch<T>(
    cacheKey: string,
    path: string,
    mapItem: (item: T) => LocationOption,
    fallback: LocationOption[],
  ): Observable<LocationOption[]> {
    const cached = this.cache.readList<LocationOption>(cacheKey);
    return this.fetchList<T>(path, mapItem).pipe(
      tap((rows) => {
        if (rows.length > 0) {
          this.cache.write(cacheKey, rows);
        }
      }),
      switchMap((rows) => of(rows.length > 0 ? rows : cached.length > 0 ? cached : fallback)),
      catchError(() => of(cached.length > 0 ? cached : fallback)),
    );
  }

  private loginDistrictFallback(): LocationOption[] {
    const id = this.loginDistrictId();
    if (!id) {
      return [];
    }
    const name = this.loginDistrictName();
    // Keep urban resilient: still show option if DistName not yet in URL.
    return [{ id, name: name || id }];
  }

  /** Urban body fallback — only for ub-list path. */
  private loginBodyFallback(): LocationOption[] {
    if (this.isRuralLogin()) {
      return [];
    }
    const id =
      APP_PARAMS.bodyId?.trim() ||
      this.surveyAuth.session?.bodyId?.trim() ||
      '';
    if (!id) {
      return [];
    }
    const name = this.loginBodyName();
    // Prefer real name; never leave blank so urban dropdown still works offline.
    return [{ id, name: name || 'चयनित निकाय' }];
  }

  /** Rural block fallback — never used for urban login. */
  private loginBlockFallback(): LocationOption[] {
    if (this.isUrbanLogin() || !this.isRuralLogin()) {
      return [];
    }
    const id = this.loginRuralBlockId();
    const name = this.loginBodyName();
    if (!id || !name) {
      return [];
    }
    return [{ id, name }];
  }

  private isRuralLogin(): boolean {
    const scope = this.loginUrbanRural();
    return scope === 'R' || scope === 'RURAL';
  }

  private isUrbanLogin(): boolean {
    const scope = this.loginUrbanRural();
    return scope === 'U' || scope === 'URBAN';
  }

  private loginUrbanRural(): string {
    return (
      APP_PARAMS.urbanRural?.trim().toUpperCase() ||
      this.surveyAuth.session?.urbanRural?.toUpperCase() ||
      ''
    );
  }

  private loginDistrictId(): string {
    return (
      APP_PARAMS.districtId?.trim() ||
      this.surveyAuth.session?.districtId?.trim() ||
      ''
    );
  }

  private loginDistrictName(): string {
    return (
      APP_PARAMS.distName?.trim() ||
      this.surveyAuth.session?.distName?.trim() ||
      ''
    );
  }

  /**
   * Urban BodyID for ub-list / ups-list.
   * Blocked only for rural login (their BodyID is a block id).
   */
  private loginUrbanBodyId(): string {
    if (this.isRuralLogin()) {
      return '';
    }
    return (
      APP_PARAMS.bodyId?.trim() ||
      this.surveyAuth.session?.bodyId?.trim() ||
      ''
    );
  }

  /**
   * Rural BlockID for block-list / rps-list.
   * Blocked for urban login (their BodyID is a municipal body).
   */
  private loginRuralBlockId(): string {
    if (this.isUrbanLogin()) {
      return '';
    }
    if (!this.isRuralLogin()) {
      return '';
    }
    return (
      APP_PARAMS.bodyId?.trim() ||
      this.surveyAuth.session?.bodyId?.trim() ||
      ''
    );
  }

  private loginBodyName(): string {
    return (
      APP_PARAMS.bodyName?.trim() ||
      this.surveyAuth.session?.bodyName?.trim() ||
      ''
    );
  }

  private tryListPaths<T>(
    paths: string[],
    mapItem: (item: T) => LocationOption,
    cacheKey: string,
  ): Observable<LocationOption[]> {
    if (paths.length === 0) {
      return of([]);
    }
    const cached = this.cache.readList<LocationOption>(cacheKey);
    const [head, ...tail] = paths;
    return this.fetchList<T>(head, mapItem).pipe(
      switchMap((rows) => {
        if (rows.length > 0) {
          this.cache.write(cacheKey, rows);
          return of(rows);
        }
        return tail.length > 0
          ? this.tryListPaths<T>(tail, mapItem, cacheKey)
          : of(cached);
      }),
      catchError(() =>
        tail.length > 0 ? this.tryListPaths<T>(tail, mapItem, cacheKey) : of(cached),
      ),
    );
  }

  private fetchList<T>(
    path: string,
    mapItem: (item: T) => LocationOption,
  ): Observable<LocationOption[]> {
    if (this.api.useMockData) {
      return of([]).pipe(delay(250));
    }

    return this.api.get<{ Status?: boolean; Message?: string; Data?: unknown }>(path).pipe(
      map((res) => {
        if (res && res.Status === false) {
          throw new Error(res.Message?.trim() || `Master list failed: ${path}`);
        }
        return asArray<T>(res?.Data)
          .map(mapItem)
          .filter((opt) => opt.id.length > 0);
      }),
    );
  }
}

function asArray<T>(data: unknown): T[] {
  if (Array.isArray(data)) {
    return data as T[];
  }
  if (data && typeof data === 'object') {
    return [data as T];
  }
  return [];
}

function pickId(...candidates: Array<string | undefined | null>): string {
  for (const value of candidates) {
    const trimmed = value?.toString().trim();
    if (trimmed) {
      return trimmed;
    }
  }
  return '';
}

function mapDistrict(item: DistrictDto): LocationOption {
  return {
    id: pickId(item.DistID, item.ID),
    name: item.DistName?.trim() || item.DistNameEn?.trim() || pickId(item.DistID, item.ID),
  };
}

function mapBlock(item: BlockDto): LocationOption {
  return {
    id: pickId(item.ID, item.BlockID),
    name: item.BlockName?.trim() || item.BlockNameEn?.trim() || pickId(item.ID, item.BlockID),
  };
}

function mapUrbanBody(item: UrbanBodyDto): LocationOption {
  return {
    id: pickId(item.ID, item.UrbanBodyID, item.BodyID),
    name:
      item.UrbanBodyName?.trim() ||
      item.UrbanBodyNameEn?.trim() ||
      pickId(item.ID, item.UrbanBodyID, item.BodyID),
  };
}

function mapUrbanPs(item: UrbanPsDto): LocationOption {
  return {
    id: pickId(item.ID, item.PSID),
    name: item.PSNoName?.trim() || item.PSName?.trim() || pickId(item.ID, item.PSID),
  };
}

function mapRuralPs(item: RuralPsDto): LocationOption {
  return {
    id: pickId(item.ID, item.PSID),
    name: item.PSNoName?.trim() || item.PSName?.trim() || pickId(item.ID, item.PSID),
  };
}
