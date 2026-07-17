import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// A formal and attractive fallback screen for offline data collection.
class OfflineFallbackScreen extends StatefulWidget {
  const OfflineFallbackScreen({required this.title, super.key});

  final String title;

  @override
  State<OfflineFallbackScreen> createState() => _OfflineFallbackScreenState();
}

class _OfflineFallbackScreenState extends State<OfflineFallbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _districtController = TextEditingController();
  final _boothController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isVerified = false;

  // Formal questions for the inspection/survey
  final Map<String, bool?> _checklist = {
    'Is the EVM warehouse physically secured?': null,
    'Are CCTV cameras operational in the area?': null,
    'Is the fire safety equipment accessible?': null,
    'Are authorized personnel logs maintained?': null,
  };

  // Professional District Suggestions
  final List<String> _districts = [
    'BHOPAL',
    'INDORE',
    'GWALIOR',
    'JABALPUR',
    'UJJAIN',
    'SAGAR',
    'REWA',
    'SATNA',
    'RATLAM',
    'MORENA',
  ];

  @override
  void dispose() {
    _districtController.dispose();
    _boothController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back<void>(),
        ),
      ),
      body: Column(
        children: [
          _buildOfflineStatusBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFLINE FORM ENTRY',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Field Inspection Report',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Location Section ---
                    _buildSectionHeader(
                      Icons.location_on_rounded,
                      'Location Details',
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('District Name'),
                    _buildDistrictAutocomplete(),
                    const SizedBox(height: 20),

                    _buildFieldLabel('Booth / Warehouse Number'),
                    TextFormField(
                      controller: _boothController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. WH-BPL-001',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),

                    // --- Checklist Section ---
                    _buildSectionHeader(
                      Icons.fact_check_rounded,
                      'Safety & Security Checklist',
                    ),
                    const SizedBox(height: 16),
                    _buildChecklistCard(),
                    const SizedBox(height: 32),

                    // --- Remarks Section ---
                    _buildSectionHeader(
                      Icons.rate_review_rounded,
                      'Additional Observations',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter detailed remarks here...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Verification ---
                    _buildVerificationToggle(),
                    const SizedBox(height: 40),

                    AppGradientButton(
                      label: 'Save Offline Record',
                      icon: Icons.cloud_off_rounded,
                      onPressed: _isVerified ? _submitForm : null,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Data will be synced automatically when online.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: const Color(0xFFFEF2F2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_off_rounded,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Text(
            'Offline Mode Active',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.slate700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color: AppColors.slate500,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDistrictAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty)
          return const Iterable<String>.empty();
        return _districts.where(
          (String option) =>
              option.contains(textEditingValue.text.toUpperCase()),
        );
      },
      onSelected: (String selection) {
        _districtController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Search District...',
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildChecklistCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: _checklist.keys.map((q) {
          final isLast = _checklist.keys.last == q;
          return Column(
            children: [
              CheckboxListTile(
                title: Text(
                  q,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate800,
                  ),
                ),
                value: _checklist[q] ?? false,
                onChanged: (v) => setState(() => _checklist[q] = v),
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.slate100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerificationToggle() {
    return InkWell(
      onTap: () => setState(() => _isVerified = !_isVerified),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _isVerified,
                onChanged: (v) => setState(() => _isVerified = v ?? false),
                activeColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I hereby certify that the information provided is accurate and verified on-site by the authorized officer.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // Logic to persist entry in Local Database
    AppSnackbar.success(context, 'Report Saved Offline Successfully');
    Get.back<dynamic>();
  }
}
