import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

/**
 * Deep-blue rounded header card with the Election Commission emblem and the
 * bilingual title shown on every survey screen.
 */
@Component({
  selector: 'app-header',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <header class="ec-header">
      <img
        class="ec-header__logo"
        src="assets/mp_election_logo.png"
        alt="MP Election Commission"
      />
      <h1 class="ec-header__title">{{ title }}</h1>
      <p class="ec-header__subtitle">{{ subtitle }}</p>
    </header>
  `,
  styles: [
    `
      .ec-header {
        position: relative;
        background: linear-gradient(160deg, #7f6fec 0%, #5246cb 100%);
        border-radius: 0 0 26px 26px;
        padding: 18px 16px 24px;
        text-align: center;
        color: #fff;
        box-shadow: 0 8px 20px rgba(95, 73, 204, 0.32);
      }
      .ec-header::after {
        content: '';
        position: absolute;
        left: 18%;
        right: 18%;
        bottom: 8px;
        height: 3px;
        border-radius: 3px;
        background: linear-gradient(90deg, rgba(255,255,255,0.72) 0%, rgba(255,255,255,0.2) 100%);
      }
      .ec-header__logo {
        width: 54px;
        height: 54px;
        object-fit: contain;
        margin-bottom: 6px;
      }
      .ec-header__title {
        margin: 0;
        font-size: 19px;
        font-weight: 700;
        line-height: 1.3;
        letter-spacing: 0.2px;
      }
      .ec-header__subtitle {
        margin: 4px 0 0;
        font-size: 14px;
        font-weight: 500;
        opacity: 0.92;
      }
      @media (max-width: 360px) {
        .ec-header__title {
          font-size: 17px;
        }
      }
    `,
  ],
})
export class AppHeaderComponent {
  @Input() title = 'मध्य प्रदेश राज्य निर्वाचन आयोग';
  @Input() subtitle = 'मतदान केंद्र चेकलिस्ट';
}
