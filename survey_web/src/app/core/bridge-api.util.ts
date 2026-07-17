import { HttpRequest } from '@angular/common/http';

import { environment } from '../../environments/environment';

type AppBridgeInvoke = (
  action: string,
  payload?: Record<string, unknown>,
) => Promise<unknown>;

export interface NativeApiResult {
  body: unknown;
  status: number;
  statusText: string;
}

/** True when the page host differs from the API host and Flutter bridge is ready. */
export function shouldUseNativeApiBridge(url: string): boolean {
  const invoke = (window as Window & { AppBridge?: { invoke?: AppBridgeInvoke } })
    .AppBridge?.invoke;
  if (typeof invoke !== 'function') {
    return false;
  }
  try {
    const apiHost = new URL(environment.apiBaseUrl).host;
    const requestHost = new URL(url, window.location.origin).host;
    const pageHost = window.location.host;
    return (
      apiHost.length > 0 &&
      pageHost.length > 0 &&
      (pageHost !== apiHost || requestHost !== apiHost)
    );
  } catch {
    return false;
  }
}

/** Routes an HTTP call through Flutter native Dio (no browser CORS). */
export async function nativeApiRequest(
  req: HttpRequest<unknown>,
): Promise<NativeApiResult> {
  const invoke = (window as Window & { AppBridge?: { invoke: AppBridgeInvoke } })
    .AppBridge?.invoke;
  if (!invoke) {
    throw new Error('bridge_unavailable');
  }

  const headers: Record<string, string> = {};
  for (const key of req.headers.keys()) {
    const value = req.headers.get(key);
    if (value != null) {
      headers[key] = value;
    }
  }

  const payload = (await invoke('apiRequest', {
    method: req.method,
    url: req.urlWithParams,
    headers,
    body: req.body ?? null,
  })) as { ok?: boolean; status?: number; data?: unknown; error?: string };

  const status = Number(payload?.status ?? (payload?.ok ? 200 : 0));
  return {
    body: payload?.data,
    status,
    statusText: payload?.error ?? (payload?.ok ? 'OK' : 'Error'),
  };
}
