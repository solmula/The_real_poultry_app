class ThresholdModel {
  final double tempFanLow;
  final double tempFanHigh;
  final double tempFanOff;
  final double tempHeatOn;
  final double tempHeatOff;
  final double nh3Warn;
  final double nh3High;
  final double nh3Critical;
  final double co2High;
  final double rhHigh;
  final double lightOnLux;
  final double lightDimLux;
  final double waterPumpOn;
  final double waterPumpOff;
  final double feedWarn;
  final double feedCritical;
  final int lightOnHour;
  final int lightOnMinute;
  final int lightOffHour;
  final int lightOffMinute;

  const ThresholdModel({
    this.tempFanLow = 25.0,
    this.tempFanHigh = 27.0,
    this.tempFanOff = 23.0,
    this.tempHeatOn = 16.0,
    this.tempHeatOff = 19.0,
    this.nh3Warn = 10.0,
    this.nh3High = 20.0,
    this.nh3Critical = 35.0,
    this.co2High = 3000.0,
    this.rhHigh = 72.0,
    this.lightOnLux = 10.0,
    this.lightDimLux = 20.0,
    this.waterPumpOn = 30.0,
    this.waterPumpOff = 70.0,
    this.feedWarn = 15.0,
    this.feedCritical = 8.0,
    this.lightOnHour = 5,
    this.lightOnMinute = 0,
    this.lightOffHour = 21,
    this.lightOffMinute = 0,
  });

  factory ThresholdModel.fromJson(Map<dynamic, dynamic> json) {
    return ThresholdModel(
      tempFanLow: _toDouble(json['temp_fan_low']) ?? 25.0,
      tempFanHigh: _toDouble(json['temp_fan_high']) ?? 27.0,
      tempFanOff: _toDouble(json['temp_fan_off']) ?? 23.0,
      tempHeatOn: _toDouble(json['temp_heat_on']) ?? 16.0,
      tempHeatOff: _toDouble(json['temp_heat_off']) ?? 19.0,
      nh3Warn: _toDouble(json['nh3_warn']) ?? 10.0,
      nh3High: _toDouble(json['nh3_high']) ?? 20.0,
      nh3Critical: _toDouble(json['nh3_critical']) ?? 35.0,
      co2High: _toDouble(json['co2_high']) ?? 3000.0,
      rhHigh: _toDouble(json['rh_high']) ?? 72.0,
      lightOnLux: _toDouble(json['light_on_lux']) ?? 10.0,
      lightDimLux: _toDouble(json['light_dim_lux']) ?? 20.0,
      waterPumpOn: _toDouble(json['water_pump_on']) ?? 30.0,
      waterPumpOff: _toDouble(json['water_pump_off']) ?? 70.0,
      feedWarn: _toDouble(json['feed_warn']) ?? 15.0,
      feedCritical: _toDouble(json['feed_critical']) ?? 8.0,
      lightOnHour: _toInt(json['light_on_hour']) ?? 5,
      lightOnMinute: _toInt(json['light_on_minute']) ?? 0,
      lightOffHour: _toInt(json['light_off_hour']) ?? 21,
      lightOffMinute: _toInt(json['light_off_minute']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'temp_fan_low': tempFanLow,
    'temp_fan_high': tempFanHigh,
    'temp_fan_off': tempFanOff,
    'temp_heat_on': tempHeatOn,
    'temp_heat_off': tempHeatOff,
    'nh3_warn': nh3Warn,
    'nh3_high': nh3High,
    'nh3_critical': nh3Critical,
    'co2_high': co2High,
    'rh_high': rhHigh,
    'light_on_lux': lightOnLux,
    'light_dim_lux': lightDimLux,
    'water_pump_on': waterPumpOn,
    'water_pump_off': waterPumpOff,
    'feed_warn': feedWarn,
    'feed_critical': feedCritical,
    'light_on_hour': lightOnHour,
    'light_on_minute': lightOnMinute,
    'light_off_hour': lightOffHour,
    'light_off_minute': lightOffMinute,
  };

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}