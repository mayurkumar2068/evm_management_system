import { Injectable, inject, signal } from '@angular/core';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';

import { LocationOption, SelectedLocation } from '../models/location.model';
import {
  SaveSurveyAnswerRequest,
  SaveSurveyAnswerResponse,
  SurveyQuestion,
} from '../models/survey.model';
import { MastersApiService } from './masters-api.service';
import { SurveyApiService } from './survey-api.service';

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

  readonly selectedLocation = signal<SelectedLocation | null>(null);
  readonly surveyQuestions = signal<SurveyQuestion[]>([]);
  readonly savedAnswerIds = signal<Record<string, string>>({});

  private questionsLoaded = false;

  setLocation(location: SelectedLocation): void {
    this.selectedLocation.set(location);
  }

  clearSurveySession(): void {
    this.surveyQuestions.set([]);
    this.questionsLoaded = false;
    this.savedAnswerIds.set({});
  }

  getDistricts(): Observable<LocationOption[]> {
    return this.masters.getDistricts();
  }

  getBlocks(districtId: string): Observable<LocationOption[]> {
    return this.masters.getBlocks(districtId);
  }

  getRuralBooths(blockId: string): Observable<LocationOption[]> {
    return this.masters.getRuralBooths(blockId);
  }

  getBodies(districtId: string): Observable<LocationOption[]> {
    return this.masters.getBodies(districtId);
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
