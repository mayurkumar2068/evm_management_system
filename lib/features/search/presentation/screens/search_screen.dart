import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// In-memory list of the user's most recent search queries (newest first).
class RecentSearchesController extends GetxController {
  final RxList<String> recent = <String>[].obs;

  void add(String query) {
    final String q = query.trim();
    if (q.isEmpty) return;
    final List<String> next = <String>[
      q,
      ...recent.where((String s) => s.toLowerCase() != q.toLowerCase()),
    ];
    recent.assignAll(next.take(8));
  }
}

/// Universal Search — searches across device IDs, barcodes, boxes and officers
/// with type filters, advanced filter shortcuts and recent searches. Reads
/// live from the device-records store.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final RecentSearchesController _recentSearches = Get.put(
    RecentSearchesController(),
    tag: 'search',
  );
  late final List<(String, String)> _chips = <(String, String)>[
    ('all', LocaleKeys.statsTotal.tr()),
    ('control_unit', LocaleKeys.statsControlUnits.tr()),
    ('ballot_unit', LocaleKeys.statsBallotUnits.tr()),
    ('box', LocaleKeys.detailBoxNo.tr()),
    ('officer', LocaleKeys.authUsername.tr()),
  ];

  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _chip = 'all';

  @override
  void dispose() {
    Get.delete<RecentSearchesController>(tag: 'search');
    _controller.dispose();
    super.dispose();
  }

  List<DeviceRecord> _filtered() {
    final List<DeviceRecord> base = AppServices.deviceRecords.search(_query);
    return switch (_chip) {
      'control_unit' =>
        base
            .where((DeviceRecord r) => r.kind == DeviceKind.controlUnit)
            .toList(),
      'ballot_unit' =>
        base
            .where((DeviceRecord r) => r.kind == DeviceKind.ballotUnit)
            .toList(),
      _ => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          _searchHeader(context),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _searchHeader(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              AppCircleBackButton(
                onTap: () => Get.key.currentState?.canPop() == true
                    ? Get.back<dynamic>()
                    : Get.offAllNamed<dynamic>(AppRoute.dashboard.path),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (String v) => setState(() => _query = v),
                  onSubmitted: (String v) => _recentSearches.add(v),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.dashboardSearchHint.tr(),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.slate400,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.slate400,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.brMd,
                      borderSide: BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.brMd,
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final (String, String) c in _chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _chip = c.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _chip == c.$1
                              ? AppColors.primary
                              : AppColors.slate100,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          c.$2,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _chip == c.$1
                                ? Colors.white
                                : AppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_query.isEmpty) return _suggestions();
    final List<DeviceRecord> results = _filtered();
    if (results.isEmpty) return _empty();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            results.length == 1
                ? LocaleKeys.searchResultFor.tr(args: [_query])
                : LocaleKeys.searchResultsFor.tr(
                    args: ['${results.length}', _query],
                  ),
            style: AppTextStyles.caption.copyWith(color: AppColors.slate400),
          ),
        ),
        for (final DeviceRecord r in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(
              record: r,
              onTap: () {
                _recentSearches.add(_query);
                Get.toNamed<dynamic>(
                  AppRoute.deviceDetail.path,
                  arguments: r.id,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _suggestions() {
    return Obx(() {
      final List<String> recent = _recentSearches.recent;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            LocaleKeys.searchAdvancedFilters.tr(),
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.7,
            children: <Widget>[
              _FilterChip(
                label: LocaleKeys.statsActive.tr(),
                sub: 'Filter by status',
              ), // Simplified sub for now as they are static in original
              _FilterChip(
                label: LocaleKeys.authDistrict.tr(),
                sub: 'Select district',
              ),
              const _FilterChip(label: 'Date Range', sub: 'From – To'),
              _FilterChip(
                label: LocaleKeys.regManufacturer.tr(),
                sub: 'BEL / ECIL',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            LocaleKeys.searchRecent.tr(),
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    LocaleKeys.searchRecentEmpty.tr(),
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final String r in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    _controller.text = r;
                    setState(() => _query = r);
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: AppColors.slate300,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.slate600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.slate300,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      );
    });
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              borderRadius: AppRadius.brXl,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppColors.slate300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.searchNoResults.tr(),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.searchHint.tr(),
            style: const TextStyle(color: AppColors.slate300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.sub});
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            size: 14,
            color: AppColors.slate300,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.record, required this.onTap});
  final DeviceRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isCu = record.kind == DeviceKind.controlUnit;
    final Color accent = isCu ? AppColors.primary : AppColors.green;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(
              isCu ? Icons.memory_rounded : Icons.dns_rounded,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.id,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate700,
                  ),
                ),
                Text(
                  '${record.barcode} • ${record.box}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '${record.district} • ${record.officer}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppStatusPill(status: record.status.key),
        ],
      ),
    );
  }
}
