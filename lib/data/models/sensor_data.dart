class SensorData {
  final double? tempAvg;
  final double? tempMin;
  final double? tempMax;
  final double? tempZ1;
  final double? tempZ2;
  final double? tempZ3;
  final double? rhAvg;
  final double? nh3Max;
  final double? co2Avg;
  final double? lightAvg;
  final String? fanSpeed;
  final bool? heater;
  final String? lights;
  final double? h1WaterPct;
  final String? h1PumpState;
  final double? h1FeedKg;
  final double? h1FeedPct;
  final double? h2WaterPct;
  final String? h2PumpState;
  final double? h2FeedKg;
  final double? h2FeedPct;
  final int? h1LeftT1;
  final int? h1LeftT2;
  final int? h1LeftT3;
  final int? h1LeftT4;
  final int? h1RightT1;
  final int? h1RightT2;
  final int? h1RightT3;
  final int? h1RightT4;
  final int? h2LeftT1;
  final int? h2LeftT2;
  final int? h2LeftT3;
  final int? h2LeftT4;
  final int? h2RightT1;
  final int? h2RightT2;
  final int? h2RightT3;
  final int? h2RightT4;
  final int? totalToday;
  final double? layingRate;
  final int? h1TotalToday;
  final int? h2TotalToday;
  final double? h2LayingRate;
  final String? h1T1ManureState;
  final String? h1T2ManureState;
  final String? h1T3ManureState;
  final String? h1T4ManureState;
  final String? h2T1ManureState;
  final String? h2T2ManureState;
  final String? h2T3ManureState;
  final String? h2T4ManureState;
  final bool? nodeAOnline;
  final bool? nodeBOnline;
  final String? firmwareVer;
  final double? uptimeHours;
  final double? heapFreeKb;
  final String? nodeBFirmware;
  final double? nodeBUptimeHours;
  final int? nodeBLastHeartbeat;
  final int? timestamp;

  const SensorData({
    this.tempAvg, this.tempMin, this.tempMax,
    this.tempZ1, this.tempZ2, this.tempZ3,
    this.rhAvg, this.nh3Max, this.co2Avg,
    this.lightAvg, this.fanSpeed, this.heater, this.lights,
    this.h1WaterPct, this.h1PumpState, this.h1FeedKg, this.h1FeedPct,
    this.h2WaterPct, this.h2PumpState, this.h2FeedKg, this.h2FeedPct,
    this.h1LeftT1, this.h1LeftT2, this.h1LeftT3, this.h1LeftT4,
    this.h1RightT1, this.h1RightT2, this.h1RightT3, this.h1RightT4,
    this.h2LeftT1, this.h2LeftT2, this.h2LeftT3, this.h2LeftT4,
    this.h2RightT1, this.h2RightT2, this.h2RightT3, this.h2RightT4,
    this.totalToday, this.layingRate,
    this.h1TotalToday, this.h2TotalToday, this.h2LayingRate,
    this.h1T1ManureState, this.h1T2ManureState,
    this.h1T3ManureState, this.h1T4ManureState,
    this.h2T1ManureState, this.h2T2ManureState,
    this.h2T3ManureState, this.h2T4ManureState,
    this.nodeAOnline, this.nodeBOnline, this.firmwareVer,
    this.uptimeHours, this.heapFreeKb, this.nodeBFirmware,
    this.nodeBUptimeHours, this.nodeBLastHeartbeat,
    this.timestamp,
  });

  // ─── Tier helpers ────────────────────────────────────────────────────────
  int? h1TierLeft(int tier) {
    switch (tier) {
      case 1: return h1LeftT1;
      case 2: return h1LeftT2;
      case 3: return h1LeftT3;
      case 4: return h1LeftT4;
      default: return null;
    }
  }

  int? h1TierRight(int tier) {
    switch (tier) {
      case 1: return h1RightT1;
      case 2: return h1RightT2;
      case 3: return h1RightT3;
      case 4: return h1RightT4;
      default: return null;
    }
  }

  int? h2TierLeft(int tier) {
    switch (tier) {
      case 1: return h2LeftT1;
      case 2: return h2LeftT2;
      case 3: return h2LeftT3;
      case 4: return h2LeftT4;
      default: return null;
    }
  }

  int? h2TierRight(int tier) {
    switch (tier) {
      case 1: return h2RightT1;
      case 2: return h2RightT2;
      case 3: return h2RightT3;
      case 4: return h2RightT4;
      default: return null;
    }
  }

  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    Map<dynamic, dynamic> climate = json['climate'] ?? {};
    Map<dynamic, dynamic> h1 = json['h1'] ?? {};
    Map<dynamic, dynamic> h2 = json['h2'] ?? {};
    Map<dynamic, dynamic> eggsMap = json['eggs'] ?? {};
    Map<dynamic, dynamic> manureMap = json['manure'] ?? {};
    Map<dynamic, dynamic> systemMap = json['system'] ?? {};

    return SensorData(
      tempAvg: _toDouble(climate['temp_avg']),
      tempMin: _toDouble(climate['temp_min']),
      tempMax: _toDouble(climate['temp_max']),
      tempZ1: _toDouble(climate['temp_z1']),
      tempZ2: _toDouble(climate['temp_z2']),
      tempZ3: _toDouble(climate['temp_z3']),
      rhAvg: _toDouble(climate['rh_avg']),
      nh3Max: _toDouble(climate['nh3_max']),
      co2Avg: _toDouble(climate['co2_avg']),
      lightAvg: _toDouble(climate['light_avg']),
      fanSpeed: climate['fan_speed']?.toString(),
      heater: climate['heater'] as bool?,
      lights: climate['lights']?.toString(),
      h1WaterPct: _toDouble(h1['water_pct']),
      h1PumpState: h1['pump_state']?.toString(),
      h1FeedKg: _toDouble(h1['feed_kg']),
      h1FeedPct: _toDouble(h1['feed_pct']),
      h2WaterPct: _toDouble(h2['water_pct']),
      h2PumpState: h2['pump_state']?.toString(),
      h2FeedKg: _toDouble(h2['feed_kg']),
      h2FeedPct: _toDouble(h2['feed_pct']),
      h1LeftT1: _toInt(eggsMap['h1_left_t1']),
      h1LeftT2: _toInt(eggsMap['h1_left_t2']),
      h1LeftT3: _toInt(eggsMap['h1_left_t3']),
      h1LeftT4: _toInt(eggsMap['h1_left_t4']),
      h1RightT1: _toInt(eggsMap['h1_right_t1']),
      h1RightT2: _toInt(eggsMap['h1_right_t2']),
      h1RightT3: _toInt(eggsMap['h1_right_t3']),
      h1RightT4: _toInt(eggsMap['h1_right_t4']),
      h2LeftT1: _toInt(eggsMap['h2_left_t1']),
      h2LeftT2: _toInt(eggsMap['h2_left_t2']),
      h2LeftT3: _toInt(eggsMap['h2_left_t3']),
      h2LeftT4: _toInt(eggsMap['h2_left_t4']),
      h2RightT1: _toInt(eggsMap['h2_right_t1']),
      h2RightT2: _toInt(eggsMap['h2_right_t2']),
      h2RightT3: _toInt(eggsMap['h2_right_t3']),
      h2RightT4: _toInt(eggsMap['h2_right_t4']),
      totalToday: _toInt(eggsMap['total_today']),
      layingRate: _toDouble(eggsMap['laying_rate']),
      h1TotalToday: _toInt(eggsMap['h1_total_today']),
      h2TotalToday: _toInt(eggsMap['h2_total_today']),
      h2LayingRate: _toDouble(eggsMap['h2_laying_rate']),
      h1T1ManureState: manureMap['h1_t1_state']?.toString(),
      h1T2ManureState: manureMap['h1_t2_state']?.toString(),
      h1T3ManureState: manureMap['h1_t3_state']?.toString(),
      h1T4ManureState: manureMap['h1_t4_state']?.toString(),
      h2T1ManureState: manureMap['h2_t1_state']?.toString(),
      h2T2ManureState: manureMap['h2_t2_state']?.toString(),
      h2T3ManureState: manureMap['h2_t3_state']?.toString(),
      h2T4ManureState: manureMap['h2_t4_state']?.toString(),
      nodeAOnline: systemMap['node_a_online'] as bool?,
      nodeBOnline: systemMap['node_b_online'] as bool?,
      firmwareVer: systemMap['firmware_ver']?.toString(),
      uptimeHours: _toDouble(systemMap['uptime_hours']),
      heapFreeKb: _toDouble(systemMap['heap_free_kb']),
      nodeBFirmware: systemMap['node_b_firmware']?.toString(),
      nodeBUptimeHours: _toDouble(systemMap['node_b_uptime_hours']),
      nodeBLastHeartbeat: _toInt(systemMap['node_b_last_heartbeat']),
      timestamp: _toInt(json['timestamp']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool get isStale {
    if (timestamp == null) return true;
    final dataTime = DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000);
    return DateTime.now().difference(dataTime).inMinutes >= 5;
  }

  String get lastUpdateText {
    if (timestamp == null) return 'Never';
    final ts = timestamp! > 9999999999
        ? timestamp!
        : timestamp! * 1000;
    final dataTime = DateTime.fromMillisecondsSinceEpoch(ts);
    final diff = DateTime.now().difference(dataTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}