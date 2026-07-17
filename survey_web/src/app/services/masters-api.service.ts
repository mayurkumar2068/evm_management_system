import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, delay, map } from 'rxjs/operators';

import { ApiClientService } from '../core/api-client.service';
import { APP_PARAMS } from '../core/app-params';
import { LocationOption } from '../models/location.model';

interface DistrictDto {
  ID: string;
  DistName?: string;
  DistNameEn?: string;
}

interface BlockDto {
  ID: string;
  BlockName?: string;
  BlockNameEn?: string;
}

interface UrbanBodyDto {
  ID: string;
  UrbanBodyName?: string;
  UrbanBodyNameEn?: string;
}

interface UrbanPsDto {
  ID: string;
  PSName?: string;
  PSNoName?: string;
}

interface RuralPsDto {
  ID: string;
  PSName?: string;
  PSNoName?: string;
}

/**
 * Masters API — path params per OpenAPI (`api-1.json`):
 *   GET /api/Masters/districts/{id}
 *   GET /api/Masters/ub-list/{id}
 *   GET /api/Masters/ups-list/{id}
 *   GET /api/Masters/block-list/{id}
 *   GET /api/Masters/rps-list/{id}
 */
@Injectable({ providedIn: 'root' })
export class MastersApiService {
  private readonly api = inject(ApiClientService);

  getDistricts(): Observable<LocationOption[]> {
    const districtId = APP_PARAMS.districtId?.trim();
    if (districtId) {
      return this.fetchByPath<DistrictDto>(
        `/api/Masters/districts/${encodeURIComponent(districtId)}`,
        MOCK.districts,
        mapDistrict,
      );
    }

    // Not in OpenAPI — kept only as soft fallback when DistID is missing.
    return this.fetchByPath<DistrictDto>(
      '/api/Masters/district-list-all',
      MOCK.districts,
      mapDistrict,
    ).pipe(catchError(() => of([])));
  }

  getBlocks(districtId: string): Observable<LocationOption[]> {
    return this.fetchByPath<BlockDto>(
      `/api/Masters/block-list/${encodeURIComponent(districtId)}`,
      MOCK.blocks[districtId] ?? MOCK.blocksFallback,
      mapBlock,
    );
  }

  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    return this.fetchByPath<RuralPsDto>(
      `/api/Masters/rps-list/${encodeURIComponent(blockId)}`,
      MOCK.boothsFallback,
      mapRuralPs,
    );
  }

  /** Urban bodies for a district — `GET /api/Masters/ub-list/{districtId}`. */
  getBodies(districtId: string): Observable<LocationOption[]> {
    return this.fetchByPath<UrbanBodyDto>(
      `/api/Masters/ub-list/${encodeURIComponent(districtId)}`,
      MOCK.bodiesFallback,
      mapUrbanBody,
    );
  }

  /** Urban PS for a body — `GET /api/Masters/ups-list/{bodyId}`. */
  getUrbanBooths(bodyId: string): Observable<LocationOption[]> {
    return this.fetchByPath<UrbanPsDto>(
      `/api/Masters/ups-list/${encodeURIComponent(bodyId)}`,
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

    return this.api.get<{ Status?: boolean; Data?: T[] }>(path).pipe(
      map((res) => {
        if (res && res.Status === false) {
          throw new Error('Master list request failed');
        }
        return (res?.Data ?? []).map(mapItem);
      }),
    );
  }
}

function mapDistrict(item: DistrictDto): LocationOption {
  return {
    id: item.ID,
    name: item.DistName?.trim() || item.DistNameEn?.trim() || item.ID,
  };
}

function mapBlock(item: BlockDto): LocationOption {
  return {
    id: item.ID,
    name: item.BlockName?.trim() || item.BlockNameEn?.trim() || item.ID,
  };
}

function mapUrbanBody(item: UrbanBodyDto): LocationOption {
  return {
    id: item.ID,
    name: item.UrbanBodyName?.trim() || item.UrbanBodyNameEn?.trim() || item.ID,
  };
}

function mapUrbanPs(item: UrbanPsDto): LocationOption {
  return {
    id: item.ID,
    name: item.PSNoName?.trim() || item.PSName?.trim() || item.ID,
  };
}

function mapRuralPs(item: RuralPsDto): LocationOption {
  return {
    id: item.ID,
    name: item.PSNoName?.trim() || item.PSName?.trim() || item.ID,
  };
}

const MOCK = {
  districts: <LocationOption[]>[
    { id: 'morena', name: 'मुरैना (Morena)' },
    { id: 'bhopal', name: 'भोपाल (Bhopal)' },
  ],
  blocksFallback: <LocationOption[]>[
    { id: 'block-1', name: 'जनपद 1' },
  ],
  blocks: <Record<string, LocationOption[]>>{
    morena: [{ id: 'joura', name: 'जौरा (Joura)' }],
  },
  bodiesFallback: <LocationOption[]>[
    { id: 'body-1', name: 'निकाय 1' },
  ],
  boothsFallback: <LocationOption[]>[
    { id: 'booth-1', name: 'मतदान केंद्र 1' },
    { id: 'booth-2', name: 'मतदान केंद्र 2' },
  ],
};
