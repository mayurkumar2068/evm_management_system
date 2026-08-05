import 'dart:convert';

import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and shares a Hindi voter slip PDF matching the SEC slip layout
/// (logo colors, field order, notes, and footer) exactly.
abstract final class VoterSlipPdfService {
  static const String _logoAsset = 'assets/images/voter_slip_sec_icon.png';

  static pw.Font? _regular;
  static pw.Font? _bold;
  static pw.Font? _latin;
  static pw.MemoryImage? _logoImage;

  static Future<void> _ensureAssets() async {
    if (_regular != null &&
        _bold != null &&
        _latin != null &&
        _logoImage != null) {
      return;
    }
    final ByteData regular = await rootBundle.load(
      'assets/fonts/NotoSansDevanagari-Regular.ttf',
    );
    final ByteData bold = await rootBundle.load(
      'assets/fonts/NotoSansDevanagari-Bold.ttf',
    );
    final ByteData logo = await rootBundle.load(_logoAsset);
    _regular = pw.Font.ttf(regular);
    _bold = pw.Font.ttf(bold);
    _latin = await PdfGoogleFonts.notoSansRegular();
    _logoImage = pw.MemoryImage(logo.buffer.asUint8List());
  }

  static List<pw.Font> get _fallback =>
      _latin == null ? const <pw.Font>[] : <pw.Font>[_latin!];

  static Uint8List? _decodePhoto(String? base64Photo) {
    if (base64Photo == null || base64Photo.trim().isEmpty) return null;
    try {
      String raw = base64Photo.trim();
      if (raw.contains(',')) {
        raw = raw.split(',').last.trim();
      }
      raw = raw.replaceAll(RegExp(r'\s+'), '');
      // Fix missing base64 padding.
      final int mod = raw.length % 4;
      if (mod > 0) {
        raw = raw.padRight(raw.length + (4 - mod), '=');
      }
      final Uint8List bytes = base64Decode(raw);
      if (bytes.length < 64) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Official SEC icon (yellow / saffron / green) — same colors as printed slip.
  static pw.Widget _secLogoIcon() {
    return pw.Image(
      _logoImage!,
      width: 52,
      height: 42,
      fit: pw.BoxFit.contain,
    );
  }

  static String _headerTitle(VoterElector elector) {
    // Match printed SEC panchayat slip header when rural/panchayat context.
    if (elector.panchayatName.isNotEmpty ||
        elector.blockName.isNotEmpty ||
        elector.elecType.toUpperCase().contains('R')) {
      return 'त्रि-स्तरीय पंचायतों का निर्वाचन';
    }
    return elector.electionTitle;
  }

  /// Generates PDF bytes for [elector].
  static Future<Uint8List> buildPdf({
    required VoterElector elector,
    String? photoBase64,
  }) async {
    await _ensureAssets();
    final pw.Font regular = _regular!;
    final pw.Font bold = _bold!;
    final List<pw.Font> fallback = _fallback;
    final Uint8List? photoBytes = _decodePhoto(photoBase64);
    assert(() {
      // ignore: avoid_print
      print(
        '[VoterSlip] photoBase64Len=${photoBase64?.length ?? 0} '
        'decodedBytes=${photoBytes?.length ?? 0}',
      );
      return true;
    }());

    final String wardNo = elector.wardNo.isEmpty ? '—' : elector.wardNo;
    final String serNo = elector.serNo.isEmpty ? '—' : elector.serNo;
    final String name = elector.name.isEmpty ? '—' : elector.name;
    final String relative = elector.rlnName.isEmpty ? '—' : elector.rlnName;
    final String gender = elector.gender.isEmpty ? '—' : elector.gender;
    final String bodyName =
        elector.slipBodyName.isEmpty ? '—' : elector.slipBodyName;
    final String address =
        elector.slipAddressLine.isEmpty ? '—' : elector.slipAddressLine;

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: regular,
          bold: bold,
          fontFallback: fallback,
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: <pw.Widget>[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    _secLogoIcon(),
                    pw.Expanded(
                      child: pw.Column(
                        children: <pw.Widget>[
                          pw.Text(
                            _headerTitle(elector),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: regular,
                              fontFallback: fallback,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'वोटर स्लिप',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: bold,
                              fontFallback: fallback,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 52),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: <pw.Widget>[
                          _line(
                            'पंचायत का नाम : ',
                            bodyName,
                            regular,
                            bold,
                            fallback,
                          ),
                          pw.SizedBox(height: 7),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: <pw.Widget>[
                              pw.Expanded(
                                child: _line(
                                  'वार्ड क्रमांक : ',
                                  wardNo,
                                  regular,
                                  bold,
                                  fallback,
                                ),
                              ),
                              pw.Expanded(
                                child: _line(
                                  'मतदाता क्र. ',
                                  serNo,
                                  regular,
                                  bold,
                                  fallback,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 7),
                          _line(
                            'मतदाता का नाम : ',
                            name,
                            regular,
                            bold,
                            fallback,
                            valueBold: true,
                          ),
                          pw.SizedBox(height: 7),
                          _line(
                            '${elector.relativeLabel} : ',
                            relative,
                            regular,
                            bold,
                            fallback,
                            valueBold: true,
                          ),
                          pw.SizedBox(height: 7),
                          _line(
                            'लिंग : ',
                            gender,
                            regular,
                            bold,
                            fallback,
                          ),
                          pw.SizedBox(height: 7),
                          _line(
                            'पता : ',
                            address,
                            regular,
                            bold,
                            fallback,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Container(
                      width: 88,
                      height: 108,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey600,
                          width: 0.6,
                        ),
                      ),
                      alignment: pw.Alignment.center,
                      child: photoBytes == null
                          ? pw.Text(
                              'फोटो',
                              style: pw.TextStyle(
                                font: regular,
                                fontFallback: fallback,
                                fontSize: 9,
                                color: PdfColors.grey500,
                              ),
                            )
                          : pw.Image(
                              pw.MemoryImage(photoBytes),
                              fit: pw.BoxFit.cover,
                              width: 88,
                              height: 108,
                            ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                _line(
                  'मतदान केन्द्र क्रमांक, नाम एवं पता : ',
                  elector.boothLine,
                  regular,
                  bold,
                  fallback,
                ),

                pw.SizedBox(height: 14),
                pw.Text(
                  'नोट 1: इस वोटर स्लिप को पहचान दस्तावेज के रूप में भी प्रस्तुत किया जा सकता है।',
                  style: pw.TextStyle(
                    font: regular,
                    fontFallback: fallback,
                    fontSize: 9,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'नोट 2: यदि वोटर स्लिप पर फोटोग्राफ उपलब्ध नहीं है अथवा त्रुटिपूर्ण है '
                  'अथवा अन्य प्रविष्टियां त्रुटिपूर्ण है तो भी मतदाता को राज्य निर्वाचन आयोग '
                  'द्वारा जारी वैकल्पिक दस्तावेजों के आधार पर मतदान करने की अनुमति होगी।',
                  style: pw.TextStyle(
                    font: regular,
                    fontFallback: fallback,
                    fontSize: 9,
                  ),
                ),

                pw.SizedBox(height: 22),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Expanded(
                      child: pw.Text(
                        'दिनांक : ..................',
                        style: pw.TextStyle(
                          font: regular,
                          fontFallback: fallback,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: <pw.Widget>[
                        pw.Text(
                          'हस्ताक्षर एवं सील',
                          style: pw.TextStyle(
                            font: regular,
                            fontFallback: fallback,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'रिटर्निंग अधिकारी / सहायक रिटर्निंग अधिकारी.',
                          style: pw.TextStyle(
                            font: regular,
                            fontFallback: fallback,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _line(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold,
    List<pw.Font> fallback, {
    bool valueBold = false,
  }) {
    return pw.RichText(
      text: pw.TextSpan(
        children: <pw.TextSpan>[
          pw.TextSpan(
            text: label,
            style: pw.TextStyle(
              font: regular,
              fontFallback: fallback,
              fontSize: 11,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              font: valueBold ? bold : regular,
              fontFallback: fallback,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens an in-app PDF preview (does not leave the app via share sheet).
  static Future<void> shareSlip({
    required VoterElector elector,
    String? photoBase64,
  }) =>
      previewSlip(elector: elector, photoBase64: photoBase64);

  /// In-app preview with optional print / share from the preview toolbar.
  static Future<void> previewSlip({
    required VoterElector elector,
    String? photoBase64,
  }) async {
    final Uint8List bytes = await buildPdf(
      elector: elector,
      photoBase64: photoBase64,
    );
    final String safeName = elector.epicNo.isNotEmpty
        ? elector.epicNo
        : (elector.name.isEmpty ? 'voter' : elector.name);
    final String filename = 'voter_slip_$safeName.pdf'.replaceAll(
      RegExp(r'[^\w.\-]+'),
      '_',
    );

    await Get.to<void>(
      () => _VoterSlipPreviewPage(bytes: bytes, filename: filename),
      transition: Transition.cupertino,
    );
  }
}

/// Full-screen in-app PDF preview — stays inside the Flutter app.
class _VoterSlipPreviewPage extends StatelessWidget {
  const _VoterSlipPreviewPage({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;

  Future<void> _print() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: filename,
    );
  }

  Future<void> _share() async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'वोटर स्लिप',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.slate800,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.slate800,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back<void>(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PdfPreview(
              build: (_) async => bytes,
              pdfFileName: filename,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              actions: const <Widget>[],
              initialPageFormat: PdfPageFormat.a4,
              scrollViewDecoration: const BoxDecoration(
                color: AppColors.slate50,
              ),
              pdfPreviewPageDecoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            elevation: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.slate200),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _print,
                      icon: const Icon(Icons.print_outlined, size: 20),
                      label: Text(
                        'प्रिंट',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: Text(
                        'शेयर',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
