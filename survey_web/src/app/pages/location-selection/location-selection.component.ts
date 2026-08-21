import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { Router } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBar } from '@angular/material/snack-bar';

import { CascadeSelectComponent } from '../../components/cascade-select/cascade-select.component';
import { CascadeSelection } from '../../models/cascade.model';
import {
  AreaType,
  LabelValue,
  SelectedLocation,
} from '../../models/location.model';
import { I18nService } from '../../i18n/i18n.service';
import { TranslatePipe } from '../../i18n/translate.pipe';
import { SurveyService } from '../../services/survey.service';
import { APP_PARAMS } from '../../core/app-params';
import { SurveyAuthService } from '../../services/survey-auth.service';
import {
  buildRuralLevels,
  buildUrbanLevels,
} from '../../utils/location-levels.util';

function loginUrbanRural(sessionUrbanRural?: string | null): string {
  return (
    APP_PARAMS.urbanRural.trim().toUpperCase() ||
    (sessionUrbanRural ?? '').trim().toUpperCase()
  );
}

function areaMatchesLogin(
  area: AreaType | null,
  sessionUrbanRural?: string | null,
): boolean {
  const scope = loginUrbanRural(sessionUrbanRural);
  if (!area) {
    return false;
  }
  // Prefill bodyId only for matching area — never put urban BodyID into rural block.
  if ((scope === 'U' || scope === 'URBAN') && area === 'urban') {
    return true;
  }
  if ((scope === 'R' || scope === 'RURAL') && area === 'rural') {
    return true;
  }
  // Missing urbanRural but user is on rural: still prefill BodyID as जनपद (survey rural login).
  if (!scope && area === 'rural' && APP_PARAMS.bodyId.trim()) {
    return true;
  }
  return false;
}

@Component({
  selector: 'app-location-selection',
  standalone: true,
  imports: [
    MatButtonModule,
    MatButtonToggleModule,
    MatIconModule,
    CascadeSelectComponent,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './location-selection.component.html',
  styleUrl: './location-selection.component.scss',
})
export class LocationSelectionComponent implements OnInit {
  private readonly survey = inject(SurveyService);
  private readonly surveyAuth = inject(SurveyAuthService);
  private readonly router = inject(Router);
  private readonly snack = inject(MatSnackBar);
  private readonly i18n = inject(I18nService);

  /** Top-level नगरीय / पंचायत switch. */
  readonly areaType = signal<AreaType | null>(null);

  /** Login UrbanRural — locks UI to one area when present. */
  readonly loginScope = computed(() =>
    loginUrbanRural(this.surveyAuth.session?.urbanRural),
  );

  readonly isUrbanLocked = computed(() => {
    const s = this.loginScope();
    return s === 'U' || s === 'URBAN';
  });

  readonly isRuralLocked = computed(() => {
    const s = this.loginScope();
    return s === 'R' || s === 'RURAL';
  });

  /** Show urban toggle only when not locked to rural. */
  readonly showUrbanTab = computed(() => !this.isRuralLocked());

  /** Show rural toggle only when not locked to urban. */
  readonly showRuralTab = computed(() => !this.isUrbanLocked());

  readonly areaLocked = computed(
    () => this.isUrbanLocked() || this.isRuralLocked(),
  );

  /** Levels rendered by the cascade — swap automatically on area change. */
  readonly levels = computed(() => {
    const type = this.areaType();
    return type === 'urban'
      ? buildUrbanLevels(this.survey, this.i18n)
      : type === 'rural'
      ? buildRuralLevels(this.survey, this.i18n)
      : [];
  });

  /** Live selection emitted by `<app-cascade-select>`. */
  readonly selection = signal<CascadeSelection | null>(null);

  /** Auto-fill district + body/block only when area matches login scope. */
  readonly cascadePrefill = computed(() => {
    const area = this.areaType();
    const session = this.surveyAuth.session;
    const scoped = areaMatchesLogin(area, session?.urbanRural);
    const bodyId = scoped
      ? APP_PARAMS.bodyId.trim() || session?.bodyId?.trim() || ''
      : '';
    return {
      districtId: APP_PARAMS.districtId.trim() || session?.districtId?.trim() || '',
      blockId: bodyId,
      bodyId,
    };
  });

  readonly cascadePrefillNames = computed(() => {
    const area = this.areaType();
    const session = this.surveyAuth.session;
    const scoped = areaMatchesLogin(area, session?.urbanRural);
    const bodyName = scoped
      ? APP_PARAMS.bodyName.trim() || session?.bodyName?.trim() || ''
      : '';
    return {
      districtId: APP_PARAMS.distName.trim() || session?.distName?.trim() || '',
      blockId: bodyName,
      bodyId: bodyName,
    };
  });

  readonly canProceed = computed(
    () => this.areaType() !== null && this.selection()?.complete === true,
  );

  ngOnInit(): void {
    // Reload/refresh inside the WebView re-enters at this route (the Flutter
    // host reloads the base URL, not the SPA path). If a location is still
    // in session, the survey is already in progress — resume the checklist
    // directly instead of forcing district/booth reselection.
    if (this.survey.selectedLocation()) {
      void this.router.navigate(['/checklist']);
      return;
    }

    const urbanRural = loginUrbanRural(this.surveyAuth.session?.urbanRural);
    if (urbanRural === 'U' || urbanRural === 'URBAN') {
      this.areaType.set('urban');
    } else if (urbanRural === 'R' || urbanRural === 'RURAL') {
      this.areaType.set('rural');
    }
  }

  setArea(type: AreaType): void {
    // Login-scoped: do not allow switching away from U/R assigned area.
    if (this.isUrbanLocked() && type !== 'urban') {
      return;
    }
    if (this.isRuralLocked() && type !== 'rural') {
      return;
    }
    if (type === this.areaType()) {
      return;
    }
    this.areaType.set(type);
    this.selection.set(null);
  }

  onSelectionChange(selection: CascadeSelection): void {
    this.selection.set(selection);
  }

  next(): void {
    const current = this.selection();
    const areaType = this.areaType();

    if (!areaType || !current?.complete) {
      this.snack.open(this.i18n.t('loc.validation.selectAll'), 'OK', {
        duration: 2500,
      });
      return;
    }

    const rows: LabelValue[] = [
      {
        key: 'areaType',
        label: this.i18n.t('loc.row.areaType'),
        value: areaType === 'urban' ? this.i18n.t('area.urban') : this.i18n.t('area.rural'),
      },
      ...this.levels().map((level) => ({
        key: level.key,
        label:
          level.key === 'boothId'
            ? this.i18n.t('loc.row.booth')
            : level.label,
        value: current.labels[level.key] ?? '',
      })),
    ];

    const location: SelectedLocation = {
      // Fix: cast areaType to satisfy TypeScript narrowing after null check.
      areaType: areaType as AreaType,
      values: current.values,
      rows,
    };
    this.survey.setLocation(location);
    void this.router.navigate(['/checklist']);
  }
}
