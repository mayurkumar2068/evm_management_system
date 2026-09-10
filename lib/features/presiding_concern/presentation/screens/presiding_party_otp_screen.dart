import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_party_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/controllers/presiding_party_controller.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

class PresidingPartyOtpScreen extends StatefulWidget {
  const PresidingPartyOtpScreen({super.key});

  @override
  State<PresidingPartyOtpScreen> createState() =>
      _PresidingPartyOtpScreenState();
}

class _PresidingPartyOtpScreenState extends State<PresidingPartyOtpScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  late final PoPartyRemoteDatasource _api;

  bool _busy = false;
  bool _sending = false;
  String? _error;
  String? _info;

  PoPartyDetails? get _payload {
    final Object? args = Get.arguments;
    if (args is PoPartyDetails) return args;
    return null;
  }

  String get _mobile {
    final PoPartyDetails? payload = _payload;
    if (payload != null) return payload.p1MobileNo;
    final Object? args = Get.arguments;
    if (args is Map && args['mobile'] != null) {
      return args['mobile'].toString();
    }
    if (args is String) return args;
    return '';
  }

  @override
  void initState() {
    super.initState();
    _api = PoPartyRemoteDatasource(AppServices.config);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendOtp(isResend: false);
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp({required bool isResend}) async {
    final String mobile = _mobile.trim();
    if (mobile.isEmpty) {
      setState(() {
        _error = LocaleKeys.presidingPartyP1MobileRequired.tr();
        _info = null;
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    try {
      await _api.sendOtp(mobile);
      if (!mounted) return;
      final String msg = isResend
          ? LocaleKeys.presidingPartyOtpResent.tr(args: <String>[mobile.masked])
          : LocaleKeys.presidingPartyOtpSent.tr(args: <String>[mobile.masked]);
      setState(() {
        _sending = false;
        _info = msg;
      });
    } on PoApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.isUnauthorized
            ? LocaleKeys.presidingPartySessionMissing.tr()
            : (e.message.trim().isEmpty
                  ? LocaleKeys.presidingPartyOtpSendFailed.tr()
                  : e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = LocaleKeys.presidingPartyOtpSendFailed.tr();
      });
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final String otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = LocaleKeys.presidingPartyOtpRequired.tr());
      return;
    }
    final PoPartyDetails? payload = _payload;
    if (payload == null || payload.poUserId.trim().isEmpty) {
      setState(() => _error = LocaleKeys.presidingPartySessionMissing.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _api.savePartyDetails(payload);
      if (!mounted) return;
      await Get.find<PresidingPartyController>().markComplete();
      if (!mounted) return;
      setState(() => _busy = false);
      Get.back<dynamic>(result: true);
    } on PoApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.isUnauthorized
            ? LocaleKeys.presidingPartySessionMissing.tr()
            : e.isInvalidOtp
            ? LocaleKeys.presidingPartyOtpInvalid.tr()
            : (e.message.trim().isEmpty
                  ? LocaleKeys.presidingPartyOtpInvalid.tr()
                  : e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = LocaleKeys.presidingPartySaveFailed.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mobile = _mobile;
    final String masked = mobile.masked;
    final bool blocked = _busy || _sending;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: <Widget>[
          AppGradientHeader(
            centerTitle: true,
            title: LocaleKeys.presidingPartyOtpTitle.tr(),
            subtitle: LocaleKeys.presidingPartyOtpSubtitle.tr(
              args: <String>[masked.isEmpty ? '—' : masked],
            ),
            leading: AppCircleBackButton(
              onTap: () {
                if (!blocked) Get.back<dynamic>(result: false);
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          LocaleKeys.presidingPartyOtpHint.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.slate600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: !blocked,
                          style: AppTextStyles.titleLarge.copyWith(
                            letterSpacing: 8,
                            fontWeight: FontWeight.w800,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            hintText: '••••••',
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onSubmitted: blocked ? null : (_) => _verify(),
                        ),
                        if (_info != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _info!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PresidingThemeButton(
                    label: LocaleKeys.presidingPartyOtpVerify.tr(),
                    onPressed: blocked ? null : _verify,
                    isLoading: _busy,
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 10),
                  PresidingThemeButton(
                    label: LocaleKeys.presidingPartyOtpResend.tr(),
                    onPressed: blocked ? null : () => _sendOtp(isResend: true),
                    isLoading: _sending,
                    outlined: true,
                    icon: Icons.sms_outlined,
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
