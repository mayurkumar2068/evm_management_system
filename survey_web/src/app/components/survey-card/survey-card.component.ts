import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { FormGroup } from '@angular/forms';

import { ChecklistItemComponent } from '../checklist-item/checklist-item.component';

/**
 * White card wrapping the full checklist. Enforces the global photo budget by
 * disabling the camera button on un-photographed rows once `usedImages`
 * reaches `maxImages`.
 */
@Component({
  selector: 'app-survey-card',
  standalone: true,
  imports: [ChecklistItemComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="sc">
      <div class="sc__list">
        @for (g of groups; track $index) {
          <app-checklist-item
            [group]="g"
            [index]="$index"
            [uploadDisabled]="budgetReached"
            (enlarge)="enlarge.emit($event)"
          />
        }
      </div>
    </section>
  `,
  styles: [
    `
      .sc {
        background: var(--ec-card);
        border: 1px solid var(--ec-border);
        border-radius: var(--ec-radius);
        padding: 12px;
        box-shadow: var(--ec-shadow-sm);
        animation: ec-fade-up 0.4s ease both;
      }
      .sc__list {
        display: flex;
        flex-direction: column;
        gap: 10px;
      }
    `,
  ],
})
export class SurveyCardComponent {
  @Input() groups: FormGroup[] = [];
  @Input() maxImages = 6;
  @Input() usedImages = 0;

  @Output() enlarge = new EventEmitter<string>();

  get budgetReached(): boolean {
    return this.usedImages >= this.maxImages;
  }
}
