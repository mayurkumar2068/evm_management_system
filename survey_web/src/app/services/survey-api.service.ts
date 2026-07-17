import { Injectable, inject } from '@angular/core';
import { Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';

import { ApiClientService } from '../core/api-client.service';
import {
  SaveSurveyAnswerRequest,
  SaveSurveyAnswerResponse,
  SurveyQuestion,
  SurveyQuestionDto,
} from '../models/survey.model';

/**
 * PSSurvey API (`/api/PSSurvey/*`) — questions load + per-answer save.
 */
@Injectable({ providedIn: 'root' })
export class SurveyApiService {
  private readonly api = inject(ApiClientService);

  getQuestions(): Observable<SurveyQuestion[]> {
    if (this.api.useMockData) {
      return of(MOCK_QUESTIONS).pipe(delay(300));
    }

    return this.api
      .get<SurveyQuestionDto[]>('/api/PSSurvey/survey_questions')
      .pipe(map((rows) => [...rows].sort((a, b) => a.SORT_ORDER - b.SORT_ORDER).map(mapQuestionDto)));
  }

  saveAnswer(payload: SaveSurveyAnswerRequest): Observable<SaveSurveyAnswerResponse> {
    if (this.api.useMockData) {
      const id = payload.id ?? `mock-${Date.now()}`;
      return of<SaveSurveyAnswerResponse>({ Success: true, Id: id }).pipe(delay(500));
    }

    return this.api.post<SaveSurveyAnswerResponse>(
      '/api/PSSurvey/save_survey_answer',
      payload,
    );
  }
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
