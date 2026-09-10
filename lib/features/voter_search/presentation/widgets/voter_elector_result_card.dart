import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/presentation/controllers/voter_search_controller.dart';
import 'package:evm_management_system/features/voter_search/presentation/services/voter_slip_pdf_service.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class VoterElectorResultCard extends StatefulWidget {
  const VoterElectorResultCard({required this.elector, super.key});

  final VoterElector elector;

  @override
  State<VoterElectorResultCard> createState() => _VoterElectorResultCardState();
}

class _VoterElectorResultCardState extends State<VoterElectorResultCard> {
  bool _generating = false;

  Future<void> _generateSlip() async {
    if (_generating) return;
    setState(() => _generating = true);
    final VoterSearchController controller = Get.find<VoterSearchController>();
    try {
      final String? photo = await controller.loadPhoto(
        widget.elector,
        forceRefresh: false,
      );
      if (!mounted) return;
      await VoterSlipPdfService.previewSlip(
        elector: widget.elector,
        photoBase64: photo,
      );
    } catch (e) {
      AppLogger.d('[VoterSlip] Generation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleKeys.voterSearchSlipFailed.tr())),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _v(String value) => value.trim().isEmpty ? '—' : value.trim();

  @override
  Widget build(BuildContext context) {
    final VoterElector e = widget.elector;
    final bool urban = e.isUrban;
    final VoterSearchController controller = Get.find<VoterSearchController>();

    final List<_Field> personal = <_Field>[
      _Field(LocaleKeys.voterSearchRelativeNameTable.tr(), _v(e.rlnName)),
      _Field(LocaleKeys.voterSearchHouseNo.tr(), _v(e.houseNo)),
      _Field(LocaleKeys.voterSearchVoterNo.tr(), _v(e.serNo)),
      if (e.mohallaNo.isNotEmpty)
        _Field(LocaleKeys.voterSearchMohallaNo.tr(), e.mohallaNo),
      if (e.partNo.isNotEmpty)
        _Field(LocaleKeys.voterSearchPartNo.tr(), e.partNo),
      if (e.epicNo.isNotEmpty)
        _Field(LocaleKeys.voterSearchEpicNo.tr(), e.epicNo),
    ];

    final List<_Field> area = urban
        ? <_Field>[
            if (e.urbanWardNo.isNotEmpty)
              _Field(LocaleKeys.voterSearchUrbanWardNo.tr(), e.urbanWardNo),
            if (e.wardName.isNotEmpty)
              _Field(LocaleKeys.voterSearchWardName.tr(), e.wardName),
            if (e.ubName.isNotEmpty)
              _Field(LocaleKeys.voterSearchUrbanBodyName.tr(), e.ubName),
          ]
        : <_Field>[
            if (e.ruralWardNo.isNotEmpty)
              _Field(LocaleKeys.voterSearchRuralWardNo.tr(), e.ruralWardNo),
            if (e.villName.isNotEmpty)
              _Field(LocaleKeys.voterSearchVillageName.tr(), e.villName),
            if (e.panchayatName.isNotEmpty)
              _Field(LocaleKeys.voterSearchPanchayatName.tr(), e.panchayatName),
            if (e.blockName.isNotEmpty)
              _Field(LocaleKeys.voterSearchBlockName.tr(), e.blockName),
          ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CardHeader(
            name: _v(e.name),
            isUrban: urban,
            gender: e.gender,
            age: e.age,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _FieldBlock(fields: personal),
                if (area.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _SectionTitle(
                    icon: Icons.home_outlined,
                    title: LocaleKeys.voterSearchAddress.tr(),
                  ),
                  _FieldBlock(fields: area),
                ],
                if (e.psName.isNotEmpty || e.psNo.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _SectionTitle(
                    icon: Icons.how_to_vote_outlined,
                    title: LocaleKeys.voterSearchBoothFullLabel.tr(),
                  ),
                  _BoothBox(line: e.boothLine),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generateSlip,
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.image_outlined, size: 20),
                    label: Text(
                      _generating
                          ? LocaleKeys.voterSearchSlipGenerating.tr()
                          : LocaleKeys.voterSearchGenerateSlip.tr(),
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: controller.backToSearch,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(LocaleKeys.voterSearchBackToSearch.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field {
  const _Field(this.label, this.value);
  final String label;
  final String value;
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.name,
    required this.isUrban,
    required this.gender,
    required this.age,
  });

  final String name;
  final bool isUrban;
  final String gender;
  final String age;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '${LocaleKeys.voterSearchElectorName.tr()} - ',
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate500,
                    height: 1.35,
                  ),
                ),
                TextSpan(
                  text: name,
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _Chip(
                label: isUrban
                    ? LocaleKeys.voterSearchUrban.tr()
                    : LocaleKeys.voterSearchRural.tr(),
                color: isUrban ? AppColors.primary : AppColors.greenDark,
                bg: isUrban
                    ? AppColors.primaryLight
                    : AppColors.greenExtraLight,
              ),
              if (gender.trim().isNotEmpty)
                _Chip(
                  label: gender,
                  color: AppColors.slate700,
                  bg: AppColors.slate100,
                ),
              if (age.trim().isNotEmpty)
                _Chip(
                  label: '${LocaleKeys.voterSearchAge.tr()}: $age',
                  color: AppColors.slate700,
                  bg: AppColors.slate100,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.fields});

  final List<_Field> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < fields.length; i++) ...<Widget>[
            _DetailRow(label: fields[i].label, value: fields[i].value),
            if (i != fields.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.slate200),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate800,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoothBox extends StatelessWidget {
  const _BoothBox({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        line,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.slate800,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}
