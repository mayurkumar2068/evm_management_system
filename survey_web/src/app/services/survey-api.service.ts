import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, delay, map, tap } from 'rxjs/operators';

import { ApiClientService } from '../core/api-client.service';
import { SurveyOfflineCacheService } from '../core/survey-offline-cache.service';
import {
  SaveSurveyAnswerRequest,
  SaveSurveyAnswerResponse,
  SurveyQuestion,
  SurveyQuestionDto,
} from '../models/survey.model';

const QUESTIONS_KEY = 'survey_questions';

/**
 * PSSurvey API (`/api/PSSurvey/*`) — questions load + per-answer save.
 */
@Injectable({ providedIn: 'root' })
export class SurveyApiService {
  private readonly api = inject(ApiClientService);
  private readonly cache = inject(SurveyOfflineCacheService);

  getQuestions(): Observable<SurveyQuestion[]> {
    if (this.api.useMockData) {
      return of(MOCK_QUESTIONS).pipe(delay(300));
    }

    const cached = this.cache.readList<SurveyQuestion>(QUESTIONS_KEY);
    return this.api.get<unknown>('/api/PSSurvey/survey_questions').pipe(
      map((res) => normalizeQuestions(res)),
      tap((items) => {
        if (items.length > 0) {
          this.cache.write(QUESTIONS_KEY, items);
        }
      }),
      catchError(() =>
        cached.length > 0 ? of(cached) : of([] as SurveyQuestion[]),
      ),
    );
  }

  saveAnswer(payload: SaveSurveyAnswerRequest): Observable<SaveSurveyAnswerResponse> {
    if (this.api.useMockData) {
      const id = payload.id ?? `mock-${Date.now()}`;
      return of<SaveSurveyAnswerResponse>({ Success: true, Id: id }).pipe(delay(500));
    }

    return this.api
      .post<unknown>('/api/PSSurvey/save_survey_answer', payload)
      .pipe(
        map((res) => normalizeSaveResponse(res)),
        tap((res) => {
          if (!res.Success) {
            this.cache.queuePendingSave(payload);
          }
        }),
        catchError((err) => {
          this.cache.queuePendingSave(payload);
          throw err;
        }),
      );
  }
}

/** mpsec may return raw array or `{ Status, Data }` envelope. */
function normalizeQuestions(res: unknown): SurveyQuestion[] {
  const rows = extractQuestionRows(res);
  return [...rows]
    .sort((a, b) => a.SORT_ORDER - b.SORT_ORDER)
    .map(mapQuestionDto);
}

function extractQuestionRows(res: unknown): SurveyQuestionDto[] {
  if (Array.isArray(res)) {
    return res as SurveyQuestionDto[];
  }
  if (res && typeof res === 'object') {
    const envelope = res as { Status?: boolean; Data?: unknown; data?: unknown };
    if (envelope.Status === false) {
      throw new Error('Survey questions request failed');
    }
    const data = envelope.Data ?? envelope.data;
    if (Array.isArray(data)) {
      return data as SurveyQuestionDto[];
    }
  }
  return [];
}

function mapQuestionDto(dto: SurveyQuestionDto): SurveyQuestion {
  return {
    id: dto.Id,
    surveyId: dto.SurveyId,
    titleHi: dto.Q_Hi,
    titleEn: dto.Q_En,
    descHi: dto.Desc_Hi,
    descEn: dto.Desc_En,
    photoRequired: Boolean(dto.IS_PHOTO_REQUIRED),
    sortOrder: dto.SORT_ORDER,
    mandatory: Boolean(dto.IS_MANDATORY),
  };
}

/**
 * mpsec returns `{ Status, Message, Data: "<guid>" }`.
 * Older shapes may use `{ Success, Id }` — accept both.
 */
function normalizeSaveResponse(res: unknown): SaveSurveyAnswerResponse {
  if (!res || typeof res !== 'object') {
    return { Success: false, Id: '' };
  }
  const row = res as {
    Status?: boolean;
    Message?: string;
    Data?: unknown;
    Success?: boolean;
    Id?: string;
    id?: string;
  };

  if (typeof row.Success === 'boolean') {
    const id = row.Id ?? row.id ?? '';
    return { Success: row.Success, Id: String(id || '') };
  }

  if (row.Status === true) {
    const data = row.Data;
    let id = '';
    if (typeof data === 'string' || typeof data === 'number') {
      id = String(data);
    } else if (data && typeof data === 'object') {
      const nested = data as { Id?: string; id?: string };
      id = nested.Id ?? nested.id ?? '';
    }
    return { Success: id.length > 0, Id: id };
  }

  return { Success: false, Id: '' };
}

const MOCK_QUESTIONS: SurveyQuestion[] = [
  {
    id: '62bb3c65-7755-456e-9eb1-ec1805b17718',
    surveyId: null,
    titleHi: 'पर्याप्त फर्नीचर है?',
    titleEn: 'Adequate furniture?',
    descHi: null,
    descEn: null,
    photoRequired: true,
    sortOrder: 1,
    mandatory: true,
  },
  {
    id: 'a5e64636-9bc3-4e5d-b9a1-76bd7fd63940',
    surveyId: null,
    titleHi: 'समुचित रोशनी की व्यवस्था है?',
    titleEn: 'Proper lighting?',
    descHi: null,
    descEn: null,
    photoRequired: true,
    sortOrder: 2,
    mandatory: true,
  },
];
