import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/location/location_service.dart';
import 'package:evm_management_system/core/navigation/map_navigation_service.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Map preview + navigation button for the assigned polling booth (login Lat/Long).
/// Always visible on the PO dashboard — even when booth coordinates are missing.
class PresidingBoothMapCard extends StatefulWidget {
  const PresidingBoothMapCard({this.stationName, super.key});

  final String? stationName;

  @override
  State<PresidingBoothMapCard> createState() => _PresidingBoothMapCardState();
}

class _PresidingBoothMapCardState extends State<PresidingBoothMapCard> {
  final MapNavigationService _maps = MapNavigationService();
  final LocationService _location = LocationService();

  double? _boothLat;
  double? _boothLong;
  GeoCoordinates? _current;
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    final PresidingElectionContext? ctx = await store.read();
    final ServiceSession? session = AppServices.serviceAuth.session.value;

    final double? boothLat = ctx?.boothLat ?? session?.lat;
    final double? boothLong = ctx?.boothLong ?? session?.long;
    final GeoCoordinates? current = await _location.getCurrentCoordinates();

    if (!mounted) return;
    setState(() {
      _boothLat = boothLat;
      _boothLong = boothLong;
      _current = current;
      _loading = false;
    });
  }

  bool get _hasBooth =>
      _boothLat != null &&
      _boothLong != null &&
      _boothLat!.abs() > 0 &&
      _boothLong!.abs() > 0;

  String get _stationLabel {
    final String? name = widget.stationName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'मतदान केंद्र';
  }

  Future<void> _openNavigation() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      if (_hasBooth) {
        await _maps.openDirections(
          destinationLat: _boothLat!,
          destinationLng: _boothLong!,
          originLat: _current?.latitude,
          originLng: _current?.longitude,
          destinationLabel: _stationLabel,
        );
      } else {
        // Login me Lat/Long na ho to bhi map kholo — station name se search.
        await _maps.openPlaceSearch(_stationLabel);
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: AppLoader()),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MpSecTokens.cardRadius),
        side: const BorderSide(color: AppColors.slate100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 7,
                child: _hasBooth
                    ? Image.network(
                        _maps.staticMapImageUrl(
                          lat: _boothLat!,
                          lng: _boothLong!,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _mapPlaceholder(),
                      )
                    : _mapPlaceholder(),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: MpSecTokens.softBlueDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'मतदान केंद्र',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'मतदान केंद्र का स्थान',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stationLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasBooth
                      ? '${_boothLat!.toStringAsFixed(5)}°, ${_boothLong!.toStringAsFixed(5)}°'
                      : 'लॉगिन में निर्देशांक नहीं मिले — मैप बटन से खोज खोलें',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate500,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                if (_current != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'आपकी वर्तमान लोकेशन: '
                    '${_current!.latitude.toStringAsFixed(5)}°, '
                    '${_current!.longitude.toStringAsFixed(5)}°',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _navigating ? null : _openNavigation,
                    icon: _navigating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.directions_rounded),
                    label: Text(
                      'मतदान केंद्र पर जाएँ',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: MpSecTokens.softBlueDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _mapPlaceholder() {
    return Container(
      color: AppColors.slate50,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.map_outlined, size: 40, color: AppColors.slate300),
          SizedBox(height: 8),
          Text(
            'मैप पर जाएँ',
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
