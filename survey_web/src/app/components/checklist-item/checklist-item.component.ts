import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';
import { FormGroup } from '@angular/forms';

import { ImageUploadComponent } from '../image-upload/image-upload.component';
import { TranslatePipe } from '../../i18n/translate.pipe';

type Answer = boolean | null;

/**
 * One checklist row, list-card style:
 *
 *   [#] question text (wraps for long titles)
 *   ─────────────────────────────────────────
 *   [ हाँ | नहीं ]  segmented toggle        [photo]
 *
 * Driven by a reactive `FormGroup`
 * ({ surveyId, title, photoRequired, checked, image }) where `checked`
 * is tri-state: `null` = unanswered, `true` = हाँ, `false` = नहीं.
 */
@Component({
  selector: 'app-checklist-item',
  standalone: true,
  imports: [ImageUploadComponent, TranslatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div
      class="ci"
      [class.ci--compact]="compact"
      [class.ci--yes]="answer === true"
      [class.ci--no]="answer === false"
    >
      <div class="ci__top">
        @if (!compact) {
          <span class="ci__idx">{{ index + 1 }}</span>
        }
        <p class="ci__title">{{ title }}</p>
      </div>

        <div class="ci__bar">
        <div class="seg" role="group" [attr.aria-label]="'ci.yesno.aria' | t">
          <button
            type="button"
            class="seg__btn seg__btn--yes"
            [class.is-active]="answer === true"
            (click)="setAnswer(true)"
          >
            {{ 'ci.yes' | t }}
          </button>
          <button
            type="button"
            class="seg__btn seg__btn--no"
            [class.is-active]="answer === false"
            (click)="setAnswer(false)"
          >
            {{ 'ci.no' | t }}
          </button>
        </div>

        @if (answer === true) {
          <div class="ci__photo">
            @if (!image) {
              <span class="ci__photo-hint">{{ 'ci.photo' | t }}</span>
            }
            <app-image-upload
              [image]="image"
              [disabled]="uploadDisabled && !image"
              (imageChange)="onImage($event)"
              (enlarge)="enlarge.emit($event)"
            />
          </div>
        }
      </div>

      @if (answer === true && !image) {
        <span class="ci__req">{{ 'ci.photoHint' | t }}</span>
      }
    </div>
  `,
  styles: [
    `
      .ci {
        border: 1px solid var(--ec-border);
        border-left: 4px solid #d8e2dd;
        border-radius: 14px;
        background: #fff;
        padding: 12px 13px;
        transition: border-color 0.2s ease, background 0.2s ease;
      }
      .ci--compact {
        border: none;
        border-left: none;
        border-radius: 0;
        background: transparent;
        padding: 0;
      }
      .ci--compact.ci--yes,
      .ci--compact.ci--no {
        background: transparent;
      }
      .ci--yes {
        border-left-color: var(--ec-primary);
        background: rgba(59, 130, 246, 0.08);
      }
      .ci--no {
        border-left-color: #f28baf;
        background: rgba(242, 139, 175, 0.06);
      }

      .ci__top {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        margin-bottom: 12px;
      }
      .ci__idx {
        flex: 0 0 auto;
        width: 24px;
        height: 24px;
        border-radius: 8px;
        background: var(--ec-accent);
        color: #fff;
        font-size: 12.5px;
        font-weight: 700;
        display: grid;
        place-items: center;
        margin-top: 1px;
      }
      .ci__title {
        margin: 0;
        font-size: 15px;
        font-weight: 600;
        line-height: 1.5;
        color: var(--ec-text);
        word-break: break-word;
      }

      .ci__bar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding-left: 34px;
      }
      .ci--compact .ci__bar {
        padding-left: 0;
        margin-top: 4px;
      }

      /* segmented हाँ/नहीं toggle */
      .seg {
        display: inline-flex;
        background: #eef2f7;
        border-radius: 14px;
        padding: 4px;
        gap: 4px;
      }
      .seg__btn {
        border: none;
        background: transparent;
        min-width: 58px;
        padding: 8px 14px;
        border-radius: 10px;
        font-family: inherit;
        font-size: 13.5px;
        font-weight: 600;
        color: var(--ec-text-muted);
        cursor: pointer;
        transition: all 0.18s ease;
      }
      .seg__btn--yes.is-active {
        background: var(--ec-primary);
        color: #fff !important;
        box-shadow: 0 4px 10px rgba(59, 130, 246, 0.24);
      }
      .seg__btn--no.is-active {
        background: #fff;
        color: #ef4444;
        box-shadow: var(--ec-shadow-sm);
      }

      .ci__photo {
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .ci__photo-hint {
        font-size: 12.5px;
        font-weight: 500;
        color: var(--ec-text-muted);
      }

      .ci__req {
        display: block;
        margin: 10px 0 0 34px;
        font-size: 11.5px;
        font-weight: 500;
        color: #ef4444;
      }
      .ci--compact .ci__req {
        margin-left: 0;
      }
    `,
  ],
})
export class ChecklistItemComponent {
  @Input({ required: true }) group!: FormGroup;
  /** Zero-based position used for the row badge. */
  @Input() index = 0;
  /** Hides row badge when parent already shows progress. */
  @Input() compact = false;
  /** True when the global max-images budget is exhausted. */
  @Input() uploadDisabled = false;

  @Output() enlarge = new EventEmitter<string>();

  get title(): string {
    return (this.group.get('title')?.value as string) ?? '';
  }

  get answer(): Answer {
    return (this.group.get('checked')?.value as Answer) ?? null;
  }

  get image(): string | null {
    return (this.group.get('image')?.value as string | null) ?? null;
  }

  get photoRequired(): boolean {
    // Photo is mandatory only when the officer answers हाँ / Yes.
    return this.answer === true;
  }

  setAnswer(value: boolean): void {
    const control = this.group.get('checked');
    // tapping the active option again clears it back to "unanswered"
    const next = this.answer === value ? null : value;
    control?.setValue(next);
    control?.markAsDirty();
    // नहीं → photo not required; clear any attached image
    if (next !== true) {
      this.group.get('image')?.setValue(null);
    }
  }

  onImage(image: string | null): void {
    const control = this.group.get('image');
    control?.setValue(image);
    control?.markAsDirty();
  }
}
