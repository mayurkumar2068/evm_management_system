import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/cache/app_startup_cache.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_turnout_report_view.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Captures the PO report as a Flutter widget image (app header/theme),
/// then wraps it in a PDF for save / print.
abstract final class PresidingTurnoutReportPdfService {
  static const double reportWidth = 595;
  static const double _capturePixelRatio = 3;

  static Future<void> openReport({
    required PresidingSession session,
    PresidingElectionContext? electionContext,
  }) async {
    final String stationCode = session.pollingStationCode;
    final String filename =
        'po_report_${stationCode}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Get.to<void>(
      () => _PresidingReportPreviewPage(
        session: session,
        electionContext: electionContext,
        filename: filename,
      ),
      transition: Transition.cupertino,
    );
  }

  static Future<Uint8List?> captureReportPng({
    required GlobalKey repaintKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;
    final RenderObject? obj = repaintKey.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final ui.Image image = await obj.toImage(pixelRatio: _capturePixelRatio);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return data?.buffer.asUint8List();
  }

  static Future<pw.Document> buildPdfFromPng(Uint8List pngBytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image src = frame.image;
    try {
      const PdfPageFormat format = PdfPageFormat.a4;
      const double margin = 16;
      final double contentW = format.width - margin * 2;
      final double contentH = format.height - margin * 2;
      final double pxPerPt = src.width / contentW;
      final int pageSrcH = math.max(1, (contentH * pxPerPt).floor());

      final pw.Document doc = pw.Document();
      int y = 0;
      while (y < src.height) {
        final int sliceH = math.min(pageSrcH, src.height - y);
        final Uint8List slicePng = y == 0 && sliceH == src.height
            ? pngBytes
            : await _cropPng(src, y, sliceH);
        final double slicePtH = sliceH / pxPerPt;
        doc.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(margin),
            build: (_) => pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.Image(
                pw.MemoryImage(slicePng),
                width: contentW,
                height: slicePtH,
              ),
            ),
          ),
        );
        y += sliceH;
      }
      return doc;
    } finally {
      src.dispose();
    }
  }

  static Future<Uint8List> _cropPng(ui.Image src, int y, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(0, y.toDouble(), src.width.toDouble(), height.toDouble()),
      Rect.fromLTWH(0, 0, src.width.toDouble(), height.toDouble()),
      Paint(),
    );
    final ui.Picture picture = recorder.endRecording();
    final ui.Image slice = await picture.toImage(src.width, height);
    picture.dispose();
    final ByteData? data = await slice.toByteData(
      format: ui.ImageByteFormat.png,
    );
    slice.dispose();
    if (data == null) {
      throw StateError('Failed to encode report image slice.');
    }
    return data.buffer.asUint8List();
  }
}

class _PresidingReportPreviewPage extends StatefulWidget {
  const _PresidingReportPreviewPage({
    required this.session,
    required this.filename,
    this.electionContext,
  });

  final PresidingSession session;
  final PresidingElectionContext? electionContext;
  final String filename;

  @override
  State<_PresidingReportPreviewPage> createState() =>
      _PresidingReportPreviewPageState();
}

class _PresidingReportPreviewPageState
    extends State<_PresidingReportPreviewPage> {
  final GlobalKey _reportKey = GlobalKey();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage(BrandLogo.asset), context);
    });
  }

  Future<pw.Document?> _capturePdf() async {
    final Uint8List? png =
        await PresidingTurnoutReportPdfService.captureReportPng(
          repaintKey: _reportKey,
        );
    if (png == null || png.isEmpty) return null;
    return PresidingTurnoutReportPdfService.buildPdfFromPng(png);
  }

  Future<void> _sharePdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final pw.Document? doc = await _capturePdf();
      if (!mounted) return;
      if (doc == null) {
        AppSnackbar.error(context, LocaleKeys.presidingReportFailed.tr());
        return;
      }
      final Uint8List bytes = await doc.save();
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${widget.filename}');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(
              file.path,
              mimeType: 'application/pdf',
              name: widget.filename,
            ),
          ],
          subject: LocaleKeys.presidingReportTitle.tr(),
        ),
      );
    } finally {
      await AppStartupCache.clearGeneratedExports();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final pw.Document? doc = await _capturePdf();
      if (!mounted) return;
      if (doc == null) {
        AppSnackbar.error(context, LocaleKeys.presidingReportFailed.tr());
        return;
      }
      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: widget.filename,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double previewWidth = (MediaQuery.sizeOf(context).width - 24).clamp(
      280.0,
      PresidingTurnoutReportPdfService.reportWidth,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppGradientHeader(
            leading: AppCircleBackButton(onTap: () => Get.back<void>()),
            title: LocaleKeys.presidingReportTitle.tr(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Center(
                child: RepaintBoundary(
                  key: _reportKey,
                  child: PresidingTurnoutReportView(
                    session: widget.session,
                    electionContext: widget.electionContext,
                    width: previewWidth,
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.slate200)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: PresidingThemeButton(
                      outlined: true,
                      icon: Icons.share_outlined,
                      label: LocaleKeys.presidingReportShare.tr(),
                      isLoading: _busy,
                      onPressed: _busy ? null : _sharePdf,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PresidingThemeButton(
                      icon: Icons.print_outlined,
                      label: LocaleKeys.presidingReportPrint.tr(),
                      isLoading: _busy,
                      onPressed: _busy ? null : _printPdf,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
