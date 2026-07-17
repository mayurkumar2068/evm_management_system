import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, delay, map } from 'rxjs/operators';

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
 * Masters API — aligned with OpenAPI (`api-1.json`) cascade:
 *   GET /api/Masters/district-list-all     (full district list; no DistID)
 *   GET /api/Masters/districts/{id}        (single district lookup only)
 *   GET /api/Masters/ub-list/{districtId}  (urban bodies for selected district)
 *   GET /api/Masters/ups-list/{bodyId}     (urban PS for selected body)
 *   GET /api/Masters/block-list/{districtId}
 *   GET /api/Masters/rps-list/{blockId}
 *
 * Login DistID / bodyId must NOT drive the district list — user picks district,
 * then child dropdowns load from that selection.
 */
@Injectable({ providedIn: 'root' })
export class MastersApiService {
  private readonly api = inject(ApiClientService);

  /** Full district list — never pass login DistID. */
  getDistricts(): Observable<LocationOption[]> {
    return this.fetchByPath<DistrictDto>(
      '/api/Masters/district-list-all',
      MOCK.districts,
      mapDistrict,
    ).pipe(
      catchError(() =>
        // Soft fallbacks some backends expose for "all districts".
        this.fetchByPath<DistrictDto>(
          '/api/Masters/districts/0',
          MOCK.districts,
          mapDistrict,
        ).pipe(catchError(() => of(MOCK.districts))),
      ),
    );
  }

  getBlocks(districtId: string): Observable<LocationOption[]> {
    const id = districtId?.trim();
    if (!id) {
      return of([]);
    }
    return this.fetchByPath<BlockDto>(
      `/api/Masters/block-list/${encodeURIComponent(id)}`,
      MOCK.blocks[id] ?? MOCK.blocksFallback,
      mapBlock,
    );
  }

  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    const id = blockId?.trim();
    if (!id) {
      return of([]);
    }
    return this.fetchByPath<RuralPsDto>(
      `/api/Masters/rps-list/${encodeURIComponent(id)}`,
      MOCK.boothsFallback,
      mapRuralPs,
    );
  }

  /** Urban bodies for the *selected* district — `ub-list/{districtId}`. */
  getBodies(districtId: string): Observable<LocationOption[]> {
    const id = districtId?.trim();
    if (!id) {
      return of([]);
    }
    return this.fetchByPath<UrbanBodyDto>(
      `/api/Masters/ub-list/${encodeURIComponent(id)}`,
      MOCK.bodiesFallback,
      mapUrbanBody,
    );
  }

  /** Urban PS for the *selected* body — `ups-list/{bodyId}`. */
  getUrbanBooths(bodyId: string): Observable<LocationOption[]> {
    const id = bodyId?.trim();
    if (!id) {
      return of([]);
    }
    return this.fetchByPath<UrbanPsDto>(
      `/api/Masters/ups-list/${encodeURIComponent(id)}`,
      MOCK.boothsFallback,
      mapUrbanPs,
    );
  }

  private fetchByPath<T>(
    path: string,
    mockData: LocationOption[],
    mapItem: (item: T) => LocationOption,
  ): Observable<LocationOption[]> {
    if (this.api.useMockData) {
      return of(mockData).pipe(delay(250));
    }

    return this.api.get<{ Status?: boolean; Data?: unknown }>(path).pipe(
      map((res) => {
        if (res && res.Status === false) {
          throw new Error('Master list request failed');
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
    const trimmed = value?.trim();
    if (trimmed) {
      return trimmed;
    }
  }
  return '';
}

function mapDistrict(item: DistrictDto): LocationOption {
  return {
    id: pickId(item.ID, item.DistID),
    name: item.DistName?.trim() || item.DistNameEn?.trim() || pickId(item.ID, item.DistID),
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
    id: pickId(item.ID, item.UrbanBodyID),
    name:
      item.UrbanBodyName?.trim() ||
      item.UrbanBodyNameEn?.trim() ||
      pickId(item.ID, item.UrbanBodyID),
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

const MOCK = {
  districts: <LocationOption[]>[
    { id: 'morena', name: 'मुरैना (Morena)' },
    { id: 'bhopal', name: 'भोपाल (Bhopal)' },
  ],
  blocksFallback: <LocationOption[]>[{ id: 'block-1', name: 'जनपद 1' }],
  blocks: <Record<string, LocationOption[]>>{
    morena: [{ id: 'joura', name: 'जौरा (Joura)' }],
  },
  bodiesFallback: <LocationOption[]>[{ id: 'body-1', name: 'निकाय 1' }],
  boothsFallback: <LocationOption[]>[
    { id: 'booth-1', name: 'मतदान केंद्र 1' },
    { id: 'booth-2', name: 'मतदान केंद्र 2' },
  ],
};
