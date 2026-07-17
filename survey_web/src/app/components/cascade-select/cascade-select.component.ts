import {
  Component,
  DestroyRef,
  EventEmitter,
  Input,
  OnChanges,
  Output,
  SimpleChanges,
  inject,
  signal,
} from '@angular/core';
import {
  FormBuilder,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
} from '@angular/forms';
import { Subscription } from 'rxjs';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar } from '@angular/material/snack-bar';

import { CascadeLevel, CascadeSelection } from '../../models/cascade.model';
import { LocationOption } from '../../models/location.model';
import { I18nService } from '../../i18n/i18n.service';

/**
 * Generic, data-driven cascading dropdowns.
 *
 * Feed it any ordered `CascadeLevel[]`; it renders one select per level, loads
 * options lazily, resets/disables every downstream level on change and emits a
 * normalized {@link CascadeSelection}. One component powers both the urban and
 * rural location flows — zero per-screen boilerplate.
 */
@Component({
  selector: 'app-cascade-select',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatFormFieldModule,
    MatSelectModule,
    MatProgressSpinnerModule,
  ],
  template: `
    <form [formGroup]="form" class="cascade">
      @for (level of levels; track level.key; let i = $index; let last = $last) {
        <div class="step" [attr.data-state]="stepState(i)">
          <div class="step__rail">
            <span class="step__badge">
              @if (stepState(i) === 'done') {
                <span class="step__tick">✓</span>
              } @else {
                {{ i + 1 }}
              }
            </span>
            @if (!last) {
              <span class="step__line"></span>
            }
          </div>

          <div class="step__content">
            <span class="step__label">{{ level.label }}</span>
            <mat-form-field
              appearance="outline"
              class="step__field"
              subscriptSizing="dynamic"
            >
              <mat-select
                [formControlName]="level.key"
                [placeholder]="placeholderFor(level.label)"
              >
                @for (opt of optionsFor(level.key); track opt.id) {
                  <mat-option [value]="opt.id">{{ opt.name }}</mat-option>
                }
              </mat-select>
              @if (loadingKey() === level.key) {
                <mat-spinner matSuffix diameter="18" />
              }
            </mat-form-field>
          </div>
        </div>
      }
    </form>
  `,
  styles: [
    `
      .cascade {
        display: flex;
        flex-direction: column;
      }
      .step {
        display: flex;
        gap: 12px;
      }

      /* numbered badge + dotted connector */
      .step__rail {
        flex: 0 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
      }
      .step__badge {
        width: 26px;
        height: 26px;
        border-radius: 50%;
        display: grid;
        place-items: center;
        font-size: 13px;
        font-weight: 700;
        margin-top: 4px;
        background: #f3efff;
        color: var(--ec-text-muted);
        transition: all 0.2s ease;
      }
      .step__tick {
        font-size: 14px;
        line-height: 1;
      }
      .step__line {
        flex: 1;
        width: 2px;
        margin: 4px 0;
        background-image: linear-gradient(
          var(--ec-border) 60%,
          transparent 0
        );
        background-size: 2px 7px;
        background-repeat: repeat-y;
      }
      .step[data-state='active'] .step__badge {
        background: var(--ec-grad);
        color: #fff;
        box-shadow: 0 3px 8px rgba(113, 103, 232, 0.24);
      }
      .step[data-state='done'] .step__badge {
        background: var(--ec-primary);
        color: #fff;
      }

      .step__content {
        flex: 1;
        min-width: 0;
        padding-bottom: 14px;
      }
      .step__label {
        display: block;
        margin: 6px 0 4px;
        font-size: 13px;
        font-weight: 600;
        color: var(--ec-text);
      }
      .step__field {
        width: 100%;
      }
      .step__field ::ng-deep .mat-mdc-text-field-wrapper {
        border-radius: 15px;
        background: #fff;
      }
      .step__field ::ng-deep .mdc-notched-outline__leading {
        border-radius: 15px 0 0 15px;
        width: 15px;
      }
      .step__field ::ng-deep .mdc-notched-outline__trailing {
        border-radius: 0 15px 15px 0;
      }
      .step__field ::ng-deep .mat-mdc-form-field-infix {
        min-height: 44px;
        padding-top: 10px;
        padding-bottom: 10px;
      }
      .step__field ::ng-deep .mat-mdc-form-field-subscript-wrapper {
        display: none;
      }
    `,
  ],
})
export class CascadeSelectComponent implements OnChanges {
  private readonly fb = inject(FormBuilder);
  private readonly destroyRef = inject(DestroyRef);
  private readonly i18n = inject(I18nService);
  private readonly snack = inject(MatSnackBar);

  @Input({ required: true }) levels: CascadeLevel[] = [];
  @Output() readonly selectionChange = new EventEmitter<CascadeSelection>();

  /** Localized "Select <level>" placeholder. */
  placeholderFor(label: string): string {
    return this.i18n.t('cascade.placeholder', { label });
  }

  form = new FormGroup<Record<string, FormControl<string>>>({});
  readonly options = signal<Record<string, LocationOption[]>>({});
  readonly loadingKey = signal<string | null>(null);

  private valueSubs: Subscription[] = [];

  /** Loaded options for a level (empty until its parent is chosen). */
  optionsFor(key: string): LocationOption[] {
    return this.options()[key] ?? [];
  }

  /** Visual state of a step badge: done · active (next to fill) · idle. */
  stepState(index: number): 'done' | 'active' | 'idle' {
    const value = this.form.controls[this.levels[index]?.key]?.value;
    if (value) {
      return 'done';
    }
    const firstEmpty = this.levels.findIndex(
      (l) => !this.form.controls[l.key]?.value,
    );
    return index === firstEmpty ? 'active' : 'idle';
  }

  constructor() {
    this.destroyRef.onDestroy(() => this.teardown());
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['levels']) {
      this.rebuild();
    }
  }

  /** Recreate the form + wiring whenever the level set changes (mode switch). */
  private rebuild(): void {
    this.teardown();

    const controls: Record<string, FormControl<string>> = {};
    this.levels.forEach((level, index) => {
      controls[level.key] = this.fb.nonNullable.control(
        { value: '', disabled: index !== 0 },
      );
    });
    this.form = new FormGroup(controls);
    this.options.set({});
    this.loadingKey.set(null);

    if (this.levels.length) {
      this.loadLevel(0);
    }

    this.levels.forEach((level, index) => {
      this.valueSubs.push(
        this.form.controls[level.key].valueChanges.subscribe((id) =>
          this.onLevelChange(index, id),
        ),
      );
    });

    this.emit();
  }

  private onLevelChange(index: number, selectedId: string): void {
    for (let j = index + 1; j < this.levels.length; j++) {
      const key = this.levels[j].key;
      this.form.controls[key].reset('', { emitEvent: false });
      this.form.controls[key].disable({ emitEvent: false });
      this.setOptions(key, []);
    }

    if (selectedId && index + 1 < this.levels.length) {
      this.loadLevel(index + 1);
    }

    this.emit();
  }

  /** Current key → selected id for every level (used by loaders). */
  private currentValues(): Record<string, string> {
    const values: Record<string, string> = {};
    for (const level of this.levels) {
      values[level.key] = this.form.controls[level.key]?.value ?? '';
    }
    return values;
  }

  private loadLevel(index: number): void {
    const level = this.levels[index];
    this.loadingKey.set(level.key);
    level.load(this.currentValues()).subscribe({
      next: (list) => {
        this.setOptions(level.key, list);
        // Always enable once the request finishes so the user can open the
        // panel (empty list is clearer than a permanently disabled control).
        this.form.controls[level.key].enable({ emitEvent: false });
        this.loadingKey.set(null);
        if (index > 0 && list.length === 0) {
          this.snack.open(this.i18n.t('cascade.loadError'), 'OK', {
            duration: 3500,
          });
        }
      },
      error: () => {
        this.setOptions(level.key, []);
        this.form.controls[level.key].enable({ emitEvent: false });
        this.loadingKey.set(null);
        this.snack.open(this.i18n.t('cascade.loadError'), 'OK', {
          duration: 3500,
        });
      },
    });
  }

  private setOptions(key: string, list: LocationOption[]): void {
    this.options.update((curr) => ({ ...curr, [key]: list }));
  }

  private emit(): void {
    const values: Record<string, string> = {};
    const labels: Record<string, string> = {};
    let complete = true;

    for (const level of this.levels) {
      const id = this.form.controls[level.key]?.value ?? '';
      values[level.key] = id;
      labels[level.key] =
        (this.options()[level.key] ?? []).find((o) => o.id === id)?.name ?? '';
      if (!id) {
        complete = false;
      }
    }

    this.selectionChange.emit({ values, labels, complete });
  }

  private teardown(): void {
    this.valueSubs.forEach((s) => s.unsubscribe());
    this.valueSubs = [];
  }
}
