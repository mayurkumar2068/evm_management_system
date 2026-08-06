import 'dart:io';
import 'dart:ui' as ui;

import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/presentation/widgets/voter_slip_view.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Builds / previews the SEC voter slip as a PNG image (same layout as before).
abstract final class VoterSlipPdfService {
  /// Opens in-app preview with save / share as image.
  static Future<void> previewSlip({
    required VoterElector elector,
    String? photoBase64,
  }) async {
    final String safeName = elector.epicNo.isNotEmpty
        ? elector.epicNo
        : (elector.name.isEmpty ? 'voter' : elector.name);
    final String filename = 'voter_slip_$safeName.png'.replaceAll(
      RegExp(r'[^\w.\-]+'),
      '_',
    );

    await Get.to<void>(
      () => VoterSlipPreviewPage(
        elector: elector,
        photoBase64: photoBase64,
        filename: filename,
      ),
      transition: Transition.cupertino,
    );
  }

  /// Alias kept for older call sites.
  static Future<void> shareSlip({
    required VoterElector elector,
    String? photoBase64,
  }) =>
      previewSlip(elector: elector, photoBase64: photoBase64);
}

/// Full-screen slip preview — same header/back pattern as voter search.
class VoterSlipPreviewPage extends StatefulWidget {
  const VoterSlipPreviewPage({
    required this.elector,
    required this.filename,
    this.photoBase64,
    super.key,
  });

  final VoterElector elector;
  final String? photoBase64;
  final String filename;

  @override
  State<VoterSlipPreviewPage> createState() => _VoterSlipPreviewPageState();
}

class _VoterSlipPreviewPageState extends State<VoterSlipPreviewPage> {
  final GlobalKey _slipKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _captureSlipPng() async {
    if (!mounted) return null;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final RenderObject? obj = _slipKey.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final ui.Image image = await obj.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<File?> _writePngFile() async {
    final Uint8List? png = await _captureSlipPng();
    if (png == null || png.isEmpty) return null;
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/${widget.filename}');
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  Future<void> _shareImage({required String subject}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final File? file = await _writePngFile();
      if (file == null || !mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(file.path, mimeType: 'image/png', name: widget.filename),
          ],
          subject: subject,
          text: 'वोटर स्लिप',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double maxSlipWidth =
        (MediaQuery.sizeOf(context).width - 32).clamp(260.0, 380.0);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppGradientHeader(
            leading: AppCircleBackButton(onTap: () => Get.back<void>()),
            title: 'वोटर स्लिप',
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Center(
                child: RepaintBoundary(
                  key: _slipKey,
                  child: VoterSlipView(
                    elector: widget.elector,
                    photoBase64: widget.photoBase64,
                    width: maxSlipWidth,
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
                border: Border(
                  top: BorderSide(color: AppColors.slate200),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _shareImage(subject: 'वोटर स्लिप सेव'),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined, size: 20),
                      label: Text(
                        'सेव करें',
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
                      onPressed: _busy
                          ? null
                          : () => _shareImage(subject: 'वोटर स्लिप'),
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
