/// The kind of EVM device.
enum DeviceKind {
  controlUnit,
  ballotUnit;

  String get code => this == DeviceKind.controlUnit ? 'CU' : 'BU';
  String get label =>
      this == DeviceKind.controlUnit ? 'Control Unit' : 'Ballot Unit';

  static DeviceKind fromName(String name) => DeviceKind.values.firstWhere(
    (DeviceKind k) => k.name == name,
    orElse: () => DeviceKind.controlUnit,
  );
}

/// Lifecycle status of a device record (mirrors the design's status pills).
enum DeviceStatus {
  registered,
  pending,
  inTransit,
  defective;

  String get key => switch (this) {
    DeviceStatus.registered => 'registered',
    DeviceStatus.pending => 'pending',
    DeviceStatus.inTransit => 'in_transit',
    DeviceStatus.defective => 'defective',
  };

  static DeviceStatus fromName(String name) => DeviceStatus.values.firstWhere(
    (DeviceStatus s) => s.name == name,
    orElse: () => DeviceStatus.pending,
  );
}

/// Immutable record for a single EVM device persisted in the local database.
class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.barcode,
    required this.box,
    required this.kind,
    required this.manufacturer,
    required this.status,
    required this.district,
    required this.officer,
    required this.timestamp,
  });

  factory DeviceRecord.fromJson(Map<String, dynamic> json) => DeviceRecord(
    id: json['id'] as String,
    barcode: json['barcode'] as String? ?? '',
    box: json['box'] as String? ?? 'Unassigned',
    kind: DeviceKind.fromName(json['kind'] as String? ?? 'controlUnit'),
    manufacturer: json['manufacturer'] as String? ?? 'BEL',
    status: DeviceStatus.fromName(json['status'] as String? ?? 'pending'),
    district: json['district'] as String? ?? 'Unassigned',
    officer: json['officer'] as String? ?? '—',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  final String id;
  final String barcode;
  final String box;
  final DeviceKind kind;
  final String manufacturer;
  final DeviceStatus status;
  final String district;
  final String officer;
  final DateTime timestamp;

  DeviceRecord copyWith({DeviceStatus? status}) => DeviceRecord(
    id: id,
    barcode: barcode,
    box: box,
    kind: kind,
    manufacturer: manufacturer,
    status: status ?? this.status,
    district: district,
    officer: officer,
    timestamp: timestamp,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'barcode': barcode,
    'box': box,
    'kind': kind.name,
    'manufacturer': manufacturer,
    'status': status.name,
    'district': district,
    'officer': officer,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Aggregated counters derived from the records, used by dashboards/inventory.
class DeviceStats {
  const DeviceStats({
    required this.total,
    required this.registered,
    required this.pending,
    required this.inTransit,
    required this.defective,
  });

  final int total;
  final int registered;
  final int pending;
  final int inTransit;
  final int defective;

  int get active => registered + inTransit;
  double get registeredPct => total == 0 ? 0 : registered / total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStats &&
          other.total == total &&
          other.registered == registered &&
          other.pending == pending &&
          other.inTransit == inTransit &&
          other.defective == defective;

  @override
  int get hashCode =>
      Object.hash(total, registered, pending, inTransit, defective);
}
