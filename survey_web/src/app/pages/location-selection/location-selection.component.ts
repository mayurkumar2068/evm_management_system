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

function loginUrbanRural(): string {
  return APP_PARAMS.urbanRural.trim().toUpperCase();
}

function areaMatchesLogin(area: AreaType | null): boolean {
  const scope = loginUrbanRural();
  if (!scope || !area) {
    return false;
  }
  // Prefill bodyId only for matching area — never put urban BodyID into rural block.
  if ((scope === 'U' || scope === 'URBAN') && area === 'urban') {
    return true;
  }
  if ((scope === 'R' || scope === 'RURAL') && area === 'rural') {
    return true;
  }
  return false;
}

/** Material icon for each location level (used by the summary card). */
const LEVEL_ICONS: Record<string, string> = {
  districtId: 'location_on',
  blockId: 'map',
  panchayatId: 'holiday_village',
  bodyTypeId: 'domain',
  bodyId: 'location_city',
  boothId: 'how_to_vote',
};

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
    const scoped = areaMatchesLogin(area);
    const session = this.surveyAuth.session;
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
    const scoped = areaMatchesLogin(area);
    const session = this.surveyAuth.session;
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
    const urbanRural = APP_PARAMS.urbanRural.trim().toUpperCase();
    if (urbanRural === 'U' || urbanRural === 'URBAN') {
      this.areaType.set('urban');
    } else if (urbanRural === 'R' || urbanRural === 'RURAL') {
      this.areaType.set('rural');
    }
  }

  setArea(type: AreaType): void {
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
        label: this.i18n.t('loc.row.areaType'),
        value: areaType === 'urban' ? this.i18n.t('area.urban') : this.i18n.t('area.rural'),
        icon: 'category',
      },
      ...this.levels().map((level) => ({
        label: level.label,
        value: current.labels[level.key] ?? '',
        icon: LEVEL_ICONS[level.key] ?? 'place',
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
