import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

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
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isPoLogin =>
      widget.serviceTitle == LocaleKeys.servicePresidingTitle.tr();

  /// App is Hindi-first — keep officer-facing copy in Hindi.
  String _t(String hi, String en) => hi;

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
    _userFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final String userId = _userCtrl.text.trim();
    final String password = _passCtrl.text;

    if (userId.isEmpty) {
      setState(
        () => _error = _isPoLogin
            ? _t('यूज़र आईडी दर्ज करें।', 'Enter User ID.')
            : _t('यूज़रनेम दर्ज करें।', 'Enter username.'),
      );
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = _t('पासवर्ड दर्ज करें।', 'Enter the password.'));
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
        _error = _t('कुछ गलत हुआ। पुनः प्रयास करें।', 'Something went wrong.');
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
                    title: _t('सेवा लॉगिन', 'Service Login'),
                    subtitle: widget.serviceTitle != null
                        ? _t(
                            '"${widget.serviceTitle}" खोलने के लिए लॉगिन करें',
                            'Sign in to open "${widget.serviceTitle}"',
                          )
                        : _t(
                            'सेवा तक पहुँचने के लिए लॉगिन करें',
                            'Sign in to access the service',
                          ),
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
                        _SoftField(
                          controller: _userCtrl,
                          focusNode: _userFocus,
                          label: _isPoLogin
                              ? _t('यूज़र आईडी', 'User ID')
                              : _t('यूज़रनेम', 'Username'),
                          hint: _isPoLogin
                              ? _t('आईडी दर्ज करें', 'Enter user ID')
                              : _t('यूज़रनेम दर्ज करें', 'Enter username'),
                          icon: Icons.person_outline_rounded,
                          enabled: !_busy,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passFocus.requestFocus(),
                        ),
                        const SizedBox(height: 14),
                        _SoftField(
                          controller: _passCtrl,
                          focusNode: _passFocus,
                          label: _t('पासवर्ड', 'Password'),
                          hint: _t('पासवर्ड दर्ज करें', 'Enter password'),
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
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 16),
                        _HintStrip(
                          text: _t(
                            'सही विवरण भरने के बाद लॉगिन सक्रिय होगा।',
                            'Sign in unlocks after you enter your details.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SubmitButton(
                          busy: _busy,
                          onPressed: _submit,
                          text: _t('लॉगिन करें', 'Sign in'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SecureBadge(
                    text: _t(
                      'सुरक्षित सरकारी सेवा',
                      'Secure government service',
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _HeroChip(label: LocaleKeys.authTrustNic.tr()),
                    _HeroChip(label: LocaleKeys.authTrustGovt.tr()),
                    _HeroChip(label: LocaleKeys.authTrustEncrypted.tr()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
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

class _SecureBadge extends StatelessWidget {
  const _SecureBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.verified_user_outlined,
          size: 15,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            onSubmitted: onSubmitted,
            inputFormatters: obscure
                ? null
                : <TextInputFormatter>[
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
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
