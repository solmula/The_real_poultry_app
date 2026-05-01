class AlertModel {
  final String id;
  final String type;
  final double? value;
  final double? threshold;
  final String severity;
  final int timestamp;
  final bool acked;
  final String? ackedBy;
  final int? ackedAt;

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.acked,
    this.value,
    this.threshold,
    this.ackedBy,
    this.ackedAt,
  });

  factory AlertModel.fromJson(String id, Map<dynamic, dynamic> json) {
    return AlertModel(
      id: id,
      type: json['type']?.toString() ?? 'UNKNOWN',
      value: _toDouble(json['value']),
      threshold: _toDouble(json['threshold']),
      severity: json['severity']?.toString() ?? 'INFO',
      timestamp: json['timestamp'] as int? ?? 0,
      acked: json['acked'] as bool? ?? false,
      ackedBy: json['acked_by']?.toString(),
      ackedAt: json['acked_at'] as int?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String get displayText {
    switch (type) {
      case 'TEMP_HIGH': return 'House temperature above safe limit for laying hens';
      case 'TEMP_CRITICAL': return 'Critical temperature — heat stress risk to flock';
      case 'TEMP_LOW': return 'House temperature below recommended minimum';
      case 'TEMP_CRITICAL_LOW': return 'Critical low temperature — cold stress risk';
      case 'HUMIDITY_HIGH': return 'High humidity — risk of eggshell softening';
      case 'HUMIDITY_CRITICAL': return 'Critical humidity — maximum ventilation triggered';
      case 'NH3_ELEVATED': return 'Ammonia elevated — monitor ventilation';
      case 'NH3_HIGH': return 'Ammonia above legal limit — fans at maximum';
      case 'NH3_CRITICAL': return 'Critical ammonia level — manual intervention required';
      case 'CO2_HIGH': return 'CO2 elevated — ventilation increased';
      case 'AIR_QUALITY_COMPOUND': return 'Combined gas alert — maximum ventilation triggered';
      case 'LIGHT_DURATION_LOW': return 'Daily light hours below 14h — laying rate at risk';
      case 'WATER_CRITICAL': return 'Water critically low — check pump immediately';
      case 'PUMP_FAULT': return 'Water pump not responding — manual check required';
      case 'HOPPER_LOW': return 'Feed hopper below 20% — schedule refill';
      case 'HOPPER_CRITICAL': return 'Feed hopper critically low — auto-feed suspended';
      case 'CHAIN_JAM': return 'Chain feeder jam detected — motor stopped';
      case 'FEEDER_FAULT': return 'Feeder cycle did not complete — check trough';
      case 'NO_EGGS_2H': return 'No eggs detected on belt for 2 hours';
      case 'MANURE_BLOCKAGE': return 'Manure belt may be blocked — manual inspection';
      case 'SLAVE2_OFFLINE': return 'ESP32 Node B offline — egg, manure, and feeder data unavailable';
      case 'SLAVE1_OFFLINE': return 'ESP32 Node B offline — feed and water data unavailable';
      case 'SHT85_FAULT': return 'Temperature sensor fault — using remaining sensors';
      case 'ZE03_FAULT': return 'Ammonia sensor fault — ventilation set to HIGH as precaution';
      case 'SCD41_FAULT': return 'CO2 sensor fault — CO2 monitoring unavailable';
      default: return type.replaceAll('_', ' ');
    }
  }

  String get parameterLabel {
    switch (type) {
      case 'TEMP_HIGH':
      case 'TEMP_CRITICAL':
      case 'TEMP_LOW':
      case 'TEMP_CRITICAL_LOW':
      case 'SHT85_FAULT': return 'Temperature';
      case 'HUMIDITY_HIGH':
      case 'HUMIDITY_CRITICAL': return 'Humidity';
      case 'NH3_ELEVATED':
      case 'NH3_HIGH':
      case 'NH3_CRITICAL':
      case 'ZE03_FAULT': return 'NH3';
      case 'CO2_HIGH':
      case 'SCD41_FAULT': return 'CO2';
      case 'AIR_QUALITY_COMPOUND': return 'Air Quality';
      case 'LIGHT_DURATION_LOW': return 'Light Hours';
      case 'WATER_CRITICAL':
      case 'PUMP_FAULT': return 'Water';
      case 'HOPPER_LOW':
      case 'HOPPER_CRITICAL':
      case 'CHAIN_JAM':
      case 'FEEDER_FAULT': return 'Feed';
      case 'NO_EGGS_2H': return 'Egg Collection';
      case 'MANURE_BLOCKAGE': return 'Manure Belt';
      case 'SLAVE1_OFFLINE':
      case 'SLAVE2_OFFLINE': return 'Node B';
      default: return 'System';
    }
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}