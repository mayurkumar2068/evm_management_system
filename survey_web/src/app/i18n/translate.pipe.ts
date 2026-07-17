import { Pipe, PipeTransform, inject } from '@angular/core';

import { I18nService } from './i18n.service';

/** `{{ 'key' | t }}` or `{{ 'key' | t:{ name: value } }}`. */
@Pipe({ name: 't', standalone: true })
export class TranslatePipe implements PipeTransform {
  private readonly i18n = inject(I18nService);

  transform(key: string, params?: Record<string, string | number>): string {
    return this.i18n.t(key, params);
  }
}
