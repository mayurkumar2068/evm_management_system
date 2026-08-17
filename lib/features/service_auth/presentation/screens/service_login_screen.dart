import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Which credential type the Booth/PS Survey login form is using.
/// Presiding Officer login always stays on [password] — OTP is Survey-only.
enum _LoginMode { password, otp }

/// Officer login gate shown before opening any service tile.
/// Soft Booth-Survey look: hero strip + label-above fields + pill CTA.
class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key, this.serviceTitle});

  /// Name of the tile the user tapped — shown as context in the header.
  final String? serviceTitle;

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  static const int _resendCooldownSeconds = 30;

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  // Booth/PS Survey OTP login — unused (and never rendered) for PO login.
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

  bool get _isPoLogin =>
      widget.serviceTitle == LocaleKeys.servicePresidingTitle.tr();

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

  String _localizedAuthMessage(String message) {
    if (message.startsWith('auth.') ||
        message.startsWith('error.') ||
        message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  @override
  void initState() {
    super.initState();
    // Survey/Booth: OTP-only UI. PO keeps username/password.
    _loginMode = _isPoLogin ? _LoginMode.password : _LoginMode.otp;
    _userFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _mobileFocus.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));
    // Editing the number after OTP was sent invalidates it — start over.
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
      await AppServices.serviceAuth.sendSurveyLoginOtp(mobileNo: mobileNo);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpSent = true;
      });
      _startResendCooldown();
      _otpFocus.requestFocus();
      AppSnackbar.success(context, LocaleKeys.serviceAuthOtpSentSuccess.tr());
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _localizedAuthMessage(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = LocaleKeys.serviceAuthGenericError.tr();
      });
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
        _error = _localizedAuthMessage(e.message);
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
      setState(
        () => _error = LocaleKeys.serviceAuthPasswordRequired.tr(),
      );
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
        _error = _localizedAuthMessage(e.message);
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
          const _SoftBackdrop(),
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
                  _LoginHero(
                    title: widget.serviceTitle ??
                        LocaleKeys.serviceAuthSignInButton.tr(),
                    subtitle: LocaleKeys.serviceAuthSubtitleDefault.tr(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: AppRadius.brXl,
                      border: Border.all(color: context.appOutline),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: context.isAppDark ? 0.18 : 0.08,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_isOtpMode) ...<Widget>[
                          _SoftField(
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
                            onSubmitted: (_) => _otpSent
                                ? _otpFocus.requestFocus()
                                : _submit(),
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
                            _SoftField(
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
                          _SoftField(
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
                          _SoftField(
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
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 16),
                        _HintStrip(
                          text: _isOtpMode && _otpSent
                              ? LocaleKeys.serviceAuthOtpSentHint.tr(
                                  args: <String>[_maskedMobile],
                                )
                              : LocaleKeys.serviceAuthHintStrip.tr(),
                        ),
                        const SizedBox(height: 20),
                        _SubmitButton(
                          busy: _busy,
                          onPressed: _submit,
                          text: _submitLabel,
                        ),
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

class _SoftBackdrop extends StatelessWidget {
  const _SoftBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft survey-style hero: icon + title row, decorative orbs.
class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: AppRadius.brXl,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -36,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: BrandLogo(width: 40),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.35,
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

/// "OTP sent • Resend in Ns / Resend OTP" row shown under the OTP field.
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

class _HintStrip extends StatelessWidget {
  const _HintStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.primaryDark.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.busy,
    required this.onPressed,
    required this.text,
  });
  final bool busy;
  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: AppRadius.brPill,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: AppRadius.brPill,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          text,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label-above soft field — same chrome for focused / unfocused (no floating label).
class _SoftField extends StatelessWidget {
  const _SoftField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  /// Overrides the default whitespace-denying formatter (used by the
  /// mobile-number / OTP fields, which need digits-only + max length).
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final bool focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: focused ? AppColors.primaryBright : context.appMutedStrong,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: focused ? context.appSurface : context.appChip,
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: focused ? AppColors.primary : context.appOutline,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscure,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            inputFormatters: inputFormatters ??
                (obscure
                    ? null
                    : <TextInputFormatter>[
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ]),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: context.appMuted,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: focused ? AppColors.primary : context.appMuted,
                size: 20,
              ),
              suffixIcon: suffix,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
