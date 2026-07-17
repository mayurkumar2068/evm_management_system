import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="app-shell">
      <router-outlet />
    </div>
  `,
  styles: [
    `
      .app-shell {
        min-height: 100vh;
        max-width: 520px;
        margin: 0 auto;
        background: var(--ec-bg);
      }
    `,
  ],
})
export class AppComponent {}
