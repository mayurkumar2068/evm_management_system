import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:MPSECNET/app/router/app_routes.dart';
import 'package:MPSECNET/core/location/location_service.dart';
import 'package:MPSECNET/core/media/app_image_picker_service.dart';
import 'package:MPSECNET/features/grievance/di/grievance_module.dart';
import 'package:MPSECNET/features/grievance/presentation/controllers/grievance_controller.dart';
import 'package:MPSECNET/localization/locale_keys.dart';
import 'package:MPSECNET/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

class GrievanceFormScreen extends StatefulWidget {
  const GrievanceFormScreen({super.key});

  @override
  State<GrievanceFormScreen> createState() => _GrievanceFormScreenState();
}

class _GrievanceFormScreenState extends State<GrievanceFormScreen> {
  late final GrievanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GrievanceModule.ensureController();
    _controller.captureLocationInBackground();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bool ok = await _controller.submitGrievance();
    if (!ok || !mounted) return;

    final String reference = _controller.referenceNo.value ?? '';
    await AppDialog.alert(
      context,
      title: LocaleKeys.grievanceSubmitSuccessTitle.tr(),
      message: reference.isNotEmpty
          ? LocaleKeys.grievanceSubmitSuccessMessageWithRef.tr(
              args: <String>[reference],
            )
          : LocaleKeys.grievanceSubmitSuccessMessage.tr(),
      actionLabel: LocaleKeys.grievanceDoneButton.tr(),
    );
    if (!mounted) return;
    _controller.reset();
    unawaited(Get.offAllNamed<void>(AppRoute.dashboard.path));
  }

  Future<void> _showPhotoSourceSheet() async {
    final ImageSource? source = await AppBottomSheet.show<ImageSource>(
      context,
      title: LocaleKeys.grievancePhotoSection.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppButton(
            label: LocaleKeys.grievancePickFromCamera.tr(),
            icon: Icons.photo_camera_outlined,
            onPressed: () => Get.back<ImageSource>(result: ImageSource.camera),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: LocaleKeys.grievancePickFromGallery.tr(),
            icon: Icons.photo_library_outlined,
            variant: AppButtonVariant.outline,
            onPressed: () => Get.back<ImageSource>(result: ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source != null) {
      await _controller.pickPhoto(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: <Widget>[
          AppGradientHeader(
            centerTitle: true,
            title: LocaleKeys.grievanceFormTitle.tr(),
            leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Ambient glowing backdrop for depth and high-level visual polish
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.08 : 0.14,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 240,
                  left: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withValues(
                        alpha: isDark ? 0.05 : 0.09,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Obx(() {
                    final bool busy = _controller.busy.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SectionBadge(
                          icon: Icons.person_pin_rounded,
                          title: LocaleKeys.grievanceYourDetailsSection.tr(),
                        ),
                        const SizedBox(height: 10),
                        _FormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _VerifiedMobileRow(
                                label: LocaleKeys.grievanceMobileNo.tr(),
                                value: _controller.verifiedMobile,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: LocaleKeys.grievanceFullName.tr(),
                                hint: LocaleKeys.grievanceFullNameHint.tr(),
                                controller: _controller.fullNameController,
                                enabled: !busy,
                                isRequired: true,
                                prefixIcon: Icons.badge_outlined,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionBadge(
                          icon: Icons.assignment_outlined,
                          title: LocaleKeys.grievanceDetailsSection.tr(),
                        ),
                        const SizedBox(height: 10),
                        _FormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Obx(
                                () => AppDropdown<GrievanceCategoryOption>(
                                  label: LocaleKeys.grievanceCategory.tr(),
                                  hint: LocaleKeys.grievanceCategoryHint.tr(),
                                  items: kGrievanceCategories,
                                  value: _controller.selectedCategory.value,
                                  labelBuilder: (GrievanceCategoryOption o) =>
                                      o.labelKey.tr(),
                                  enabled: !busy,
                                  prefixIcon: Icons.category_rounded,
                                  onChanged: (GrievanceCategoryOption? value) {
                                    if (value != null) {
                                      _controller.selectedCategory.value =
                                          value;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: LocaleKeys.grievanceSubject.tr(),
                                hint: LocaleKeys.grievanceSubjectHint.tr(),
                                controller: _controller.subjectController,
                                enabled: !busy,
                                isRequired: true,
                                prefixIcon: Icons.edit_note_rounded,
                                maxLength: 100,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: LocaleKeys.grievanceDescription.tr(),
                                hint: LocaleKeys.grievanceDescriptionHint.tr(),
                                controller: _controller.descriptionController,
                                enabled: !busy,
                                isRequired: true,
                                prefixIcon: Icons.description_outlined,
                                maxLines: 5,
                                minLines: 3,
                                maxLength: 1000,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionBadge(
                          icon: Icons.camera_alt_outlined,
                          title: LocaleKeys.grievancePhotoSection.tr(),
                          badge: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              LocaleKeys.grievancePhotoRequiredBadge.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => _PhotoAttachmentCard(
                            photo: _controller.photo.value,
                            location: _controller.location.value,
                            busy: busy,
                            onTap: _showPhotoSourceSheet,
                            onRemove: _controller.removePhoto,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: context.appMuted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                LocaleKeys.grievancePhotoHint.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  color: context.appMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Obx(() {
                          if (_controller.location.value == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenDark.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: AppRadius.brMd,
                                border: Border.all(
                                  color: AppColors.greenDark.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenDark.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.my_location_rounded,
                                      size: 14,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      LocaleKeys.grievanceLocationTagged.tr(),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.greenDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.greenDark,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (_controller.error.value != null) ...<Widget>[
                          const SizedBox(height: 16),
                          AppStatusBanner(
                            message: _controller.error.value!,
                            tone: StatusTone.error,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: 28),
                        AppGradientButton(
                          label: LocaleKeys.grievanceSubmitButton.tr(),
                          icon: Icons.send_rounded,
                          onPressed: busy ? null : _submit,
                          isLoading: busy,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.shield_outlined,
                                size: 13,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.grievanceFooterBranding.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.slate400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.icon, required this.title, this.badge});

  final IconData icon;
  final String title;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.primary.withValues(alpha: 0.16),
                AppColors.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: context.isAppDark
                ? AppColors.primaryBright
                : AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: context.appOnSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        if (badge != null) ...<Widget>[const SizedBox(width: 8), badge!],
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppRadius.brXl,
        border: Border.all(
          color: isDark ? AppColors.darkOutline : const Color(0xFFE6EDF5),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0F2744).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PhotoAttachmentCard extends StatelessWidget {
  const _PhotoAttachmentCard({
    required this.photo,
    required this.busy,
    required this.onTap,
    required this.onRemove,
    this.location,
  });

  final AppPickedImage? photo;
  final GeoCoordinates? location;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;

    if (photo == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: AppRadius.brXl,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF4F8FC),
              borderRadius: AppRadius.brXl,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        AppColors.primaryLight.withValues(alpha: 0.6),
                        AppColors.primary.withValues(alpha: 0.12),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    size: 26,
                    color: isDark
                        ? AppColors.primaryBright
                        : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.grievanceAddPhoto.tr(),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.primaryBright
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.grievancePhotoPlaceholderSubtitle.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: context.appMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppRadius.brXl,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: Image.memory(
                  photo!.bytes,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  photo!.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.grievancePhotoSizeInfo.tr(
                    args: <String>[
                      (photo!.bytes.lengthInBytes / 1024).toStringAsFixed(1),
                    ],
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: context.appMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                if (location != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          LocaleKeys.grievanceGpsCoordinates.tr(
                            args: <String>[
                              location!.latitude.toStringAsFixed(5),
                              location!.longitude.toStringAsFixed(5),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    _ActionChipButton(
                      label: LocaleKeys.grievanceChangePhoto.tr(),
                      icon: Icons.sync_rounded,
                      color: AppColors.primary,
                      onTap: busy ? null : onTap,
                    ),
                    const SizedBox(width: 10),
                    _ActionChipButton(
                      label: LocaleKeys.grievanceRemovePhoto.tr(),
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: busy ? null : onRemove,
                    ),
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

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Official verified mobile display badge with high-end aesthetic
class _VerifiedMobileRow extends StatelessWidget {
  const _VerifiedMobileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  AppColors.darkOutline.withValues(alpha: 0.5),
                  AppColors.darkOutline.withValues(alpha: 0.2),
                ]
              : <Color>[const Color(0xFFF0F6FD), const Color(0xFFE8F2FD)],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 20,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        LocaleKeys.grievanceOtpVerifiedBadge.tr(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.slate400,
          ),
        ],
      ),
    );
  }
}
