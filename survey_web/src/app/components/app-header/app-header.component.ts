import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

/**
 * Soft blue→mint header card — logo chip + bilingual title (Booth Survey family).
 */
@Component({
  selector: 'app-header',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <header class="ec-header">
      <div class="ec-header__row">
        <div class="ec-header__logo-wrap">
          <img
            class="ec-header__logo"
            src="assets/mp_election_logo.png"
            alt="MP Election Commission"
          />
        </div>
        <div class="ec-header__text">
          <h1 class="ec-header__title">{{ title }}</h1>
          <p class="ec-header__subtitle">{{ subtitle }}</p>
        </div>
      </div>
    </header>
  `,
  styles: [
    `
      .ec-header {
        position: relative;
        overflow: hidden;
        background: var(--ec-grad);
        border-radius: 0 0 22px 22px;
        padding: 16px 16px 18px;
        color: #fff;
        box-shadow: 0 12px 28px rgba(59, 130, 246, 0.22);
      }
      .ec-header::before {
        content: '';
        position: absolute;
        width: 140px;
        height: 140px;
        right: -40px;
        top: -50px;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.12);
        pointer-events: none;
      }
      .ec-header::after {
        content: '';
        position: absolute;
        left: 16%;
        right: 16%;
        bottom: 8px;
        height: 2px;
        border-radius: 3px;
        background: linear-gradient(
          90deg,
          transparent,
          rgba(255, 255, 255, 0.65),
          transparent
        );
      }
      .ec-header__row {
        position: relative;
        z-index: 1;
        display: flex;
        align-items: center;
        gap: 12px;
      }
      .ec-header__logo-wrap {
        flex: 0 0 auto;
        width: 52px;
        height: 52px;
        padding: 6px;
        border-radius: 50%;
        background: #fff;
        box-shadow: 0 6px 14px rgba(15, 39, 68, 0.12);
        overflow: hidden;
      }
      .ec-header__logo {
        width: 100%;
        height: 100%;
        object-fit: contain;
        display: block;
        border-radius: 50%;
      }
      .ec-header__text {
        flex: 1;
        min-width: 0;
        text-align: left;
      }
      .ec-header__title {
        margin: 0;
        font-size: 16px;
        font-weight: 800;
        line-height: 1.3;
        letter-spacing: 0.1px;
      }
      .ec-header__subtitle {
        margin: 4px 0 0;
        font-size: 13px;
        font-weight: 500;
        opacity: 0.92;
        line-height: 1.35;
      }
      @media (max-width: 360px) {
        .ec-header__title {
          font-size: 15px;
        }
      }
    `,
  ],
})
export class AppHeaderComponent {
  @Input() title = 'मध्य प्रदेश राज्य निर्वाचन आयोग';
  @Input() subtitle = 'मतदान केंद्र चेकलिस्ट';
}
