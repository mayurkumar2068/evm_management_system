import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_party_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/controllers/presiding_party_controller.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Polling-party details form (P1–P4) used in bottom sheet and full screen.
class PresidingPartyDetailsForm extends StatefulWidget {
  const PresidingPartyDetailsForm({
    this.onCompleted,
    this.compactHeader = false,
    super.key,
  });

  final VoidCallback? onCompleted;

  /// When true (bottom sheet), subtitle is centered under the sheet title.
  final bool compactHeader;

  @override
  State<PresidingPartyDetailsForm> createState() =>
      _PresidingPartyDetailsFormState();
}

class _PresidingPartyDetailsFormState extends State<PresidingPartyDetailsForm> {
  final TextEditingController _partyNoCtrl = TextEditingController(text: '1');
  final TextEditingController _p1Name = TextEditingController();
  final TextEditingController _p1Mobile = TextEditingController();
  final TextEditingController _p2Name = TextEditingController();
  final TextEditingController _p2Mobile = TextEditingController();
  final TextEditingController _p3Name = TextEditingController();
  final TextEditingController _p3Mobile = TextEditingController();
  final TextEditingController _p4Name = TextEditingController();
  final TextEditingController _p4Mobile = TextEditingController();

  late final PoPartyRemoteDatasource _api;
  String? _existingId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isUpdate => PoPartyDetails.isPartyGuid(_existingId);

  @override
  void initState() {
    super.initState();
    _api = PoPartyRemoteDatasource(AppServices.config);
    _load();
  }

  @override
  void dispose() {
    _partyNoCtrl.dispose();
    _p1Name.dispose();
    _p1Mobile.dispose();
    _p2Name.dispose();
    _p2Mobile.dispose();
    _p3Name.dispose();
    _p3Mobile.dispose();
    _p4Name.dispose();
    _p4Mobile.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final String poUserId = session?.userId.trim() ?? '';
    if (poUserId.isEmpty) {
      setState(() {
        _loading = false;
        _error = LocaleKeys.presidingPartySessionMissing.tr();
      });
      return;
    }
    try {
      final PoPartyDetails? existing = await _api.fetchPartyDetails(poUserId);
      if (!mounted) return;
      if (existing != null) {
        _existingId =
            PoPartyDetails.isPartyGuid(existing.id) ? existing.id : null;
        _partyNoCtrl.text = existing.partyNo.isEmpty ? '1' : existing.partyNo;
        _p1Name.text = existing.p1Name;
        _p1Mobile.text = existing.p1MobileNo;
        _p2Name.text = existing.p2Name;
        _p2Mobile.text = existing.p2MobileNo;
        _p3Name.text = existing.p3Name;
        _p3Mobile.text = existing.p3MobileNo;
        _p4Name.text = existing.p4Name;
        _p4Mobile.text = existing.p4MobileNo;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocaleKeys.presidingPartyLoadFailed.tr();
      });
    }
  }

  String? _validate() {
    if (_p1Name.text.trim().isEmpty) {
      return LocaleKeys.presidingPartyP1NameRequired.tr();
    }
    final String mobile = _p1Mobile.text.trim();
    if (mobile.isEmpty) {
      return LocaleKeys.presidingPartyP1MobileRequired.tr();
    }
    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      return LocaleKeys.presidingPartyMobileInvalid.tr();
    }
    for (final TextEditingController c in <TextEditingController>[
      _p2Mobile,
      _p3Mobile,
      _p4Mobile,
    ]) {
      final String m = c.text.trim();
      if (m.isNotEmpty && (m.length != 10 || int.tryParse(m) == null)) {
        return LocaleKeys.presidingPartyMobileInvalid.tr();
      }
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final String? validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final String poUserId = session?.userId.trim() ?? '';
    if (poUserId.isEmpty) {
      setState(() => _error = LocaleKeys.presidingPartySessionMissing.tr());
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final PoPartyDetails payload = PoPartyDetails(
      id: _existingId,
      poUserId: poUserId,
      partyNo: _partyNoCtrl.text.trim().isEmpty ? '1' : _partyNoCtrl.text.trim(),
      p1Name: _p1Name.text.trim(),
      p1MobileNo: _p1Mobile.text.trim(),
      p2Name: _p2Name.text.trim(),
      p2MobileNo: _p2Mobile.text.trim(),
      p3Name: _p3Name.text.trim(),
      p3MobileNo: _p3Mobile.text.trim(),
      p4Name: _p4Name.text.trim(),
      p4MobileNo: _p4Mobile.text.trim(),
    );

    try {
      final String? savedId = await _api.savePartyDetails(payload);
      if (!mounted) return;
      _existingId =
          PoPartyDetails.isPartyGuid(savedId) ? savedId : _existingId;
      if (!PoPartyDetails.isPartyGuid(_existingId)) {
        _existingId = null;
      }
      setState(() => _saving = false);
      await _finishAfterSave(payload);
    } on PoPartyApiException catch (e) {
      if (!mounted) return;
      if (kBypassPoPartySaveOn404 && (e.isNotFound || e.isUnauthorized)) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.presidingPartyApiNotDeployed.tr())),
        );
        await _finishAfterSave(payload);
        return;
      }
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = LocaleKeys.presidingPartySaveFailed.tr();
      });
    }
  }

  /// Marks party complete on successful save (fields already validated), then OTP.
  Future<void> _finishAfterSave(PoPartyDetails payload) async {
    await Get.find<PresidingPartyController>().markComplete();
    final String mobile = payload.otpMobile;
    widget.onCompleted?.call();
    await Get.toNamed<bool>(
      AppRoute.presidingPartyOtp.path,
      arguments: <String, String>{'mobile': mobile},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: AppLoader()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!widget.compactHeader) ...<Widget>[
          Text(
            LocaleKeys.presidingPartySubtitle.tr(),
            textAlign: TextAlign.start,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.slate500,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _Field(
          label: LocaleKeys.presidingPartyNo.tr(),
          controller: _partyNoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
        const SizedBox(height: 14),
        _PersonBlock(
          title: LocaleKeys.presidingPartyMemberP1.tr(),
          nameCtrl: _p1Name,
          mobileCtrl: _p1Mobile,
          nameRequired: true,
          mobileRequired: true,
        ),
        const SizedBox(height: 14),
        _PersonBlock(
          title: LocaleKeys.presidingPartyMemberP2.tr(),
          nameCtrl: _p2Name,
          mobileCtrl: _p2Mobile,
        ),
        const SizedBox(height: 14),
        _PersonBlock(
          title: LocaleKeys.presidingPartyMemberP3.tr(),
          nameCtrl: _p3Name,
          mobileCtrl: _p3Mobile,
        ),
        const SizedBox(height: 14),
        _PersonBlock(
          title: LocaleKeys.presidingPartyMemberP4.tr(),
          nameCtrl: _p4Name,
          mobileCtrl: _p4Mobile,
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppGradientButton(
          label: _isUpdate
              ? LocaleKeys.presidingPartyUpdate.tr()
              : LocaleKeys.presidingPartySaveContinue.tr(),
          onPressed: _saving ? null : _submit,
          isLoading: _saving,
          icon: _isUpdate ? Icons.update_rounded : Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}

class _PersonBlock extends StatelessWidget {
  const _PersonBlock({
    required this.title,
    required this.nameCtrl,
    required this.mobileCtrl,
    this.nameRequired = false,
    this.mobileRequired = false,
  });

  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController mobileCtrl;
  final bool nameRequired;
  final bool mobileRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8),
        _Field(
          label: nameRequired
              ? '${LocaleKeys.presidingPartyName.tr()} *'
              : LocaleKeys.presidingPartyName.tr(),
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 10),
        _Field(
          label: mobileRequired
              ? '${LocaleKeys.presidingPartyMobile.tr()} *'
              : LocaleKeys.presidingPartyMobile.tr(),
          controller: mobileCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.slate500,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.slate800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.78),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
