import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_officer_details_store.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_officer_details_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_officer_details.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

const int kMobileNumberLength = 10;

/// Post-PO-login gate: load/save officer name + mobile (OTP when new / mobile changed).
class PresidingPoDetailsScreen extends StatefulWidget {
  const PresidingPoDetailsScreen({super.key});

  @override
  State<PresidingPoDetailsScreen> createState() =>
      _PresidingPoDetailsScreenState();
}

enum _PoDetailsStep { form, otp }

const String _otpEmptyMark = '\u200b';

class _PresidingPoDetailsScreenState extends State<PresidingPoDetailsScreen> {
  late final PoOfficerDetailsDatasource _api;
  late final PoOfficerDetailsStore _profileStore;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(text: _otpEmptyMark),
  );
  final List<FocusNode> _otpFocus = List<FocusNode>.generate(6, (_) => FocusNode());
  final List<String> _otpPrev = List<String>.filled(6, '');

  bool _loading = true;
  bool _busy = false;
  bool _existingProfile = false;
  String _savedMobile = '';
  String _savedName = '';
  String? _existingId;
  String? _error;
  String? _info;
  _PoDetailsStep _step = _PoDetailsStep.form;

  String get _poUserId =>
      AppServices.serviceAuth.session.value?.userId.trim() ?? '';

  bool get _mobileChanged =>
      _existingProfile && _mobileCtrl.text.trim() != _savedMobile;

  bool get _nameChanged =>
      _existingProfile && _nameCtrl.text.trim() != _savedName;

  /// Skip OTP only when saved profile exists and nothing was edited.
  bool get _canSkipOtp =>
      _existingProfile && !_mobileChanged && !_nameChanged;

  String get _otpValue => _otpCtrls
      .map(
        (TextEditingController c) =>
            c.text.replaceAll(_otpEmptyMark, '').replaceAll(RegExp(r'\D'), ''),
      )
      .join();

  @override
  void initState() {
    super.initState();
    _api = PoOfficerDetailsDatasource(AppServices.config);
    _profileStore = PoOfficerDetailsStore(AppServices.secureStorage);
    _nameCtrl.addListener(() {
      if (mounted && _step == _PoDetailsStep.form) setState(() {});
    });
    _mobileCtrl.addListener(() {
      if (mounted && _step == _PoDetailsStep.form) setState(() {});
    });
    for (int i = 0; i < _otpFocus.length; i++) {
      _otpFocus[i].addListener(() {
        if (!_otpFocus[i].hasFocus) return;
        final TextEditingController ctrl = _otpCtrls[i];
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      });
    }
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    for (final TextEditingController c in _otpCtrls) {
      c.dispose();
    }
    for (final FocusNode f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final String poUserId = _poUserId;
    if (poUserId.isEmpty) {
      setState(() {
        _loading = false;
        _error = LocaleKeys.presidingPoDetailsSessionMissing.tr();
      });
      return;
    }
    try {
      final PoOfficerDetails? existing = await _api.fetchDetails(poUserId);
      if (!mounted) return;
      if (existing != null && existing.hasProfile) {
        _nameCtrl.text = existing.poName;
        _mobileCtrl.text = existing.poMobileNo;
        _savedName = existing.poName.trim();
        _savedMobile = existing.poMobileNo.trim();
        _existingId = existing.hasServerId ? existing.id : null;
        _existingProfile = true;
        await _profileStore.save(existing);
      }
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is PoApiException && e.isUnauthorized
            ? LocaleKeys.presidingPoDetailsSessionExpired.tr()
            : e is PoApiException
            ? e.message
            : LocaleKeys.presidingPoDetailsLoadFailed.tr();
      });
    }
  }

  String? _validateForm() {
    if (_nameCtrl.text.trim().isEmpty) {
      return LocaleKeys.presidingPoDetailsNameRequired.tr();
    }
    final String mobile = _mobileCtrl.text.trim();
    if (mobile.isEmpty) {
      return LocaleKeys.presidingPoDetailsMobileRequired.tr();
    }
    if (mobile.length != kMobileNumberLength || int.tryParse(mobile) == null) {
      return LocaleKeys.presidingPoDetailsMobileInvalid.tr();
    }
    return null;
  }

  void _clearOtp() {
    for (int i = 0; i < _otpCtrls.length; i++) {
      _otpCtrls[i].text = _otpEmptyMark;
      _otpPrev[i] = '';
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.greenDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onPrimary() async {
    FocusScope.of(context).unfocus();
    if (_canSkipOtp) {
      _goToDashboard();
      return;
    }
    if (_step == _PoDetailsStep.form) {
      await _sendOtp(isResend: false);
      return;
    }
    await _verifyAndSave();
  }

  Future<void> _sendOtp({required bool isResend}) async {
    final String? validationError = _validateForm();
    if (validationError != null) {
      setState(() {
        _error = validationError;
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _api.sendOtp(_mobileCtrl.text.trim());
      if (!mounted) return;
      final String mobile = _mobileCtrl.text.trim();
      final String masked = mobile.masked;
      final String msg = isResend
          ? LocaleKeys.presidingPoDetailsOtpResent.tr(
              args: <String>[masked],
            )
          : LocaleKeys.presidingPoDetailsOtpSent.tr(
              args: <String>[masked],
            );
      setState(() {
        _busy = false;
        _step = _PoDetailsStep.otp;
        _info = msg;
        _clearOtp();
      });
      _showSnack(msg);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocus.first.requestFocus();
      });
    } on PoApiException catch (e) {
      if (!mounted) return;
      final String msg = _poDetailsError(e, LocaleKeys.presidingPoDetailsOtpSendFailed.tr());
      setState(() {
        _busy = false;
        _error = msg;
      });
      _showSnack(msg, error: true);
    } catch (_) {
      if (!mounted) return;
      final String msg = LocaleKeys.presidingPoDetailsOtpSendFailed.tr();
      setState(() {
        _busy = false;
        _error = msg;
      });
      _showSnack(msg, error: true);
    }
  }

  Future<void> _verifyAndSave() async {
    final String otp = _otpValue;
    if (otp.length != 6) {
      setState(() {
        _error = LocaleKeys.presidingPoDetailsOtpRequired.tr();
        _info = null;
      });
      return;
    }
    final String poUserId = _poUserId;
    if (poUserId.isEmpty) {
      setState(() => _error = LocaleKeys.presidingPoDetailsSessionMissing.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.saveWithOtp(
        details: PoOfficerDetails(
          id: _existingId,
          poUserId: poUserId,
          poName: _nameCtrl.text.trim(),
          poMobileNo: _mobileCtrl.text.trim(),
        ),
        otp: otp,
      );
      await _profileStore.save(
        PoOfficerDetails(
          id: _existingId,
          poUserId: poUserId,
          poName: _nameCtrl.text.trim(),
          poMobileNo: _mobileCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      _goToDashboard();
    } on PoApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _poDetailsError(e, LocaleKeys.presidingPoDetailsSaveFailed.tr());
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = LocaleKeys.presidingPoDetailsSaveFailed.tr();
      });
    }
  }

  String _poDetailsError(PoApiException e, String fallback) {
    if (e.isUnauthorized) {
      return LocaleKeys.presidingPoDetailsSessionExpired.tr();
    }
    final String msg = e.message.trim();
    if (msg.isEmpty ||
        msg == 'OTP send failed' ||
        msg == 'Save failed' ||
        msg.startsWith('Save failed (HTTP')) {
      return fallback;
    }
    return msg;
  }

  void _goToDashboard() {
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    if (session == null) {
      Get.back<void>();
      return;
    }
    Get.offNamed<void>(AppRoute.presidingDashboard.path);
  }

  void _onOtpChanged(int index, String value) {
    final String digits =
        value.replaceAll(_otpEmptyMark, '').replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (int i = 0; i < 6; i++) {
        _otpCtrls[i].text = i < digits.length ? digits[i] : _otpEmptyMark;
        _otpPrev[i] = i < digits.length ? digits[i] : '';
      }
      final int focusAt = (digits.length >= 6 ? 5 : digits.length).clamp(0, 5);
      _otpFocus[focusAt].requestFocus();
      setState(() {});
      return;
    }
    if (digits.isEmpty) {
      final bool hadDigit = _otpPrev[index].isNotEmpty;
      _otpCtrls[index].text = _otpEmptyMark;
      _otpPrev[index] = '';
      if (!hadDigit && index > 0) {
        _otpCtrls[index - 1].text = _otpEmptyMark;
        _otpPrev[index - 1] = '';
        _otpFocus[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }
    _otpCtrls[index].text = digits[0];
    _otpPrev[index] = digits[0];
    _otpCtrls[index].selection = const TextSelection.collapsed(offset: 1);
    if (index < 5) {
      _otpFocus[index + 1].requestFocus();
    } else {
      _otpFocus[index].unfocus();
    }
    setState(() {});
  }

  void _onOtpBackspaceEmpty(int index) {
    if (index <= 0) return;
    _otpCtrls[index - 1].text = _otpEmptyMark;
    _otpPrev[index - 1] = '';
    _otpFocus[index - 1].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool otpStep = _step == _PoDetailsStep.otp;
    final String mobile = _mobileCtrl.text.trim();
    final String masked = mobile.masked;

    final String primaryLabel = _canSkipOtp
        ? LocaleKeys.presidingPoDetailsContinue.tr()
        : otpStep
        ? LocaleKeys.presidingPoDetailsVerify.tr()
        : LocaleKeys.presidingPoDetailsSendOtp.tr();
    final IconData primaryIcon = _canSkipOtp
        ? Icons.arrow_forward_rounded
        : otpStep
        ? Icons.verified_user_outlined
        : Icons.sms_outlined;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: <Widget>[
          AppGradientHeader(
            centerTitle: true,
            title: LocaleKeys.presidingPoDetailsTitle.tr(),
            subtitle: otpStep
                ? LocaleKeys.presidingPoDetailsOtpSubtitle.tr(
                    args: <String>[masked.isEmpty ? '—' : masked],
                  )
                : LocaleKeys.presidingPoDetailsSubtitle.tr(),
            leading: AppCircleBackButton(
              onTap: () {
                if (_busy) return;
                if (otpStep) {
                  setState(() {
                    _step = _PoDetailsStep.form;
                    _error = null;
                    _info = null;
                    _clearOtp();
                  });
                  return;
                }
                Get.back<void>();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: AppLoader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.slate200),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child:
                              otpStep ? _buildOtpFields() : _buildFormFields(),
                        ),
                        if (_info != null) ...<Widget>[
                          const SizedBox(height: 12),
                          AppStatusBanner(
                            message: _info!,
                            tone: StatusTone.success,
                          ),
                        ],
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          AppStatusBanner(
                            message: _error!,
                            tone: StatusTone.error,
                          ),
                        ],
                        const SizedBox(height: 18),
                        PresidingThemeButton(
                          label: primaryLabel,
                          isLoading: _busy,
                          onPressed: _busy ? null : _onPrimary,
                          icon: primaryIcon,
                        ),
                        if (otpStep) ...<Widget>[
                          const SizedBox(height: 10),
                          PresidingThemeButton(
                            label: LocaleKeys.presidingPoDetailsResendOtp.tr(),
                            outlined: true,
                            onPressed: _busy
                                ? null
                                : () => _sendOtp(isResend: true),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_existingProfile && !_mobileChanged && !_nameChanged)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppStatusBanner(
              message: LocaleKeys.presidingPoDetailsAlreadySaved.tr(),
              tone: StatusTone.success,
            ),
          ),
        if (_nameChanged && !_mobileChanged)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppStatusBanner(
              message: LocaleKeys.presidingPoDetailsNameChanged.tr(),
              tone: StatusTone.info,
            ),
          ),
        if (_mobileChanged)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppStatusBanner(
              message: LocaleKeys.presidingPoDetailsMobileChanged.tr(),
              tone: StatusTone.info,
            ),
          ),
        Text(
          LocaleKeys.presidingPoDetailsName.tr(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.slate600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hint: LocaleKeys.presidingPoDetailsNameHint.tr(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          LocaleKeys.presidingPoDetailsMobile.tr(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.slate600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          maxLength: kMobileNumberLength,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: _inputDecoration(
            hint: LocaleKeys.presidingPoDetailsMobileHint.tr(),
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          LocaleKeys.presidingPoDetailsOtpLabel.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.slate700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double gap = 8;
            final double boxW =
                ((constraints.maxWidth - (gap * 5)) / 6).clamp(40.0, 48.0);
            final double boxH = boxW + 6;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < 6; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: gap),
                  _OtpDigitBox(
                    width: boxW,
                    height: boxH,
                    controller: _otpCtrls[i],
                    focusNode: _otpFocus[i],
                    onChanged: (String v) => _onOtpChanged(i, v),
                    onBackspaceEmpty: () => _onOtpBackspaceEmpty(i),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.presidingPoDetailsOtpHint.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.slate500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class _OtpDigitBox extends StatefulWidget {
  const _OtpDigitBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspaceEmpty,
  });

  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceEmpty;

  @override
  State<_OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<_OtpDigitBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onText);
    widget.focusNode.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    widget.focusNode.onKeyEvent = null;
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    final bool hasDigit = widget.controller.text
        .replaceAll(_otpEmptyMark, '')
        .replaceAll(RegExp(r'\D'), '')
        .isNotEmpty;
    if (hasDigit) {
      return KeyEventResult.ignored;
    }
    widget.onBackspaceEmpty();
    return KeyEventResult.handled;
  }

  void _onFocus() => setState(() {});
  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool focused = widget.focusNode.hasFocus;
    final bool filled = widget.controller.text
        .replaceAll(_otpEmptyMark, '')
        .replaceAll(RegExp(r'\D'), '')
        .isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: focused
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focused
              ? AppColors.primary
              : filled
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.slate200,
          width: focused ? 1.8 : 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        cursorColor: AppColors.primary,
        cursorWidth: 1.5,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.slate800,
          height: 1.1,
          fontSize: 18,
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
          filled: false,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
