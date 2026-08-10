import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Temporary OTP gate (bypass code `123456` until real OTP API is provided).
class PresidingPartyOtpScreen extends StatefulWidget {
  const PresidingPartyOtpScreen({super.key});

  @override
  State<PresidingPartyOtpScreen> createState() =>
      _PresidingPartyOtpScreenState();
}

class _PresidingPartyOtpScreenState extends State<PresidingPartyOtpScreen> {
  static const String _bypassOtp = '123456';

  final TextEditingController _otpCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _mobile {
    final Object? args = Get.arguments;
    if (args is Map && args['mobile'] != null) {
      return args['mobile'].toString();
    }
    if (args is String) return args;
    return '';
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final String otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = LocaleKeys.presidingPartyOtpRequired.tr());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    // Real send/verify OTP API will replace this bypass.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    if (otp != _bypassOtp) {
      setState(() {
        _busy = false;
        _error = LocaleKeys.presidingPartyOtpInvalid.tr();
      });
      return;
    }

    setState(() => _busy = false);
    Get.back<bool>(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final String mobile = _mobile;
    final String masked = mobile.length >= 4
        ? '${'*' * (mobile.length - 4)}${mobile.substring(mobile.length - 4)}'
        : mobile;

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
                if (!_busy) Get.back<bool>(result: false);
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
                        ),
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
                  AppGradientButton(
                    label: LocaleKeys.presidingPartyOtpVerify.tr(),
                    onPressed: _busy ? null : _verify,
                    isLoading: _busy,
                    icon: Icons.verified_user_outlined,
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
