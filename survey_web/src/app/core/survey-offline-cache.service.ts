import { Injectable } from '@angular/core';

const PREFIX = 'mp_survey_cache:v2:';

/** localStorage cache for masters + checklist when network fails. */
@Injectable({ providedIn: 'root' })
export class SurveyOfflineCacheService {
  read<T>(key: string): T | null {
    try {
      const raw = localStorage.getItem(PREFIX + key);
      if (!raw) {
        return null;
      }
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  write<T>(key: string, value: T): void {
    try {
      localStorage.setItem(PREFIX + key, JSON.stringify(value));
    } catch {
      // Quota or private mode — ignore.
    }
  }

  readList<T>(key: string): T[] {
    const value = this.read<T[]>(key);
    return Array.isArray(value) ? value : [];
  }

  queuePendingSave(payload: unknown): void {
    const queue = this.read<unknown[]>('pending_saves') ?? [];
    queue.push({ ...payload as object, queuedAt: Date.now() });
    this.write('pending_saves', queue);
  }

  readPendingSaves<T>(): T[] {
    return this.readList<T>('pending_saves');
  }

  clearPendingSaves(): void {
    localStorage.removeItem(PREFIX + 'pending_saves');
  }
}
