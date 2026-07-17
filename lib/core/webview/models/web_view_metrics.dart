/// Page-load performance metrics collected from the WebView (milliseconds).
///
/// Populated from the page's `PerformanceNavigationTiming` + paint entries and
/// surfaced via [WebViewConfig.onMetrics] / analytics.
class WebViewMetrics {
  const WebViewMetrics({
    this.ttfb,
    this.domContentLoaded,
    this.firstPaint,
    this.firstContentfulPaint,
    this.largestContentfulPaint,
    this.totalLoadTime,
    this.jsExecutionTime,
  });

  factory WebViewMetrics.fromJson(Map<dynamic, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    return WebViewMetrics(
      ttfb: d(json['ttfb']),
      domContentLoaded: d(json['domContentLoaded']),
      firstPaint: d(json['firstPaint']),
      firstContentfulPaint: d(json['firstContentfulPaint']),
      largestContentfulPaint: d(json['largestContentfulPaint']),
      totalLoadTime: d(json['totalLoadTime']),
      jsExecutionTime: d(json['jsExecutionTime']),
    );
  }

  final double? ttfb;
  final double? domContentLoaded;
  final double? firstPaint;
  final double? firstContentfulPaint;
  final double? largestContentfulPaint;
  final double? totalLoadTime;
  final double? jsExecutionTime;

  @override
  String toString() =>
      'WebViewMetrics(ttfb: $ttfb, dcl: $domContentLoaded, fcp: '
      '$firstContentfulPaint, lcp: $largestContentfulPaint, '
      'total: $totalLoadTime)';
}
