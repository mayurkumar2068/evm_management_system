import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:mobile_scanner/mobile_scanner.dart';

/// The live tracking phase of a scan session, surfaced to the user as a
/// percentage + status hint while the camera locks on to a code.
enum _ScanPhase {
  searching, // nothing in frame yet
  locking, // a code is in view; building stable reads
  verifying, // almost confirmed
  locked, // confirmed → review & save
}

/// Highly optimized AI-powered scanner for EVM management.
/// Features laser rays, auto-detection for QR/Barcodes, and localized scan windows.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF070F1F);
  static const Color _overlayColor = Color(0x99000000); // 60% black

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 1000,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.aztec,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.itf14,
      BarcodeFormat.pdf417,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  late final AnimationController _scanAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  String? _detected;
  double _zoomFactor = 0.0;

  // ── Scan tracking ──────────────────────────────────────────────────────────
  // We don't accept the very first frame a code appears in; instead we require
  // a few *consecutive* reads of the same value. This both (a) gives us a real
  // progress signal to show the user and (b) rejects fleeting misreads, making
  // detection more reliable. Progress = stable reads / threshold.
  static const int _confirmThreshold = 5;
  String? _candidate;
  int _stableHits = 0;
  double _progress = 0.0;
  _ScanPhase _phase = _ScanPhase.searching;
  DateTime _lastSeen = DateTime.now();
  Timer? _decayTimer;

  @override
  void initState() {
    super.initState();
    // When the code leaves the frame, gently wind progress back down so the
    // indicator reflects reality instead of freezing at a stale value.
    _decayTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (_detected != null) return;
      final bool stale =
          DateTime.now().difference(_lastSeen) >
          const Duration(milliseconds: 600);
      if (!stale || _stableHits == 0) return;
      setState(() {
        _stableHits = (_stableHits - 1).clamp(0, _confirmThreshold);
        _progress = _stableHits / _confirmThreshold;
        if (_stableHits == 0) {
          _candidate = null;
          _phase = _ScanPhase.searching;
        }
      });
    });
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _scanAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected != null) return;
    final Barcode? barcode = _pickBarcode(capture);
    final String? raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _lastSeen = DateTime.now();

    // Same code as last frame → one more stable read; otherwise restart the
    // lock-on against the new candidate.
    if (raw == _candidate) {
      _stableHits++;
    } else {
      _candidate = raw;
      _stableHits = 1;
    }

    if (_stableHits >= _confirmThreshold) {
      _confirm(raw, barcode!);
      return;
    }

    setState(() {
      _progress = (_stableHits / _confirmThreshold).clamp(0.0, 1.0);
      _phase = _stableHits >= _confirmThreshold - 1
          ? _ScanPhase.verifying
          : _ScanPhase.locking;
    });
  }

  /// Pick the first non-empty barcode in the frame (the scan window already
  /// restricts detection to the centre, so this is the targeted code).
  Barcode? _pickBarcode(BarcodeCapture capture) {
    for (final Barcode b in capture.barcodes) {
      if ((b.rawValue ?? '').isNotEmpty) return b;
    }
    return null;
  }

  void _confirm(String raw, Barcode barcode) {
    setState(() {
      _detected = raw;
      _progress = 1.0;
      _phase = _ScanPhase.locked;
    });
    _controller.stop();

    final bool isCu = raw.toUpperCase().contains('CU');
    final bool isQr =
        barcode.format == BarcodeFormat.qrCode ||
        barcode.format == BarcodeFormat.dataMatrix;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showResult(raw, isCu, isQr);
    });
  }

  void _toggleZoom() {
    setState(() {
      _zoomFactor = _zoomFactor == 0.0 ? 0.5 : 0.0;
    });
    _controller.setZoomScale(_zoomFactor);
  }

  Future<void> _showResult(String code, bool isCu, bool isQr) async {
    final bool? register = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _ResultSheet(
        code: code,
        isCu: isCu,
        isQr: isQr,
        onDiscard: () {
          Navigator.of(sheetContext).pop(false);
          _reset();
        },
        onRegister: () => Navigator.of(sheetContext).pop(true),
      ),
    );

    if (!mounted) return;
    if (register ?? false) {
      Get.back<dynamic>(result: code);
    }
  }

  void _reset() {
    setState(() {
      _detected = null;
      _candidate = null;
      _stableHits = 0;
      _progress = 0.0;
      _phase = _ScanPhase.searching;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;

    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 300,
      height: 220,
    );

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            scanWindow: scanWindow,
          ),
          _buildOverlay(top, scanWindow),
          Positioned(bottom: 40, left: 20, right: 20, child: _bottomControls()),
        ],
      ),
    );
  }

  Widget _buildOverlay(double top, Rect scanWindow) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, 20),
          color: _overlayColor,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back<void>(),
              ),
              Expanded(
                child: Text(
                  LocaleKeys.scannerTitle.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  _overlayColor,
                  BlendMode.srcOut,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Center(
                      child: Container(
                        width: scanWindow.width,
                        height: scanWindow.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: SizedBox(
                  width: scanWindow.width,
                  height: scanWindow.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: LaserGridPainter(animation: _scanAnim),
                    ),
                  ),
                ),
              ),
              ..._buildCorners(scanWindow),
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (context, child) {
                  return Positioned(
                    top: scanWindow.top + (_scanAnim.value * scanWindow.height),
                    left: scanWindow.left,
                    width: scanWindow.width,
                    child: Column(
                      children: [
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBright.withValues(
                                  alpha: 0.8,
                                ),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                            color: AppColors.primaryBright,
                          ),
                        ),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryBright.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: scanWindow.bottom - 220,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryBright.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppColors.primaryBright,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.scannerDetectionCombined.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _trackingBand(),
      ],
    );
  }

  /// Live scan-tracking panel: status, animated progress bar and percentage.
  Widget _trackingBand() {
    final ({IconData icon, String label, Color color, String hint}) info =
        _phaseInfo();
    return Container(
      height: 120,
      width: double.infinity,
      color: _overlayColor,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(info.icon, size: 16, color: info.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _progress),
                duration: const Duration(milliseconds: 250),
                builder: (_, double v, __) => Text(
                  '${(v * 100).round()}%',
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _progress),
              duration: const Duration(milliseconds: 250),
              builder: (_, double v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(info.color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.hint,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, String label, Color color, String hint}) _phaseInfo() {
    switch (_phase) {
      case _ScanPhase.searching:
        return (
          icon: Icons.search_rounded,
          label: LocaleKeys.scannerSearching.tr(),
          color: AppColors.primaryBright,
          hint: _zoomFactor > 0
              ? LocaleKeys.scannerZoomActive.tr()
              : LocaleKeys.scannerAlignPrompt.tr(),
        );
      case _ScanPhase.locking:
        return (
          icon: Icons.center_focus_strong_rounded,
          label: LocaleKeys.scannerLocking.tr(),
          color: AppColors.primaryBright,
          hint: LocaleKeys.scannerKeepInside.tr(),
        );
      case _ScanPhase.verifying:
        return (
          icon: Icons.verified_rounded,
          label: LocaleKeys.scannerVerifying.tr(),
          color: AppColors.warning,
          hint: LocaleKeys.scannerAlmostThere.tr(),
        );
      case _ScanPhase.locked:
        return (
          icon: Icons.check_circle_rounded,
          label: LocaleKeys.scannerLocked.tr(),
          color: AppColors.success,
          hint: LocaleKeys.scannerLaserComplete.tr(),
        );
    }
  }

  List<Widget> _buildCorners(Rect scanWindow) {
    // Brackets shift from blue → green as the lock-on progresses, giving an
    // at-a-glance "focusing on the code" cue right around the target.
    final Color color = Color.lerp(
      AppColors.primaryBright,
      AppColors.success,
      _progress,
    )!;
    return [
      _Corner(Alignment.topLeft, scanWindow, color),
      _Corner(Alignment.topRight, scanWindow, color),
      _Corner(Alignment.bottomLeft, scanWindow, color),
      _Corner(Alignment.bottomRight, scanWindow, color),
    ];
  }

  Widget _bottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleAction(
          icon: _zoomFactor > 0 ? Icons.zoom_out : Icons.zoom_in,
          onTap: _toggleZoom,
        ),
        _CircleAction(
          icon: Icons.flash_on,
          onTap: () => _controller.toggleTorch(),
        ),
        _CircleAction(
          icon: Icons.cameraswitch,
          onTap: () => _controller.switchCamera(),
        ),
      ],
    );
  }
}

class LaserGridPainter extends CustomPainter {
  LaserGridPainter({required this.animation}) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBright.withValues(
        alpha: 0.05 + (animation.value * 0.05),
      )
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LaserGridPainter oldDelegate) => true;
}

class _Corner extends StatelessWidget {
  const _Corner(this.alignment, this.scanWindow, this.color);
  final Alignment alignment;
  final Rect scanWindow;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: scanWindow.width,
        height: scanWindow.height,
        alignment: alignment,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              top: alignment.y < 0
                  ? BorderSide(color: color, width: 4)
                  : BorderSide.none,
              bottom: alignment.y > 0
                  ? BorderSide(color: color, width: 4)
                  : BorderSide.none,
              left: alignment.x < 0
                  ? BorderSide(color: color, width: 4)
                  : BorderSide.none,
              right: alignment.x > 0
                  ? BorderSide(color: color, width: 4)
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.code,
    required this.isCu,
    required this.isQr,
    required this.onDiscard,
    required this.onRegister,
  });

  final String code;
  final bool isCu;
  final bool isQr;
  final VoidCallback onDiscard;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.primary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.scannerDeviceIdentified.tr(),
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.scannerLaserComplete.tr(),
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _InfoTile(
            label: LocaleKeys.scannerScannedCode.tr(),
            value: code,
            icon: Icons.qr_code_2,
          ),
          _InfoTile(
            label: LocaleKeys.scannerDetectedAs.tr(),
            value: isCu
                ? LocaleKeys.regControlUnit.tr()
                : LocaleKeys.regBallotUnit.tr(),
            icon: Icons.settings_suggest,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(LocaleKeys.scannerDiscard.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AppGradientButton(
                  label: LocaleKeys.scannerConfirmPrefill.tr(),
                  onPressed: onRegister,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
