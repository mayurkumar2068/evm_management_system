import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { switchMap } from 'rxjs/operators';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
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

  readonly location: SelectedLocation | null = this.survey.selectedLocation();

  readonly questions = signal<SurveyQuestion[]>([]);
  readonly currentIndex = signal(0);
  readonly loadingQuestions = signal(true);
  readonly saving = signal(false);
  readonly saveError = signal<string | null>(null);

  readonly questionForm: FormGroup = this.fb.group({
    surveyId: [''],
    title: [''],
    photoRequired: [false],
    checked: [null as boolean | null, Validators.required],
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

  private readonly drafts = new Map<number, SurveyQuestionDraft>();

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
            this.bindQuestionToForm(0);
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

  questionTitle(question: SurveyQuestion): string {
    return question.titleHi?.trim() || question.titleEn?.trim() || '';
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
    return rows.find((r) => r.icon === 'how_to_vote')?.value ?? '';
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
    const savedId =
      cached?.savedAnswerId ?? this.survey.savedAnswerIds()[question.id] ?? null;

    this.questionForm.reset({
      surveyId: question.id,
      title: this.questionTitle(question),
      photoRequired: question.photoRequired,
      checked: cached?.answerYN ?? null,
      image: cached?.image ?? null,
      remark: cached?.remark ?? '',
      savedAnswerId: savedId,
    });
    this.saveError.set(null);
  }

  private persistDraftForIndex(index: number): void {
    const raw = this.questionForm.getRawValue();
    this.drafts.set(index, {
      answerYN: raw.checked as boolean | null,
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
    const nextIndex = index - 1;
    this.currentIndex.set(nextIndex);
    this.bindQuestionToForm(nextIndex);
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
    const answerYN = raw.checked as boolean | null;
    const remark = ((raw.remark as string) ?? '').trim();
    const image = (raw.image as string | null) ?? null;

    if (answerYN === null || answerYN === undefined) {
      this.saveError.set(this.i18n.t('chk.validation.answerRequired'));
      return;
    }

    if (question.photoRequired && !image) {
      this.saveError.set(this.i18n.t('chk.validation.photoRequired'));
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
      answerYN,
      answerText: answerYN ? 'Yes' : 'No',
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
          if (!res?.Success) {
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

          const nextIndex = this.currentIndex() + 1;
          this.currentIndex.set(nextIndex);
          this.bindQuestionToForm(nextIndex);
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

  private completeSurvey(): void {
    this.survey.clearSurveySession();
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
