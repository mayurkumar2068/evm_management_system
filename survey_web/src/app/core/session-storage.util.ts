/** Best-effort JSON persistence across Angular route/chunk reloads. */
export function readSessionJson<T>(key: string): T | null {
  try {
    const raw = sessionStorage.getItem(key);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function writeSessionJson(key: string, value: unknown): void {
  try {
    sessionStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Ignore storage failures (private mode / quota exceeded).
  }
}

export function clearSessionKey(key: string): void {
  try {
    sessionStorage.removeItem(key);
  } catch {
    // Ignore storage failures.
  }
}
