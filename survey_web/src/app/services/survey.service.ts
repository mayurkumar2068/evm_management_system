import { Injectable, inject, signal } from '@angular/core';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

import {
  clearSessionKey,
  readSessionJson,
  writeSessionJson,
} from '../core/session-storage.util';
import { LocationOption, SelectedLocation } from '../models/location.model';
import {
  SaveSurveyAnswerRequest,
  SaveSurveyAnswerResponse,
  SurveyQuestion,
} from '../models/survey.model';
import { MastersApiService } from './masters-api.service';
import { SurveyApiService } from './survey-api.service';

const SELECTED_LOCATION_KEY = 'survey.selected_location';

/**
 * Session state + facade over Masters / PSSurvey APIs.
 *
 * Components talk to this service; HTTP details live in {@link MastersApiService}
 * and {@link SurveyApiService}.
 */
@Injectable({ providedIn: 'root' })
export class SurveyService {
  private readonly masters = inject(MastersApiService);
  private readonly surveyApi = inject(SurveyApiService);

  readonly selectedLocation = signal<SelectedLocation | null>(
    readSessionJson<SelectedLocation>(SELECTED_LOCATION_KEY),
  );
  readonly surveyQuestions = signal<SurveyQuestion[]>([]);
  readonly savedAnswerIds = signal<Record<string, string>>({});

  private questionsLoaded = false;

  setLocation(location: SelectedLocation): void {
    this.selectedLocation.set(location);
    writeSessionJson(SELECTED_LOCATION_KEY, location);
  }

  clearSurveySession(): void {
    this.surveyQuestions.set([]);
    this.questionsLoaded = false;
    this.savedAnswerIds.set({});
    this.selectedLocation.set(null);
    clearSessionKey(SELECTED_LOCATION_KEY);
  }

  getDistricts(): Observable<LocationOption[]> {
    return this.masters.getDistricts();
  }

  getBlocks(): Observable<LocationOption[]> {
    return this.masters.getBlocks();
  }

  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    return this.masters.getRuralBooths(blockId);
  }

  getBodies(): Observable<LocationOption[]> {
    return this.masters.getBodies();
  }

  getUrbanBooths(bodyId: string): Observable<LocationOption[]> {
    return this.masters.getUrbanBooths(bodyId);
  }

  getSurveyQuestions(): Observable<SurveyQuestion[]> {
    if (this.questionsLoaded && this.surveyQuestions().length > 0) {
      return of(this.surveyQuestions());
    }

    return this.surveyApi.getQuestions().pipe(
      tap((items) => {
        this.surveyQuestions.set(items);
        this.questionsLoaded = true;
      }),
    );
  }

  saveSurveyAnswer(
    payload: SaveSurveyAnswerRequest,
  ): Observable<SaveSurveyAnswerResponse> {
    return this.surveyApi.saveAnswer(payload);
  }

  rememberSavedAnswer(questionId: string, answerId: string): void {
    this.savedAnswerIds.update((current) => ({
      ...current,
      [questionId]: answerId,
    }));
  }
}
