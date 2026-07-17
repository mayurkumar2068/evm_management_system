import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

import { Coordinates } from '../../models/location.model';
import { TranslatePipe } from '../../i18n/translate.pipe';

/** Dark "Location Coordinates" pill matching the screenshot. */
@Component({
  selector: 'app-coordinates-card',
  standalone: true,
  imports: [
    DecimalPipe,
    MatProgressSpinnerModule,
    MatButtonModule,
    MatIconModule,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="coord">
      <span class="coord__glow"></span>

      <header class="coord__head">
        <span class="coord__dot" [class.coord__dot--idle]="!loading && !coordinates"></span>
        <span class="coord__title">
          @if (loading) {
            {{ 'coord.loading' | t }}
          } @else if (coordinates) {
            {{ 'coord.live' | t }}
          } @else {
            {{ 'coord.unavailable' | t }}
          }
        </span>
        @if (loading) {
          <mat-spinner class="coord__spin" diameter="16" strokeWidth="2" />
        }
      </header>

      @if (error) {
        <p class="coord__error">{{ error }}</p>
      } @else if (coordinates) {
        <div class="coord__grid">
          <div class="coord__cell">
            <span class="coord__k">{{ 'coord.lat' | t }}</span>
            <span class="coord__v">
              {{ absLat | number: '1.4-4' }}° {{ latHemisphere }}
            </span>
          </div>
          <div class="coord__cell">
            <span class="coord__k">{{ 'coord.lng' | t }}</span>
            <span class="coord__v">
              {{ absLng | number: '1.4-4' }}° {{ lngHemisphere }}
            </span>
          </div>
        </div>
      } @else if (!loading) {
        <p class="coord__muted">{{ 'coord.permNote' | t }}</p>
      }

      <footer class="coord__foot">
        <span class="coord__src">
          <mat-icon>gps_fixed</mat-icon> {{ 'coord.source' | t }}
        </span>
        <button
          type="button"
          class="coord__retry"
          [disabled]="loading"
          (click)="retry.emit()"
        >
          <mat-icon>refresh</mat-icon> {{ 'coord.retry' | t }}
        </button>
      </footer>
    </section>
  `,
  styles: [
    `
      .coord {
        position: relative;
        overflow: hidden;
        background:
          radial-gradient(120% 90% at 100% 0%, rgba(113, 103, 232, 0.2), transparent 55%),
          linear-gradient(135deg, #1f2145 0%, #111229 100%);
        color: #e9eefc;
        border-radius: var(--ec-radius);
        padding: 14px 15px;
        box-shadow: 0 12px 28px rgba(24, 24, 72, 0.28);
      }
      .coord__glow {
        position: absolute;
        top: -26px;
        right: -26px;
        width: 90px;
        height: 90px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(113, 103, 232, 0.3), transparent 70%);
      }
      .coord__head {
        position: relative;
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 12.5px;
        font-weight: 600;
        color: #d8dcff;
        margin-bottom: 12px;
      }
      .coord__dot {
        width: 9px;
        height: 9px;
        border-radius: 50%;
        background: #8b78f0;
        box-shadow: 0 0 0 0 rgba(139, 120, 240, 0.6);
        animation: coord-pulse 1.8s infinite;
      }
      .coord__dot--idle {
        background: #9ca3af;
        animation: none;
      }
      .coord__spin {
        margin-left: auto;
      }
      @keyframes coord-pulse {
        0% {
          box-shadow: 0 0 0 0 rgba(139, 120, 240, 0.55);
        }
        70% {
          box-shadow: 0 0 0 8px rgba(139, 120, 240, 0);
        }
        100% {
          box-shadow: 0 0 0 0 rgba(139, 120, 240, 0);
        }
      }
      .coord__grid {
        position: relative;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
      }
      .coord__cell {
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 12px;
        padding: 10px 12px;
        display: flex;
        flex-direction: column;
        gap: 4px;
      }
      .coord__k {
        color: #9fb8ad;
        font-size: 11px;
        font-weight: 600;
      }
      .coord__v {
        font-weight: 700;
        font-size: 16px;
        font-variant-numeric: tabular-nums;
        color: #ecfdf5;
      }
      .coord__muted {
        position: relative;
        margin: 0;
        color: #9ca3af;
        font-size: 12.5px;
      }
      .coord__error {
        position: relative;
        margin: 0 0 4px;
        color: #fca5a5;
        font-size: 12.5px;
      }
      .coord__foot {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-top: 12px;
        padding-top: 10px;
        border-top: 1px solid rgba(255, 255, 255, 0.08);
      }
      .coord__src {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        font-size: 11.5px;
        color: #9fb8ad;
      }
      .coord__src mat-icon {
        font-size: 14px;
        width: 14px;
        height: 14px;
        color: #b9b5ff;
      }
      .coord__retry {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        border: none;
        background: transparent;
        color: #b9b5ff;
        font-family: inherit;
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
      }
      .coord__retry:disabled {
        opacity: 0.45;
      }
      .coord__retry mat-icon {
        font-size: 16px;
        width: 16px;
        height: 16px;
      }
    `,
  ],
})
export class CoordinatesCardComponent {
  @Input() coordinates: Coordinates | null = null;
  @Input() loading = false;
  @Input() error: string | null = null;
  @Output() retry = new EventEmitter<void>();

  get absLat(): number {
    return Math.abs(this.coordinates?.latitude ?? 0);
  }

  get absLng(): number {
    return Math.abs(this.coordinates?.longitude ?? 0);
  }

  get latHemisphere(): string {
    return (this.coordinates?.latitude ?? 0) >= 0 ? 'N' : 'S';
  }

  get lngHemisphere(): string {
    return (this.coordinates?.longitude ?? 0) >= 0 ? 'E' : 'W';
  }
}
