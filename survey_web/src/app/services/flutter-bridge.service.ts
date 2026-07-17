import { Injectable } from '@angular/core';

/** Response contract from Flutter after every bridge submit. */
export interface FlutterBridgeSubmitResponse {
  ok?: boolean;
  success: boolean;
  mode: 'online' | 'offline' | 'duplicate';
  clientId?: string;
  referenceId?: string;
  message?: string;
  error?: string;
}

/** Options passed to {@link FlutterBridgeService.submitForm}. */
export interface FlutterBridgeSubmitOptions {
  /** Logical form name — survey, registration, checklist, inspection, … */
  formType: string;
  /** API path relative to the survey base, e.g. `/survey/submit`. */
  endpoint: string;
  /** Full JSON body the server expects. */
  data: Record<string, unknown>;
  /** Client-generated UUID for de-duplication (auto-generated when omitted). */
  clientId?: string;
}

type AppBridge = {
  submitForm?: (opts: FlutterBridgeSubmitOptions) => Promise<FlutterBridgeSubmitResponse>;
  invoke?: (action: string, payload?: Record<string, unknown>) => Promise<unknown>;
};

/**
 * Reusable bridge for every Angular page embedded in the Flutter WebView.
 *
 * Angular never checks `navigator.onLine` or writes to local storage — Flutter
 * is the single source of truth for connectivity and offline persistence.
 */
@Injectable({ providedIn: 'root' })
export class FlutterBridgeService {
  /** `true` when running inside the Flutter InAppWebView with AppBridge. */
  isAvailable(): boolean {
    return typeof this.bridge()?.submitForm === 'function';
  }

  /**
   * Submits a form through Flutter. Flutter uploads immediately when online or
   * queues locally when offline. The caller only sees `{ success, mode }`.
   */
  async submitForm(
    options: FlutterBridgeSubmitOptions,
  ): Promise<FlutterBridgeSubmitResponse> {
    const bridge = this.bridge();
    if (!bridge?.submitForm) {
      return {
        success: false,
        mode: 'online',
        error: 'bridge_unavailable',
      };
    }

    const clientId = options.clientId ?? this.newClientId();
    try {
      const result = await bridge.submitForm({
        ...options,
        clientId,
      });
      return {
        success: Boolean(result?.success ?? result?.ok),
        mode: (result?.mode as FlutterBridgeSubmitResponse['mode']) ?? 'online',
        clientId: result?.clientId ?? clientId,
        referenceId: result?.referenceId,
        message: result?.message,
        error: result?.error,
      };
    } catch (err) {
      return {
        success: false,
        mode: 'online',
        clientId,
        error: err instanceof Error ? err.message : 'bridge_call_failed',
      };
    }
  }

  private bridge(): AppBridge | undefined {
    return (window as Window & { AppBridge?: AppBridge }).AppBridge;
  }

  private newClientId(): string {
    if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
      return crypto.randomUUID();
    }
    return `web-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  }
}
