import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/presentation/controllers/voter_search_controller.dart';
import 'package:evm_management_system/features/voter_search/presentation/services/voter_slip_pdf_service.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Elector result card — slip-style details + photo; PDF uses the same photo.
class VoterElectorResultCard extends StatefulWidget {
  const VoterElectorResultCard({required this.elector, super.key});

  final VoterElector elector;

  @override
  State<VoterElectorResultCard> createState() => _VoterElectorResultCardState();
}

class _VoterElectorResultCardState extends State<VoterElectorResultCard> {
  bool _generating = false;
  bool _loadingPhoto = false;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPhoto());
  }

  @override
  void didUpdateWidget(covariant VoterElectorResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elector.id != widget.elector.id) {
      _photoBase64 = null;
      unawaited(_loadPhoto());
    }
  }

  Future<void> _loadPhoto() async {
    final VoterSearchController controller = Get.find<VoterSearchController>();
    final String? cached = controller.photoCache[widget.elector.id];
    if (cached != null && cached.isNotEmpty) {
      if (mounted) setState(() => _photoBase64 = cached);
      return;
    }
    if (mounted) setState(() => _loadingPhoto = true);
    try {
      final String? photo = await controller.loadPhoto(widget.elector);
      if (!mounted) return;
      setState(() {
        _photoBase64 = (photo != null && photo.isNotEmpty) ? photo : null;
        _loadingPhoto = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _generateSlip() async {
    if (_generating) return;
    setState(() {
      _generating = true;
      _loadingPhoto = true;
    });
    final VoterSearchController controller = Get.find<VoterSearchController>();
    try {
      // 1. Ensure photo is loaded from API/cache.
      final String? photo = await controller.loadPhoto(widget.elector);

      if (!mounted) return;
      setState(() {
        _photoBase64 = (photo != null && photo.isNotEmpty) ? photo : null;
        _loadingPhoto = false;
      });

      // 2. Build and preview the PDF slip with photo.
      await VoterSlipPdfService.previewSlip(
        elector: widget.elector,
        photoBase64: photo,
      );
    } catch (e) {
      debugPrint('[VoterSlip] Generation failed: $e');
      if (!mounted) return;
      setState(() => _loadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.voterSearchSlipFailed.tr())),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Uint8List? get _photoBytes {
    final String? raw = _photoBase64;
    if (raw == null || raw.isEmpty) return null;
    try {
      String value = raw.trim();
      if (value.contains(',')) value = value.split(',').last.trim();
      value = value.replaceAll(RegExp(r'\s+'), '');
      final int mod = value.length % 4;
      if (mod > 0) value = value.padRight(value.length + (4 - mod), '=');
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final VoterElector elector = widget.elector;
    final bool preferHindi = Get.find<VoterSearchController>().preferHindi;
    final String bodyName = elector.slipBodyName;
    final String address = elector.slipAddressLine;
    final String wardNo = elector.wardNo.isEmpty ? '—' : elector.wardNo;
    final String serNo = elector.serNo.isEmpty ? '—' : elector.serNo;
    final Uint8List? photoBytes = _photoBytes;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (bodyName.isNotEmpty)
                      _DetailRow(
                        label: LocaleKeys.voterSearchPanchayatName.tr(),
                        value: bodyName,
                      ),
                    _DetailRow(
                      label: LocaleKeys.voterSearchWardNo.tr(),
                      value: wardNo,
                      trailingLabel: LocaleKeys.voterSearchVoterNo.tr(),
                      trailingValue: serNo,
                    ),
                    _DetailRow(
                      label: LocaleKeys.voterSearchElectorName.tr(),
                      value: elector.name.isNotEmpty ? elector.name : '—',
                      valueBold: true,
                    ),
                    if (elector.rlnName.isNotEmpty)
                      _DetailRow(
                        label: elector.relativeLabelLocalized(preferHindi),
                        value: elector.rlnName,
                        valueBold: true,
                      ),
                    if (elector.gender.isNotEmpty)
                      _DetailRow(
                        label: LocaleKeys.voterSearchGender.tr(),
                        value: elector.gender,
                      ),
                    if (address.isNotEmpty)
                      _DetailRow(
                        label: LocaleKeys.voterSearchAddress.tr(),
                        value: address,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _PhotoThumb(
                bytes: photoBytes,
                loading: _loadingPhoto && photoBytes == null,
              ),
            ],
          ),
          if (elector.psName.isNotEmpty || elector.psNo.isNotEmpty)
            _DetailRow(
              label: LocaleKeys.voterSearchBoothFullLabel.tr(),
              value: elector.boothLine,
            ),
          if (elector.epicNo.isNotEmpty || elector.age.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if (elector.epicNo.isNotEmpty)
                  _InfoChip(
                    LocaleKeys.voterSearchEpicLabel.tr(
                      args: <String>[elector.epicNo],
                    ),
                  ),
                if (elector.age.isNotEmpty)
                  _InfoChip(
                    LocaleKeys.voterSearchAgeLabel.tr(
                      args: <String>[elector.age],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generating ? null : _generateSlip,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(
                _generating
                    ? LocaleKeys.voterSearchSlipGenerating.tr()
                    : LocaleKeys.voterSearchGenerateSlip.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.bytes, required this.loading});

  final Uint8List? bytes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: loading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : bytes == null
          ? const Icon(
              Icons.person_outline_rounded,
              color: AppColors.slate300,
              size: 32,
            )
          : Image.memory(
              bytes!,
              fit: BoxFit.cover,
              width: 72,
              height: 88,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.slate300,
                size: 28,
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailingLabel,
    this.trailingValue,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final String? trailingLabel;
  final String? trailingValue;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = AppTextStyles.caption.copyWith(
      color: AppColors.slate600,
    );
    final TextStyle valueStyle = AppTextStyles.caption.copyWith(
      color: AppColors.slate800,
      fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: '$label: ', style: labelStyle),
                  TextSpan(text: value, style: valueStyle),
                ],
              ),
            ),
          ),
          if (trailingLabel != null && trailingValue != null) ...<Widget>[
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: '$trailingLabel: ', style: labelStyle),
                  TextSpan(text: trailingValue, style: valueStyle),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.slate700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
