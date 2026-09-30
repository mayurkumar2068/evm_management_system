import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:MPSECNET/core/utils/string_extensions.dart';
import 'package:MPSECNET/features/grievance/di/grievance_module.dart';
import 'package:MPSECNET/features/grievance/presentation/controllers/grievance_controller.dart';
import 'package:MPSECNET/features/grievance/presentation/screens/grievance_form_screen.dart';
import 'package:MPSECNET/features/service_auth/presentation/widgets/service_auth_chrome.dart';
import 'package:MPSECNET/localization/locale_keys.dart';
import 'package:MPSECNET/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

class GrievanceOtpScreen extends StatefulWidget {
  const GrievanceOtpScreen({super.key});

  @override
  State<GrievanceOtpScreen> createState() => _GrievanceOtpScreenState();
}

class _GrievanceOtpScreenState extends State<GrievanceOtpScreen> {
  static const int _resendCooldownSeconds = 30;

  late final GrievanceController _controller;
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  int _resendRemaining = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _controller = GrievanceModule.ensureController();
    _controller.reset();
    _controller.mobileController.addListener(_onMobileChanged);
  }

  @override
  void dispose() {
    _controller.mobileController.removeListener(_onMobileChanged);
    _mobileFocus.dispose();
    _otpFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onMobileChanged() {
    if (_controller.otpSent.value) {
      _resendTimer?.cancel();
      setState(() => _resendRemaining = 0);
      _controller.resetOtpState();
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendRemaining = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendRemaining <= 1) {
          _resendRemaining = 0;
          timer.cancel();
        } else {
          _resendRemaining -= 1;
        }
      });
    });
  }

  void _changeMobileNumber() {
    if (_controller.busy.value) return;
    _resendTimer?.cancel();
    setState(() => _resendRemaining = 0);
    _controller.resetOtpState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mobileFocus.requestFocus();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_controller.otpSent.value) {
      final bool ok = await _controller.verifyOtp();
      if (ok && mounted) {
        await Get.off<void>(() => const GrievanceFormScreen());
      }
    } else {
      final bool ok = await _controller.sendOtp();
      if (ok && mounted) {
        _startResendCooldown();
        _otpFocus.requestFocus();
      }
    }
  }

  String get _maskedMobile => _controller.mobileController.text.trim().masked;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: <Widget>[
          const ServiceAuthBackdrop(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, top + 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Obx(
                      () => IconButton(
                        onPressed: _controller.busy.value
                            ? null
                            : () => Get.back<void>(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: context.appOnSurface,
                        style: IconButton.styleFrom(
                          backgroundColor: context.appSurface.withValues(
                            alpha: 0.9,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ServiceAuthHero(
                    title: LocaleKeys.grievanceTitle.tr(),
                    subtitle: LocaleKeys.grievanceOtpSubtitle.tr(),
                  ),
                  const SizedBox(height: 20),
                  ServiceAuthFormCard(
                    child: Obx(() {
                      final bool busy = _controller.busy.value;
                      final bool otpSent = _controller.otpSent.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          ServiceAuthSoftField(
                            controller: _controller.mobileController,
                            focusNode: _mobileFocus,
                            label: LocaleKeys.grievanceMobileNo.tr(),
                            hint: LocaleKeys.grievanceMobileNoHint.tr(),
                            icon: Icons.phone_iphone_rounded,
                            enabled: !busy && !otpSent,
                            keyboardType: TextInputType.phone,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            textInputAction: otpSent
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onSubmitted: (_) =>
                                otpSent ? _otpFocus.requestFocus() : _submit(),
                          ),
                          if (otpSent) ...<Widget>[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: busy ? null : _changeMobileNumber,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  LocaleKeys.grievanceChangeMobile.tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ServiceAuthSoftField(
                              controller: _controller.otpController,
                              focusNode: _otpFocus,
                              label: LocaleKeys.grievanceOtp.tr(),
                              hint: LocaleKeys.grievanceOtpHint.tr(),
                              icon: Icons.sms_outlined,
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (!busy && _resendRemaining <= 0)
                                    ? _submitResend
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _resendRemaining > 0
                                      ? LocaleKeys.grievanceResendOtpIn.tr(
                                          args: <String>['$_resendRemaining'],
                                        )
                                      : LocaleKeys.grievanceResendOtpButton
                                            .tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: (!busy && _resendRemaining <= 0)
                                        ? AppColors.primary
                                        : context.appMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_controller.error.value != null) ...<Widget>[
                            const SizedBox(height: 14),
                            AppStatusBanner(
                              message: _controller.error.value!,
                              tone: StatusTone.error,
                              icon: Icons.error_outline_rounded,
                            ),
                          ],
                          const SizedBox(height: 16),
                          ServiceAuthHintStrip(
                            text: otpSent
                                ? LocaleKeys.grievanceOtpSentHint.tr(
                                    args: <String>[_maskedMobile],
                                  )
                                : LocaleKeys.grievanceHintStrip.tr(),
                          ),
                          const SizedBox(height: 20),
                          ServiceAuthSubmitButton(
                            busy: busy,
                            onPressed: _submit,
                            text: otpSent
                                ? LocaleKeys.grievanceVerifyOtpButton.tr()
                                : LocaleKeys.grievanceSendOtpButton.tr(),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResend() async {
    final bool ok = await _controller.sendOtp();
    if (ok && mounted) _startResendCooldown();
  }
}
