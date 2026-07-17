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
class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key, this.serviceTitle});

  /// Name of the tile the user tapped — shown as context in the header.
  final String? serviceTitle;

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  static const Color _ink = Color(0xFF0F1E17);

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isPoLogin =>
      widget.serviceTitle == LocaleKeys.servicePresidingTitle.tr();
  bool get _isHindi => context.locale.languageCode == 'hi';

  String _t(String hi, String en) => _isHindi ? hi : en;

  String _localizedAuthMessage(String message) {
    if (message.startsWith('auth.') ||
        message.startsWith('error.') ||
        message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, top + 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _busy ? null : () => Get.back<void>(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: BrandLogo(width: 76)),
              const SizedBox(height: 18),
              Text(
                _isPoLogin
                    ? _t('पी.ओ. लॉगिन', 'P.O. Login')
                    : _t('सर्वे लॉगिन', 'Survey Login'),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.serviceTitle != null
                    ? _t(
                        '"${widget.serviceTitle}" खोलने के लिए लॉगिन करें',
                        'Sign in to open "${widget.serviceTitle}"',
                      )
                    : _t(
                        'सेवा तक पहुँचने के लिए लॉगिन करें',
                        'Sign in to access the service',
                      ),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate500,
                ),
              ),
              const SizedBox(height: 28),
              _Field(
                controller: _userCtrl,
                label: _isPoLogin
                    ? _t('यूज़र आईडी', 'User ID')
                    : _t('यूज़रनेम', 'Username'),
                icon: _isPoLogin
                    ? Icons.person_outline_rounded
                    : Icons.person_outline_rounded,
                enabled: !_busy,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _passCtrl,
                label: _t('पासवर्ड', 'Password'),
                icon: Icons.lock_outline_rounded,
                enabled: !_busy,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
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
              const SizedBox(height: 26),
              _SubmitButton(
                busy: _busy,
                onPressed: _submit,
                text: _t('लॉगिन करें', 'Sign in'),
              ),
              const SizedBox(height: 18),
              const _SecureBadge(),
            ],
          ),
        ),
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
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F8A5F),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.verified_user_outlined,
          size: 14,
          color: Color(0xFF0B6B49),
        ),
        const SizedBox(width: 6),
        Text(
          'Secure government service',
          style: AppTextStyles.caption.copyWith(color: AppColors.slate500),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
        color: const Color(0xFF0F1E17),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.slate400, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.slate50,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.slate500,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.slate100),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.slate100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: Color(0xFF0F8A5F), width: 1.6),
        ),
      ),
    );
  }
}
