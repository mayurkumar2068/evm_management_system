import {
  ChangeDetectionStrategy,
  Component,
  Input,
  signal,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { Coordinates } from '../../models/location.model';
import { TranslatePipe } from '../../i18n/translate.pipe';
import { openMapDirections, staticMapImageUrl } from '../../utils/map-navigation.util';

@Component({
  selector: 'app-booth-map-card',
  standalone: true,
  imports: [
    DecimalPipe,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    TranslatePipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (booth; as dest) {
      <section class="booth-map">
        <div class="booth-map__preview">
          <img
            [src]="mapImageUrl(dest)"
            alt=""
            loading="lazy"
            (error)="mapFailed.set(true)"
          />
          @if (mapFailed()) {
            <div class="booth-map__fallback">
              <mat-icon>map</mat-icon>
            </div>
          }
          <span class="booth-map__chip">
            <mat-icon>location_on</mat-icon>
            {{ 'map.boothChip' | t }}
          </span>
        </div>

        <div class="booth-map__body">
          <h3 class="booth-map__title">{{ 'map.boothTitle' | t }}</h3>
          <p class="booth-map__coords">
            {{ dest.latitude | number: '1.4-5' }}°,
            {{ dest.longitude | number: '1.4-5' }}
          </p>
          @if (boothLabel) {
            <p class="booth-map__name">{{ boothLabel }}</p>
          }

          <button
            type="button"
            class="booth-map__nav"
            [disabled]="navigating()"
            (click)="navigate(dest)"
          >
            @if (navigating()) {
              <mat-spinner diameter="18" strokeWidth="2" />
            } @else {
              <mat-icon>directions</mat-icon>
            }
            <span>{{ 'map.navigate' | t }}</span>
          </button>
        </div>
      </section>
    }
  `,
  styles: [
    `
      .booth-map {
        border: 1px solid var(--ec-border);
        border-radius: 20px;
        overflow: hidden;
        background: #fff;
        box-shadow: var(--ec-shadow-sm);
      }
      .booth-map__preview {
        position: relative;
        aspect-ratio: 16 / 7;
        background: #f3f4fa;
      }
      .booth-map__preview img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
      }
      .booth-map__fallback {
        position: absolute;
        inset: 0;
        display: grid;
        place-items: center;
        color: var(--ec-text-muted);
      }
      .booth-map__chip {
        position: absolute;
        top: 10px;
        left: 10px;
        display: inline-flex;
        align-items: center;
        gap: 4px;
        padding: 5px 10px;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.94);
        font-size: 12px;
        font-weight: 700;
        color: var(--ec-text);
      }
      .booth-map__chip mat-icon {
        font-size: 16px;
        width: 16px;
        height: 16px;
        color: var(--ec-primary);
      }
      .booth-map__body {
        padding: 14px;
      }
      .booth-map__title {
        margin: 0 0 4px;
        font-size: 15px;
        font-weight: 800;
        color: var(--ec-text);
      }
      .booth-map__coords,
      .booth-map__name {
        margin: 0 0 4px;
        font-size: 12.5px;
        color: var(--ec-text-muted);
      }
      .booth-map__nav {
        margin-top: 12px;
        width: 100%;
        min-height: 46px;
        border: none;
        border-radius: 14px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        font: inherit;
        font-size: 15px;
        font-weight: 700;
        color: #fff;
        background: linear-gradient(135deg, #6f63eb 0%, #5348cf 100%);
        box-shadow: 0 10px 22px rgba(83, 72, 207, 0.24);
        cursor: pointer;
      }
      .booth-map__nav:disabled {
        opacity: 0.7;
        cursor: wait;
      }
      .booth-map__nav mat-icon {
        font-size: 20px;
        width: 20px;
        height: 20px;
      }
    `,
  ],
})
export class BoothMapCardComponent {
  @Input() booth: Coordinates | null = null;
  @Input() current: Coordinates | null = null;
  @Input() boothLabel = '';

  readonly mapFailed = signal(false);
  readonly navigating = signal(false);

  mapImageUrl(dest: Coordinates): string {
    return staticMapImageUrl(dest.latitude, dest.longitude);
  }

  navigate(dest: Coordinates): void {
    if (this.navigating()) {
      return;
    }
    this.navigating.set(true);
    try {
      openMapDirections(dest, this.current, this.boothLabel || 'मतदान केंद्र');
    } finally {
      window.setTimeout(() => this.navigating.set(false), 600);
    }
  }
}
