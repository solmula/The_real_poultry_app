import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/flock_defaults.dart';

class FlockConfig {
  final String? id;
  final String? farmId;
  final String? houseId;
  final String? name;
  final int? initialBirdCount;
  final int? activeBirdCount;
  final int? mortalityCount;
  final double? feedKgPerBirdPerDay;
  final double? waterLitersPerBirdPerDay;
  final bool isActive;
  final DateTime? updatedAt;

  const FlockConfig({
    this.id,
    this.farmId,
    this.houseId,
    this.name,
    this.initialBirdCount,
    this.activeBirdCount,
    this.mortalityCount,
    this.feedKgPerBirdPerDay,
    this.waterLitersPerBirdPerDay,
    this.isActive = true,
    this.updatedAt,
  });

  factory FlockConfig.empty() {
    return const FlockConfig(isActive: false);
  }

  factory FlockConfig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return FlockConfig.empty();
    }
    return FlockConfig.fromMap(data, id: doc.id);
  }

  factory FlockConfig.fromMap(Map<String, dynamic> json, {String? id}) {
    return FlockConfig(
      id: id ?? json['id']?.toString(),
      farmId: json['farm_id']?.toString(),
      houseId: json['house_id']?.toString(),
      name: json['name']?.toString(),
      initialBirdCount: _toInt(json['initial_bird_count']),
      activeBirdCount: _toInt(json['active_bird_count']),
      mortalityCount: _toInt(json['mortality_count']),
      feedKgPerBirdPerDay: _toDouble(json['feed_kg_per_bird_per_day']),
      waterLitersPerBirdPerDay: _toDouble(json['water_liters_per_bird_per_day']),
      isActive: json['is_active'] != false,
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  bool get isConfigured =>
      initialBirdCount != null || activeBirdCount != null || mortalityCount != null;

  int? get effectiveBirdCount {
    final active = activeBirdCount;
    if (active != null) {
      return max(0, active);
    }

    final initial = initialBirdCount;
    if (initial == null) {
      return null;
    }

    final mortalities = mortalityCount ?? 0;
    return max(0, initial - mortalities);
  }

  bool get isEmptyFlock => effectiveBirdCount == 0;

  double? get mortalityRatePercent {
    final initial = initialBirdCount;
    final mortalities = mortalityCount;
    if (initial == null || mortalities == null || initial <= 0) {
      return null;
    }
    return (mortalities.clamp(0, initial) / initial) * 100.0;
  }

  double? estimatedDailyFeedKg({double? overridePerBirdKg}) {
    final birds = effectiveBirdCount;
    if (birds == null) {
      return null;
    }
    if (birds <= 0) {
      return 0.0;
    }

    final rate = overridePerBirdKg ??
        feedKgPerBirdPerDay ??
        FlockDefaults.feedKgPerBirdPerDay;
    return birds * rate;
  }

  double? estimatedDailyWaterLiters({double? overridePerBirdLiters}) {
    final birds = effectiveBirdCount;
    if (birds == null) {
      return null;
    }
    if (birds <= 0) {
      return 0.0;
    }

    final rate = overridePerBirdLiters ??
        waterLitersPerBirdPerDay ??
        FlockDefaults.waterLitersPerBirdPerDay;
    return birds * rate;
  }

  double? layingRatePercent(int? eggCount) {
    final birds = effectiveBirdCount;
    if (eggCount == null || birds == null || birds <= 0) {
      return null;
    }
    return (eggCount / birds) * 100.0;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      final millis = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
