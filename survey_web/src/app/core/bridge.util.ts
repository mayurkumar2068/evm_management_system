export type AppBridgeInvoke = (
  action: string,
  payload?: Record<string, unknown>,
) => Promise<unknown>;

export function getAppBridgeInvoke(): AppBridgeInvoke | null {
  const invoke = (window as Window & { AppBridge?: { invoke?: AppBridgeInvoke } })
    .AppBridge?.invoke;
  return typeof invoke === 'function' ? invoke : null;
}

/** Opens a URL through Flutter when the WebView bridge is available. */
export function openExternalViaBridge(url: string): boolean {
  const invoke = getAppBridgeInvoke();
  if (!invoke) {
    return false;
  }
  void invoke('openExternal', { url }).catch(() => {
    window.location.assign(url);
  });
  return true;
}
