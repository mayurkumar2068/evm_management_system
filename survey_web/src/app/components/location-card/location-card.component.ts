import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';

import { LabelValue } from '../../models/location.model';

/**
 * White card showing the chosen location in a two-column label/value grid.
 * Fully generic — works for both the urban and rural flows since it just
 * renders whatever {@link LabelValue} rows it is given.
 */
@Component({
  selector: 'app-location-card',
  standalone: true,
  imports: [MatIconModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="loc-card">
      @for (row of rows; track row.label) {
        <div class="loc-row">
          <span class="loc-row__label">
            @if (row.icon) {
              <mat-icon>{{ row.icon }}</mat-icon>
            }
            {{ row.label }}
          </span>
          <span class="loc-row__value">{{ row.value || '—' }}</span>
        </div>
      }
    </section>
  `,
  styles: [
    `
      .loc-card {
        background: var(--ec-card);
        border: 1px solid var(--ec-border);
        border-radius: var(--ec-radius);
        padding: 6px 16px;
        box-shadow: var(--ec-shadow-sm);
        animation: ec-fade-up 0.4s ease both;
      }
      .loc-row {
        display: grid;
        grid-template-columns: 140px 1fr;
        align-items: center;
        padding: 9px 0;
        gap: 10px;
      }
      .loc-row + .loc-row {
        border-top: 1px dashed var(--ec-border);
      }
      .loc-row__label {
        display: flex;
        align-items: center;
        gap: 7px;
        font-weight: 500;
        color: var(--ec-text-secondary);
        font-size: 13.5px;
      }
      .loc-row__label mat-icon {
        font-size: 17px;
        width: 17px;
        height: 17px;
        color: var(--ec-primary);
      }
      .loc-row__value {
        color: var(--ec-text);
        font-size: 14px;
        font-weight: 600;
        text-align: right;
        line-height: 1.4;
      }
      @media (max-width: 340px) {
        .loc-row {
          grid-template-columns: 116px 1fr;
        }
      }
    `,
  ],
})
export class LocationCardComponent {
  @Input() rows: LabelValue[] = [];
}
