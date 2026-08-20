import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  NgZone,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { switchMap } from 'rxjs/operators';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar } from '@angular/material/snack-bar';

import { ChecklistItemComponent } from '../../components/checklist-item/checklist-item.component';
import { BoothMapCardComponent } from '../../components/booth-map-card/booth-map-card.component';
import { CoordinatesCardComponent } from '../../components/coordinates-card/coordinates-card.component';
import { LocationCardComponent } from '../../components/location-card/location-card.component';
import { Coordinates, SelectedLocation } from '../../models/location.model';
import {
  SaveSurveyAnswerRequest,
  SurveyQuestion,
  SurveyQuestionDraft,
} from '../../models/survey.model';
import { GeolocationError, GeolocationService } from '../../services/geolocation.service';
import { SurveyAuthService } from '../../services/survey-auth.service';
import { SurveyService } from '../../services/survey.service';
import { APP_PARAMS } from '../../core/app-params';
import { I18nService } from '../../i18n/i18n.service';
import { TranslatePipe } from '../../i18n/translate.pipe';
import {
  readSessionJson,
  writeSessionJson,
  clearSessionKey,
} from '../../core/session-storage.util';
import { shrinkDataUrlImage } from '../../utils/shrink-data-url-image';

const CURRENT_INDEX_KEY = 'survey.current_index';

@Component({
  selector: 'app-survey-checklist',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    LocationCardComponent,
    ChecklistItemComponent,
    BoothMapCardComponent,
    CoordinatesCardComponent,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './survey-checklist.component.html',
  styleUrl: './survey-checklist.component.scss',
})
export class SurveyChecklistComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly survey = inject(SurveyService);
  private readonly geo = inject(GeolocationService);
  private readonly surveyAuth = inject(SurveyAuthService);
  private readonly router = inject(Router);
  private readonly snack = inject(MatSnackBar);
  private readonly destroyRef = inject(DestroyRef);
  private readonly i18n = inject(I18nService);
  private readonly zone = inject(NgZone);

  readonly location: SelectedLocation | null = this.survey.selectedLocation();

  readonly questions = signal<SurveyQuestion[]>([]);
  readonly currentIndex = signal(0);
  readonly loadingQuestions = signal(true);
  readonly saving = signal(false);
  readonly saveError = signal<string | null>(null);

  /** Explicit UI state — avoids OnPush misses when form is patched async. */
  readonly uiAnswerValue = signal<string | null>(null);
  readonly uiImage = signal<string | null>(null);

  readonly questionForm: FormGroup = this.fb.group({
    surveyId: [''],
    answerValue: [null as string | null],
    image: [null as string | null],
    remark: [''],
    savedAnswerId: [null as string | null],
  });

  readonly currentQuestion = computed(() => {
    const list = this.questions();
    const index = this.currentIndex();
    return list[index] ?? null;
  });

  readonly totalQuestions = computed(() => this.questions().length);

  readonly isLastQuestion = computed(() => {
    const total = this.totalQuestions();
    return total > 0 && this.currentIndex() >= total - 1;
  });

  readonly hasSavedAnswer = computed(() => {
    const q = this.currentQuestion();
    if (!q) return false;
    return !!this.survey.savedAnswerIds()[q.id];
  });

  readonly progressLabel = computed(() => {
    const total = this.totalQuestions();
    if (total === 0) {
      return '';
    }
    return this.i18n.t('chk.progress', {
      current: this.currentIndex() + 1,
      total,
    });
  });

  readonly coordinates = signal<Coordinates | null>(null);
  readonly geoLoading = signal(false);
  readonly geoError = signal<string | null>(null);
  readonly preview = signal<string | null>(null);
  readonly authError = signal<string | null>(null);
  /** Bumped after form reset/prefill so OnPush checklist re-reads values. */
  readonly formEpoch = signal(0);

  private readonly drafts = new Map<number, SurveyQuestionDraft>();
  /** Guards against stale `existing_answer` responses when changing questions quickly. */
  private existingAnswerBindToken = 0;

  ngOnInit(): void {
    if (!this.location) {
      void this.router.navigate(['/location']);
      return;
    }
    this.ensureAuthAndLoadQuestions();
    this.fetchLocation();
  }

  private ensureAuthAndLoadQuestions(): void {
    this.loadingQuestions.set(true);
    this.surveyAuth
      .ensureAuthenticated()
      .pipe(
        switchMap(() => this.survey.getSurveyQuestions()),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe({
        next: (items) => {
          this.authError.set(null);
          this.questions.set(items);
          this.loadingQuestions.set(false);
          if (items.length > 0) {
            const restored = readSessionJson<number>(CURRENT_INDEX_KEY) ?? 0;
            const startIdx = restored >= 0 && restored < items.length ? restored : 0;
            this.currentIndex.set(startIdx);
            this.bindQuestionToForm(startIdx);
          } else {
            this.snack.open(this.i18n.t('chk.toast.loadFail'), 'OK', {
              duration: 3000,
            });
          }
        },
        error: () => {
          this.loadingQuestions.set(false);
          this.authError.set(this.i18n.t('chk.toast.authFail'));
          this.snack.open(this.i18n.t('chk.toast.loadFail'), 'OK', {
            duration: 3000,
          });
        },
      });
  }

  readonly progressPercent = computed(() => {
    const total = this.totalQuestions();
    if (total <= 0) {
      return 0;
    }
    return Math.round(((this.currentIndex() + 1) / total) * 100);
  });

  /** Booth location from login API (`Lat` / `Long`). */
  readonly boothCoordinates = computed((): Coordinates | null => {
    const session = this.surveyAuth.session;
    const lat = APP_PARAMS.boothLat ?? session?.lat ?? null;
    const lng = APP_PARAMS.boothLong ?? session?.long ?? null;
    if (lat == null || lng == null || !Number.isFinite(lat) || !Number.isFinite(lng)) {
      return null;
    }
    if (lat === 0 && lng === 0) {
      return null;
    }
    return { latitude: lat, longitude: lng };
  });

  readonly boothLabel = computed(() => {
    const rows = this.location?.rows ?? [];
    return (
      rows.find((r) => r.key === 'boothId')?.value ??
      rows.find((r) => r.icon === 'how_to_vote')?.value ??
      ''
    );
  });

  fetchLocation(): void {
    this.geoLoading.set(true);
    this.geoError.set(null);
    this.geo
      .getCurrentPosition()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (coords) => {
          this.coordinates.set(coords);
          this.geoLoading.set(false);
        },
        error: (err: GeolocationError) => {
          const session = this.surveyAuth.session;
          if (session?.lat != null && session?.long != null) {
            this.coordinates.set({
              latitude: session.lat,
              longitude: session.long,
            });
            this.geoError.set(null);
          } else {
            this.geoError.set(this.i18n.t(`geo.${err.kind}`));
          }
          this.geoLoading.set(false);
        },
      });
  }

  private bindQuestionToForm(index: number): void {
    const question = this.questions()[index];
    if (!question) {
      return;
    }

    const cached = this.drafts.get(index);
    const savedId = cached?.savedAnswerId ?? this.survey.savedAnswerIds()[question.id] ?? null;
    const answerValue = this.normalizeAnswerValue(cached?.answerValue);
    const image = cached?.image ?? null;
    const remark = cached?.remark ?? '';

    this.questionForm.reset({
      surveyId: question.id,
      answerValue,
      image,
      remark,
      savedAnswerId: savedId,
    });
    this.syncUiFromForm(answerValue, image);
    this.saveError.set(null);

    // Local draft already present — skip server fetch.
    if (cached) {
      return;
    }

    const boothId = this.location?.values['boothId']?.trim() ?? '';
    if (!boothId) {
      return;
    }

    const bindToken = ++this.existingAnswerBindToken;
    this.survey
      .getExistingAnswer(boothId, question.id)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (existing) => {
        void this.applyExistingAnswer(bindToken, index, question, existing);
        },
      });
  }

  private async applyExistingAnswer(
    bindToken: number,
    index: number,
    question: SurveyQuestion,
    existing: {
      id: string;
      answerYN: boolean | null;
      answerText: string | null;
      remark: string;
      photo: string | null;
    } | null,
  ): Promise<void> {
    if (
      bindToken !== this.existingAnswerBindToken ||
      this.currentIndex() !== index ||
      !existing
    ) {
      return;
    }
    if (this.drafts.has(index)) {
      return;
    }

    let photo = existing.photo;
    if (photo) {
      try {
        photo = await shrinkDataUrlImage(photo);
      } catch {
        // keep original
      }
    }

    // Flutter native bridge callbacks can land outside Angular zone.
    this.zone.run(() => {
      if (
        bindToken !== this.existingAnswerBindToken ||
        this.currentIndex() !== index
      ) {
        return;
      }
      if (this.drafts.has(index)) {
        return;
      }

      const answerId = existing.id.trim() || null;
      const answerValue = this.resolveExistingAnswerValue(question, existing);
      this.questionForm.patchValue({
        answerValue,
        remark: existing.remark ?? '',
        image: photo,
        savedAnswerId: answerId,
      });
      this.syncUiFromForm(answerValue, photo);
      if (answerId) {
        this.survey.rememberSavedAnswer(question.id, answerId);
      }
      this.persistDraftForIndex(index);
    });
  }

  private syncUiFromForm(
    answerValue: string | null,
    image: string | null,
  ): void {
    this.uiAnswerValue.set(answerValue);
    this.uiImage.set(image);
    this.formEpoch.update((n) => n + 1);
  }

  onAnswerChange(answerValue: string | null): void {
    this.uiAnswerValue.set(this.normalizeAnswerValue(answerValue));
    this.persistDraftForIndex(this.currentIndex());
  }

  onImageChange(image: string | null): void {
    this.uiImage.set(image);
    this.persistDraftForIndex(this.currentIndex());
  }

  private persistDraftForIndex(index: number): void {
    const raw = this.questionForm.getRawValue();
    this.drafts.set(index, {
      answerValue: this.normalizeAnswerValue(raw.answerValue as string | null),
      remark: (raw.remark as string) ?? '',
      image: (raw.image as string | null) ?? null,
      savedAnswerId: (raw.savedAnswerId as string | null) ?? null,
    });
  }

  goPrevious(): void {
    const index = this.currentIndex();
    if (index <= 0 || this.saving()) {
      return;
    }
    this.persistDraftForIndex(index);
    this.goToIndex(index - 1);
  }

  /** Navigate to next question without saving — for review/recheck only. */
  goNextWithoutSave(): void {
    const index = this.currentIndex();
    if (this.isLastQuestion() || this.saving()) {
      return;
    }
    this.persistDraftForIndex(index);
    this.goToIndex(index + 1);
  }

  private goToIndex(index: number): void {
    this.currentIndex.set(index);
    writeSessionJson(CURRENT_INDEX_KEY, index);
    this.bindQuestionToForm(index);
  }

  async saveAndContinue(): Promise<void> {
    if (this.saving() || this.loadingQuestions()) {
      return;
    }

    const question = this.currentQuestion();
    const location = this.location;
    if (!question || !location) {
      return;
    }

    this.saveError.set(null);
    const raw = this.questionForm.getRawValue();
    const answerValue = ((raw.answerValue as string | null) ?? '').trim();
    const remark = ((raw.remark as string) ?? '').trim();
    const image = (raw.image as string | null) ?? null;
    const normalizedAnswer = this.normalizeAnswerForSave(question, answerValue);

    if (question.mandatory && !answerValue) {
      const key = question.qType === 'YN'
        ? 'chk.validation.answerRequired'
        : 'chk.validation.answerRequired.generic';
      this.saveError.set(this.i18n.t(key));
      return;
    }

    if (this.isPhotoRequired(question, normalizedAnswer.answerYN) && !image) {
      const key = question.qType === 'YN'
        ? 'chk.validation.photoRequired'
        : 'chk.validation.photoRequired.generic';
      this.saveError.set(this.i18n.t(key));
      return;
    }

    const boothId = location.values['boothId'];
    if (!boothId) {
      this.saveError.set(this.i18n.t('chk.validation.locationMissing'));
      return;
    }

    const coords = this.coordinates();
    const payload: SaveSurveyAnswerRequest = {
      id: (raw.savedAnswerId as string | null) ?? null,
      questionId: question.id,
      answerYN: normalizedAnswer.answerYN,
      answerText: normalizedAnswer.answerText,
      remark,
      psType: location.areaType === 'rural' ? 'R' : 'U',
      psId: boothId,
      lat: coords?.latitude ?? null,
      long: coords?.longitude ?? null,
      userId: this.surveyAuth.userId,
      photo: this.stripDataUrl(image),
    };

    this.saving.set(true);
    this.survey
      .saveSurveyAnswer(payload)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (res) => {
          this.saving.set(false);
          if (!res?.Success || !res.Id) {
            this.saveError.set(this.i18n.t('chk.toast.saveFail'));
            return;
          }

          const answerId = res.Id;
          this.questionForm.patchValue({ savedAnswerId: answerId });
          this.survey.rememberSavedAnswer(question.id, answerId);
          this.persistDraftForIndex(this.currentIndex());

          if (this.isLastQuestion()) {
            this.completeSurvey();
            return;
          }

          this.goToIndex(this.currentIndex() + 1);
        },
        error: () => {
          this.saving.set(false);
          this.saveError.set(this.i18n.t('chk.toast.saveFail'));
          this.snack.open(this.i18n.t('chk.toast.saveFail'), 'OK', {
            duration: 3500,
          });
        },
      });
  }

  private resolveExistingAnswerValue(
    question: SurveyQuestion,
    existing: {
      answerYN: boolean | null;
      answerText: string | null;
    },
  ): string | null {
    if (question.qType === 'YN' && existing.answerYN !== null) {
      return existing.answerYN ? 'Y' : 'N';
    }
    const rawText = (existing.answerText ?? '').trim();
    if (!rawText) {
      return null;
    }

    if (question.options.length > 0) {
      const matched = question.options.find((option) =>
        this.sameText(option.value, rawText) || this.sameText(option.text, rawText),
      );
      return matched?.value ?? rawText;
    }

    return rawText;
  }

  private normalizeAnswerForSave(
    question: SurveyQuestion,
    answerValue: string,
  ): { answerYN: boolean | null; answerText: string } {
    const selected = question.options.find((option) => this.sameText(option.value, answerValue));
    const fallback = question.options.find((option) => this.sameText(option.text, answerValue));
    const option = selected ?? fallback ?? null;

    if (question.qType === 'YN') {
      const yesOption =
        question.options.find((option) => this.sameText(option.value, 'Y')) ??
        question.options.find((option) => this.sameText(option.text, 'yes')) ??
        question.options.find((option) => this.sameText(option.text, 'हाँ')) ??
        question.options.find((option) => this.sameText(option.text, 'हां')) ??
        question.options[0] ??
        null;
      const yesValue = yesOption?.value ?? 'Y';
      const isYes =
        this.sameText(answerValue, yesValue) ||
        this.sameText(answerValue, yesOption?.text ?? '') ||
        this.sameText(answerValue, 'yes') ||
        this.sameText(answerValue, 'हाँ') ||
        this.sameText(answerValue, 'हां') ||
        this.sameText(answerValue, 'y');
      return {
        answerYN: isYes,
        answerText: option?.text ?? answerValue,
      };
    }

    return {
      answerYN: null,
      answerText: option?.text ?? answerValue,
    };
  }

  private isPhotoRequired(question: SurveyQuestion, answerYN: boolean | null): boolean {
    if (!question.photoRequired) return false;
    // For Yes/No questions, selecting "No" should not force photo upload.
    if (question.qType === 'YN' && answerYN === false) return false;
    return true;
  }

  private normalizeAnswerValue(value: string | null | undefined): string | null {
    const raw = (value ?? '').trim();
    return raw.length > 0 ? raw : null;
  }

  private sameText(left: string, right: string): boolean {
    return left.trim().toLowerCase() === right.trim().toLowerCase();
  }

  private completeSurvey(): void {
    this.survey.clearSurveySession();
    clearSessionKey(CURRENT_INDEX_KEY);
    this.snack.open(this.i18n.t('chk.toast.submitOk'), 'OK', { duration: 3500 });
    void this.router.navigate(['/location']);
  }

  openPreview(image: string): void {
    this.preview.set(image);
  }

  closePreview(): void {
    this.preview.set(null);
  }

  private stripDataUrl(dataUrl: string | null): string | null {
    if (!dataUrl) {
      return null;
    }
    const comma = dataUrl.indexOf(',');
    return comma >= 0 ? dataUrl.slice(comma + 1) : dataUrl;
  }
}
