import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, delay, map, switchMap } from 'rxjs/operators';

import { ApiClientService } from '../core/api-client.service';
import { LocationOption } from '../models/location.model';

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
 * Masters cascade — refs:
 * - `20260710 PSSurveyAPI.txt`: district-list-all + `ub-list?id={districtId}`
 * - `20260713 PSSurveyAPI.txt` / `api-1.json`: `ub-list/{id}`, `ups-list/{id}`, …
 *
 * Urban: district-list-all → ub-list(districtId) → ups-list(bodyId)
 * Rural: district-list-all → block-list(districtId) → rps-list(blockId)
 */
@Injectable({ providedIn: 'root' })
export class MastersApiService {
  private readonly api = inject(ApiClientService);

  /** Full district list — never filter by login DistID. */
  getDistricts(): Observable<LocationOption[]> {
    return this.fetchList<DistrictDto>(
      '/api/Masters/district-list-all',
      mapDistrict,
    );
  }

  getBlocks(districtId: string): Observable<LocationOption[]> {
    return this.fetchByParentId<BlockDto>(
      'block-list',
      districtId,
      mapBlock,
    );
  }

  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    return this.fetchByParentId<RuralPsDto>(
      'rps-list',
      blockId,
      mapRuralPs,
    );
  }

  /** Urban bodies for selected district (not login BodyID). */
  getBodies(districtId: string): Observable<LocationOption[]> {
    return this.fetchByParentId<UrbanBodyDto>(
      'ub-list',
      districtId,
      mapUrbanBody,
    );
  }

  /** Urban PS for selected body. */
  getUrbanBooths(bodyId: string): Observable<LocationOption[]> {
    return this.fetchByParentId<UrbanPsDto>(
      'ups-list',
      bodyId,
      mapUrbanPs,
    );
  }

  /**
   * Tries OpenAPI path style first, then legacy query style from older docs.
   *   /api/Masters/{resource}/{id}
   *   /api/Masters/{resource}?id={id}
   */
  private fetchByParentId<T>(
    resource: string,
    parentId: string,
    mapItem: (item: T) => LocationOption,
  ): Observable<LocationOption[]> {
    const id = parentId?.trim();
    if (!id) {
      return of([]);
    }

    const pathStyle = `/api/Masters/${resource}/${encodeURIComponent(id)}`;
    const queryStyle = `/api/Masters/${resource}?id=${encodeURIComponent(id)}`;

    return this.fetchList<T>(pathStyle, mapItem).pipe(
      switchMap((rows) =>
        rows.length > 0 ? of(rows) : this.fetchList<T>(queryStyle, mapItem),
      ),
      catchError(() => this.fetchList<T>(queryStyle, mapItem)),
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
  // API samples use `ID` as DistID GUID (same value login returns as DistID).
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
