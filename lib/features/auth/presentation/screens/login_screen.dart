import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/validators.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Officer login screen — entry point demonstrating the full
/// use case → repository → datasource flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final Worker _authWorker;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _officerId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  static const List<String> _districts = <String>[
    'Delhi Central',
    'Delhi North',
    'Delhi South',
    'Delhi East',
    'Delhi West',
    'New Delhi',
  ];
  String _district = _districts.first;

  @override
  void initState() {
    super.initState();
    _authWorker = ever<AuthState>(AppServices.auth.authState, (
      AuthState state,
    ) {
      if (state.status == AuthStatus.unauthenticated && state.failure != null) {
        AppSnackbar.error(context, state.failure!.localizationKey.tr());
      }
    });
  }

  @override
  void dispose() {
    _authWorker.dispose();
    _officerId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await AppServices.auth.signIn(
      LoginCredentials(
        officerId: _officerId.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AuthState state = AppServices.auth.authState.value;
      final bool biometricEnabled =
          AppServices.auth.biometricEnabled.value ?? false;
      final double top = MediaQuery.of(context).padding.top;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _SoftLoginHero(),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brXl,
                      border: Border.all(color: AppColors.outline),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          LocaleKeys.authLoginTitle.tr(),
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys.authLoginSubtitle.tr(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel(LocaleKeys.authDistrict.tr()),
                        _DistrictDropdown(
                          value: _district,
                          items: _districts,
                          onChanged: (String v) =>
                              setState(() => _district = v),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel(LocaleKeys.authUsername.tr()),
                        _LoginField(
                          controller: _officerId,
                          hint: LocaleKeys.authUsernameHint.tr(),
                          icon: Icons.tag_rounded,
                          validator: Validators.requiredOfficerId,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _FieldLabel(LocaleKeys.authPassword.tr()),
                            GestureDetector(
                              onTap: () {
                                // TODO(mayur): implement forgot password
                              },
                              child: Text(
                                LocaleKeys.commonForgot.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _LoginField(
                          controller: _password,
                          hint: LocaleKeys.authPasswordHint.tr(),
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? AppIcons.visibility
                                  : AppIcons.visibilityOff,
                              size: 18,
                              color: AppColors.slate400,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _remember = !_remember),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _remember
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _remember
                                        ? AppColors.primary
                                        : AppColors.slate300,
                                    width: 2,
                                  ),
                                ),
                                child: _remember
                                    ? const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                LocaleKeys.authRememberMe.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        AppGradientButton(
                          label: LocaleKeys.authLoginButton.tr(),
                          icon: Icons.lock_outline_rounded,
                          gradient: AppGradients.primaryButton,
                          isLoading: state.isBusy,
                          onPressed: _submit,
                        ),
                        if (biometricEnabled) ...<Widget>[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: state.isBusy
                                ? null
                                : () => AppServices.auth.signInWithBiometrics(),
                            icon: const Icon(AppIcons.fingerprint),
                            label: Text(LocaleKeys.authBiometricButton.tr()),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primaryDark,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.brLg,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    LocaleKeys.appCopyright.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Soft blue→mint hero — same family as service (survey / pithasin) login.
class _SoftLoginHero extends StatelessWidget {
  const _SoftLoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: AppRadius.brXl,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const BrandLogo(width: 72),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.splashTitle.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.dashboardBrandSubtitle.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _TrustBadge(
                label: LocaleKeys.authTrustNic.tr(),
                color: Colors.white,
              ),
              _TrustBadge(
                label: LocaleKeys.authTrustGovt.tr(),
                color: Colors.white,
              ),
              _TrustBadge(
                label: LocaleKeys.authTrustEncrypted.tr(),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color: AppColors.slate500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate700),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.slate400),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.slate50,
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.slate100),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  const _DistrictDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.slate400,
      ),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate700),
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.slate400,
        ),
        filled: true,
        fillColor: AppColors.slate50,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.slate100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      items: items
          .map((String d) => DropdownMenuItem<String>(value: d, child: Text(d)))
          .toList(),
      onChanged: (String? v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
