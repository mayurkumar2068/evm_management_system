import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:evm_management_system/features/service_auth/presentation/widgets/service_auth_chrome.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// In-app self-registration for PO / Booth-PS officers (opened from login).
///
/// PO → `POST /api/Account/register-po-user` (`userName`, `password`)
/// PS → `POST /api/Account/register-ps-user` (`mobileNo`, `name`, `designation`)
class ServiceSelfRegisterScreen extends StatefulWidget {
  const ServiceSelfRegisterScreen({
    required this.isPresidingOfficer,
    super.key,
  });

  final bool isPresidingOfficer;

  @override
  State<ServiceSelfRegisterScreen> createState() =>
      _ServiceSelfRegisterScreenState();
}

class _ServiceSelfRegisterScreenState extends State<ServiceSelfRegisterScreen> {
  // PS Survey fields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _designationCtrl = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _designationFocus = FocusNode();

  // PO fields
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode();

  bool _busy = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  bool get _isPo => widget.isPresidingOfficer;

  @override
  void initState() {
    super.initState();
    for (final FocusNode node in <FocusNode>[
      _nameFocus,
      _mobileFocus,
      _designationFocus,
      _userFocus,
      _passFocus,
      _confirmPassFocus,
    ]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _designationCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _designationFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  String _localizedAuthMessage(String message) {
    if (message.startsWith('auth.') ||
        message.startsWith('error.') ||
        message.startsWith('service_auth.') ||
        message.startsWith('common.')) {
      return message.tr();
    }
    return message;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_busy) return;

    if (_isPo) {
      await _submitPo();
    } else {
      await _submitPs();
    }
  }

  Future<void> _submitPs() async {
    final String name = _nameCtrl.text.trim();
    final String mobile = _mobileCtrl.text.trim();
    final String designation = _designationCtrl.text.trim();

    if (name.isEmpty) {
      setState(
        () => _error = LocaleKeys.serviceAuthRegisterFullNameRequired.tr(),
      );
      return;
    }
    if (mobile.length != 10) {
      setState(() => _error = LocaleKeys.serviceAuthMobileNoInvalid.tr());
      return;
    }
    if (designation.isEmpty) {
      setState(
        () => _error = LocaleKeys.serviceAuthRegisterDesignationRequired.tr(),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final String message = await AppServices.serviceAuth.registerPsUser(
        mobileNo: mobile,
        name: name,
        designation: designation,
      );
      if (!mounted) return;
      AppSnackbar.success(context, _localizedAuthMessage(message));
      Get.back<void>();
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _localizedAuthMessage(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = LocaleKeys.serviceAuthGenericError.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPo() async {
    final String userName = _userCtrl.text.trim();
    final String password = _passCtrl.text;
    final String confirm = _confirmPassCtrl.text;

    if (userName.isEmpty) {
      setState(() => _error = LocaleKeys.serviceAuthUsernameRequired.tr());
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = LocaleKeys.serviceAuthPasswordRequired.tr());
      return;
    }
    if (password.length < 6) {
      setState(() => _error = LocaleKeys.authPasswordTooShort.tr());
      return;
    }
    if (password != confirm) {
      setState(
        () => _error = LocaleKeys.serviceAuthRegisterPasswordMismatch.tr(),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final String message = await AppServices.serviceAuth.registerPoUser(
        userName: userName,
        password: password,
      );
      if (!mounted) return;
      final String toast = message == LocaleKeys.serviceAuthRegisterSuccess
          ? LocaleKeys.serviceAuthRegisterSuccessPo.tr()
          : _localizedAuthMessage(message);
      AppSnackbar.success(context, toast);
      Get.back<void>();
    } on ServiceAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _localizedAuthMessage(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = LocaleKeys.serviceAuthGenericError.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    final String heroTitle = _isPo
        ? LocaleKeys.servicePresidingTitle.tr()
        : LocaleKeys.serviceBoothTitle.tr();
    final String subtitle = _isPo
        ? LocaleKeys.serviceAuthRegisterSubtitlePo.tr()
        : LocaleKeys.serviceAuthRegisterSubtitle.tr();

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
                    title: heroTitle,
                    subtitle: LocaleKeys.serviceAuthRegisterTitle.tr(),
                  ),
                  const SizedBox(height: 20),
                  ServiceAuthFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_isPo) ..._poFields() else ..._psFields(),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 14),
                          AppStatusBanner(
                            message: _error!,
                            tone: StatusTone.error,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ServiceAuthHintStrip(text: subtitle),
                        const SizedBox(height: 20),
                        ServiceAuthSubmitButton(
                          busy: _busy,
                          onPressed: _submit,
                          text: LocaleKeys.serviceAuthRegisterSubmit.tr(),
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

  List<Widget> _psFields() {
    return <Widget>[
      ServiceAuthSoftField(
        controller: _nameCtrl,
        focusNode: _nameFocus,
        label: LocaleKeys.serviceAuthRegisterFullName.tr(),
        hint: LocaleKeys.serviceAuthRegisterFullNameHint.tr(),
        icon: Icons.person_outline_rounded,
        enabled: !_busy,
        textInputAction: TextInputAction.next,
        inputFormatters: const <TextInputFormatter>[],
        onSubmitted: (_) => _mobileFocus.requestFocus(),
      ),
      const SizedBox(height: 14),
      ServiceAuthSoftField(
        controller: _mobileCtrl,
        focusNode: _mobileFocus,
        label: LocaleKeys.serviceAuthMobileNo.tr(),
        hint: LocaleKeys.serviceAuthMobileNoHint.tr(),
        icon: Icons.phone_iphone_rounded,
        enabled: !_busy,
        keyboardType: TextInputType.phone,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _designationFocus.requestFocus(),
      ),
      const SizedBox(height: 14),
      ServiceAuthSoftField(
        controller: _designationCtrl,
        focusNode: _designationFocus,
        label: LocaleKeys.serviceAuthRegisterDesignation.tr(),
        hint: LocaleKeys.serviceAuthRegisterDesignationHint.tr(),
        icon: Icons.badge_outlined,
        enabled: !_busy,
        textInputAction: TextInputAction.done,
        inputFormatters: const <TextInputFormatter>[],
        onSubmitted: (_) => _submit(),
      ),
    ];
  }

  List<Widget> _poFields() {
    return <Widget>[
      ServiceAuthSoftField(
        controller: _userCtrl,
        focusNode: _userFocus,
        label: LocaleKeys.serviceAuthUsername.tr(),
        hint: LocaleKeys.serviceAuthUsernameHint.tr(),
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
        obscure: _obscurePass,
        textInputAction: TextInputAction.next,
        suffix: IconButton(
          onPressed: _busy
              ? null
              : () => setState(() => _obscurePass = !_obscurePass),
          icon: Icon(
            _obscurePass
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: context.appMuted,
          ),
        ),
        onSubmitted: (_) => _confirmPassFocus.requestFocus(),
      ),
      const SizedBox(height: 14),
      ServiceAuthSoftField(
        controller: _confirmPassCtrl,
        focusNode: _confirmPassFocus,
        label: LocaleKeys.serviceAuthRegisterPasswordConfirm.tr(),
        hint: LocaleKeys.serviceAuthRegisterPasswordConfirmHint.tr(),
        icon: Icons.lock_outline_rounded,
        enabled: !_busy,
        obscure: _obscureConfirm,
        textInputAction: TextInputAction.done,
        suffix: IconButton(
          onPressed: _busy
              ? null
              : () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: context.appMuted,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    ];
  }
}
