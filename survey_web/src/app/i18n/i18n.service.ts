import { Injectable } from '@angular/core';

import { Lang, TRANSLATIONS } from './translations';

/**
 * Minimal, dependency-free runtime i18n. The language is resolved once from the
 * `?lang=` query parameter (set by the Flutter WebView) and stays fixed for the
 * session, so a pure `| t` pipe is enough — no change-detection churn.
 */
@Injectable({ providedIn: 'root' })
export class I18nService {
  /** Survey UI is Hindi-first for field officers. */
  readonly lang: Lang = 'hi';

  constructor() {
    if (typeof document !== 'undefined') {
      document.documentElement.lang = this.lang;
    }
  }

  /** Translate `key`, substituting `{name}` placeholders from `params`. */
  t(key: string, params?: Record<string, string | number>): string {
    const dict = TRANSLATIONS[this.lang] ?? TRANSLATIONS.hi;
    let str = dict[key] ?? TRANSLATIONS.hi[key] ?? key;
    if (params) {
      for (const [k, v] of Object.entries(params)) {
        str = str.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
      }
    }
    return str;
  }
}
