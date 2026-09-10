library;

const String _handlerName = 'app_bridge';

String appBridgeBootstrapJs(String contextJson) {
  return '''
(function () {
  if (window.__APP_BRIDGE_READY__) { return; }
  window.__APP_BRIDGE_READY__ = true;
  window.__APP_CONTEXT__ = $contextJson;

  function nativeCall(action, payload) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        return window.flutter_inappwebview.callHandler('$_handlerName', action, payload || {});
      }
    } catch (e) {}
    return Promise.reject(new Error('bridge_unavailable'));
  }

  var listeners = {};
  window.AppBridge = {
    context: window.__APP_CONTEXT__,
    invoke: function (action, payload) { return nativeCall(action, payload); },
    close: function () { return nativeCall('close', {}); },
    share: function (text, url) { return nativeCall('share', { text: text, url: url }); },
    copy: function (text) { return nativeCall('clipboardCopy', { text: text }); },
    openScanner: function () { return nativeCall('openScanner', {}); },
    pickImage: function (opts) { return nativeCall('pickImage', opts || {}); },
    submitForm: function (opts) { return nativeCall('submitForm', opts || {}); },
    apiRequest: function (opts) { return nativeCall('apiRequest', opts || {}); },
    openExternal: function (url) { return nativeCall('openExternal', { url: url }); },
    logout: function () { return nativeCall('logout', {}); },
    navigate: function (route) { return nativeCall('navigate', { route: route }); },
    log: function (msg) { return nativeCall('log', { message: String(msg) }); },
    post: function (action, payload) { return nativeCall('message', { action: action, payload: payload || {} }); },
    on: function (evt, cb) {
      (listeners[evt] = listeners[evt] || []).push(cb);
      window.addEventListener('app:' + evt, function (e) { cb(e.detail); });
    }
  };

  try {
    var c = window.__APP_CONTEXT__ || {};
    if (c.language) { document.documentElement.lang = c.language; }
    if (c.theme) { document.documentElement.setAttribute('data-theme', c.theme); }
  } catch (e) {}
})();
''';
}

String applyLanguageJs(String lang) {
  return '''
(function () {
  try {
    if (window.__APP_CONTEXT__) { window.__APP_CONTEXT__.language = '$lang'; }
    document.documentElement.lang = '$lang';
    window.dispatchEvent(new CustomEvent('app:language', { detail: { language: '$lang' } }));
  } catch (e) {}
})();
''';
}

String applyThemeJs(String theme) {
  return '''
(function () {
  try {
    if (window.__APP_CONTEXT__) { window.__APP_CONTEXT__.theme = '$theme'; }
    document.documentElement.setAttribute('data-theme', '$theme');
    window.dispatchEvent(new CustomEvent('app:theme', { detail: { theme: '$theme' } }));
  } catch (e) {}
})();
''';
}

const String collectMetricsJs = r'''
(function () {
  try {
    var nav = (performance.getEntriesByType && performance.getEntriesByType('navigation')[0]) || null;
    var paints = (performance.getEntriesByType && performance.getEntriesByType('paint')) || [];
    var fp = null, fcp = null;
    for (var i = 0; i < paints.length; i++) {
      if (paints[i].name === 'first-paint') fp = paints[i].startTime;
      if (paints[i].name === 'first-contentful-paint') fcp = paints[i].startTime;
    }
    var lcp = window.__APP_LCP__ || null;
    if (nav) {
      return {
        ttfb: nav.responseStart,
        domContentLoaded: nav.domContentLoadedEventEnd,
        totalLoadTime: nav.loadEventEnd || nav.duration,
        firstPaint: fp,
        firstContentfulPaint: fcp,
        largestContentfulPaint: lcp,
        jsExecutionTime: nav.domComplete ? (nav.domComplete - nav.domContentLoadedEventEnd) : null
      };
    }
  } catch (e) {}
  return {};
})();
''';

const String lcpObserverJs = r'''
(function () {
  try {
    if (!('PerformanceObserver' in window)) return;
    window.__APP_LCP__ = null;
    var po = new PerformanceObserver(function (list) {
      var entries = list.getEntries();
      if (entries.length) { window.__APP_LCP__ = entries[entries.length - 1].startTime; }
    });
    po.observe({ type: 'largest-contentful-paint', buffered: true });
  } catch (e) {}
})();
''';
