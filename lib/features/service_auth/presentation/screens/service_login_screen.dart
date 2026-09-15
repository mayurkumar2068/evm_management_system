import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/dashboard/presentation/utils/dashboard_webview_launcher.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:evm_management_system/features/service_auth/presentation/screens/service_self_register_screen.dart';
import 'package:evm_management_system/features/service_auth/presentation/utils/localized_auth_message.dart';
import 'package:evm_management_system/features/service_auth/presentation/widgets/service_auth_chrome.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

enum _LoginMode { password, otp }

class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({
    super.key,
    this.serviceTitle,
    this.loginKind,
    this.registrationAllowed,
  });

  final String? serviceTitle;

  final ServiceLoginKind? loginKind;

  final bool? registrationAllowed;

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  static const int _resendCooldownSeconds = 30;

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  _LoginMode _loginMode = _LoginMode.otp;
  bool _otpSent = false;
  int _resendRemaining = 0;
  Timer? _resendTimer;

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isPoLogin {
    if (widget.loginKind != null) {
      return widget.loginKind == ServiceLoginKind.presiding;
    }
    return widget.serviceTitle == LocaleKeys.servicePresidingTitle.tr();
  }

  bool get _isOtpMode => !_isPoLogin && _loginMode == _LoginMode.otp;

  String get _maskedMobile {
    final String mobile = _mobileCtrl.text.trim();
    if (mobile.length <= 4) return mobile;
    return '${'•' * (mobile.length - 4)}${mobile.substring(mobile.length - 4)}';
  }

  String get _submitLabel {
    if (_isOtpMode) {
      return _otpSent
          ? LocaleKeys.serviceAuthVerifyOtpButton.tr()
          : LocaleKeys.serviceAuthSendOtpButton.tr();
    }
    return LocaleKeys.serviceAuthSignInButton.tr();
  }

  bool get _showRegisterOption => widget.registrationAllowed == true;

  Future<void> _openRegister() async {
    if (_busy) return;
    final String url = _isPoLogin
        ? AppServices.config.poSelfRegisterUrl.trim()
        : AppServices.config.psSelfRegisterUrl.trim();

    if (url.isNotEmpty) {
      await Get.toNamed<dynamic>(
        AppRoute.webView.path,
        arguments: DashboardWebViewLauncher.args(
          title: LocaleKeys.serviceAuthRegisterTitle.tr(),
          url: url,
          openAsExternalPortal: true,
        ),
      );
      return;
    }

    await Get.to<void>(
      () => ServiceSelfRegisterScreen(isPresidingOfficer: _isPoLogin),
    );
  }

  @override
  void initState() {
    super.initState();

    _loginMode = _isPoLogin ? _LoginMode.password : _LoginMode.otp;
    _userFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _mobileFocus.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));

    _mobileCtrl.addListener(() {
      if (_otpSent) {
        _resendTimer?.cancel();
        setState(() {
          _otpSent = false;
          _resendRemaining = 0;
          _otpCtrl.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    _mobileFocus.dispose();
    _otpFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _changeMobileNumber() {
    if (_busy) return;
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _resendRemaining = 0;
      _otpCtrl.clear();
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mobileFocus.requestFocus();
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendRemaining = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _submit() async {
    if (_isOtpMode) {
      if (_otpSent) {
        await _verifyOtp();
      } else {
        await _sendOtp();
      }
      return;
    }
    await _submitPassword();
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final String mobileNo = _mobileCtrl.text.trim();

    if (mobileNo.isEmpty) {
      setState(() => _error = LocaleKeys.serviceAuthMobileNoRequired.tr());
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobileNo)) {
      setState(() => _error = LocaleKeys.serviceAuthMobileNoInvalid.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final String apiMessage = await AppServices.serviceAuth
          .sendSurveyLoginOtp(mobileNo: mobileNo);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpSent = true;
        _error = null;
      });
      _startResendCooldown();
      _otpFocus.requestFocus();
      AppSnackbar.success(context, localizedAuthMessage(apiMessage));
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpSent = false;
        _otpCtrl.clear();
        _resendRemaining = 0;
        _error = localizedAuthMessage(e.message);
      });
      _resendTimer?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpSent = false;
        _otpCtrl.clear();
        _resendRemaining = 0;
        _error = LocaleKeys.serviceAuthGenericError.tr();
      });
      _resendTimer?.cancel();
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final String mobileNo = _mobileCtrl.text.trim();
    final String otp = _otpCtrl.text.trim();

    if (otp.isEmpty) {
      setState(() => _error = LocaleKeys.serviceAuthOtpRequired.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ServiceSession session = await AppServices.serviceAuth
          .signInSurveyUserWithOtp(mobileNo: mobileNo, otp: otp);
      if (!mounted) return;
      Get.back<dynamic>(result: session);
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = localizedAuthMessage(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = LocaleKeys.serviceAuthGenericError.tr();
      });
    }
  }

  Future<void> _submitPassword() async {
    FocusScope.of(context).unfocus();
    final String userId = _userCtrl.text.trim();
    final String password = _passCtrl.text;

    if (userId.isEmpty) {
      setState(
        () => _error = _isPoLogin
            ? LocaleKeys.serviceAuthUserIdRequired.tr()
            : LocaleKeys.serviceAuthUsernameRequired.tr(),
      );
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = LocaleKeys.serviceAuthPasswordRequired.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ServiceSession session;
      if (_isPoLogin) {
        session = await AppServices.serviceAuth.signInPresidingOfficer(
          userId: userId,
          password: password,
        );
      } else {
        session = await AppServices.serviceAuth.signInSurveyUser(
          userName: userId,
          password: password,
        );
      }

      if (!mounted) return;
      Get.back<dynamic>(result: session);
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = localizedAuthMessage(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = LocaleKeys.serviceAuthGenericError.tr();
      });
    }
  }

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
                    child: IconButton(
                      onPressed: _busy ? null : () => Get.back<void>(),
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
                  const SizedBox(height: 10),
                  ServiceAuthHero(
                    title:
                        widget.serviceTitle ??
                        LocaleKeys.serviceAuthSignInButton.tr(),
                    subtitle: LocaleKeys.serviceAuthSubtitleDefault.tr(),
                  ),
                  const SizedBox(height: 20),
                  ServiceAuthFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_isOtpMode) ...<Widget>[
                          ServiceAuthSoftField(
                            controller: _mobileCtrl,
                            focusNode: _mobileFocus,
                            label: LocaleKeys.serviceAuthMobileNo.tr(),
                            hint: LocaleKeys.serviceAuthMobileNoHint.tr(),
                            icon: Icons.phone_iphone_rounded,
                            enabled: !_busy && !_otpSent,
                            keyboardType: TextInputType.phone,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            textInputAction: _otpSent
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onSubmitted: (_) =>
                                _otpSent ? _otpFocus.requestFocus() : _submit(),
                          ),
                          if (_otpSent) ...<Widget>[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _changeMobileNumber,
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
                                  LocaleKeys.serviceAuthChangeMobile.tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ServiceAuthSoftField(
                              controller: _otpCtrl,
                              focusNode: _otpFocus,
                              label: LocaleKeys.serviceAuthOtp.tr(),
                              hint: LocaleKeys.serviceAuthOtpHint.tr(),
                              icon: Icons.sms_outlined,
                              enabled: !_busy,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 10),
                            _ResendOtpRow(
                              remainingSeconds: _resendRemaining,
                              busy: _busy,
                              onResend: _sendOtp,
                            ),
                          ],
                        ] else ...<Widget>[
                          ServiceAuthSoftField(
                            controller: _userCtrl,
                            focusNode: _userFocus,
                            label: _isPoLogin
                                ? LocaleKeys.serviceAuthUserId.tr()
                                : LocaleKeys.serviceAuthUsername.tr(),
                            hint: _isPoLogin
                                ? LocaleKeys.serviceAuthUserIdHint.tr()
                                : LocaleKeys.serviceAuthUsernameHint.tr(),
                            icon: Icons.person_outline_rounded,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passFocus.requestFocus(),
                          ),
                          const SizedBox(height: 14),
                          ServiceAuthSoftField(
                            controller: _passCtrl,
                            focusNode: _passFocus,
                            label: LocaleKeys.serviceAuthPassword.tr(),
                            hint: LocaleKeys.serviceAuthPasswordHint.tr(),
                            icon: Icons.lock_outline_rounded,
                            enabled: !_busy,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.slate400,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 14),
                          AppStatusBanner(
                            message: _error!,
                            tone: StatusTone.error,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ServiceAuthHintStrip(
                          text: _isOtpMode && _otpSent
                              ? LocaleKeys.serviceAuthOtpSentHint.tr(
                                  args: <String>[_maskedMobile],
                                )
                              : LocaleKeys.serviceAuthHintStrip.tr(),
                        ),
                        const SizedBox(height: 20),
                        ServiceAuthSubmitButton(
                          busy: _busy,
                          onPressed: _submit,
                          text: _submitLabel,
                        ),
                        if (_showRegisterOption) ...<Widget>[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  LocaleKeys.serviceAuthNoAccount.tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _busy ? null : _openRegister,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  LocaleKeys.serviceAuthRegisterButton.tr(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

class _ResendOtpRow extends StatelessWidget {
  const _ResendOtpRow({
    required this.remainingSeconds,
    required this.busy,
    required this.onResend,
  });

  final int remainingSeconds;
  final bool busy;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final bool canResend = !busy && remainingSeconds <= 0;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: canResend ? onResend : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          remainingSeconds > 0
              ? LocaleKeys.serviceAuthResendOtpIn.tr(
                  args: <String>['$remainingSeconds'],
                )
              : LocaleKeys.serviceAuthResendOtpButton.tr(),
          style: AppTextStyles.caption.copyWith(
            color: canResend ? AppColors.primary : context.appMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
