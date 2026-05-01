import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReport {
  final String date;
  final int totalEggs;
  final double layingRatePct;
  final double feedConsumedKg;
  final double fcr;
  final double avgTemp;
  final double maxNh3;
  final double lightHours;
  final int alertsCount;

  const DailyReport({
    required this.date,
    required this.totalEggs,
    required this.layingRatePct,
    required this.feedConsumedKg,
    required this.fcr,
    required this.avgTemp,
    required this.maxNh3,
    required this.lightHours,
    required this.alertsCount,
  });

  factory DailyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyReport(
      date: data['date']?.toString() ?? '',
      totalEggs: _toInt(data['total_eggs']) ?? 0,
      layingRatePct: _toDouble(data['laying_rate_pct']) ?? 0.0,
      feedConsumedKg: _toDouble(data['feed_consumed_kg']) ?? 0.0,
      fcr: _toDouble(data['fcr']) ?? 0.0,
      avgTemp: _toDouble(data['avg_temp']) ?? 0.0,
      maxNh3: _toDouble(data['max_nh3']) ?? 0.0,
      lightHours: _toDouble(data['light_hours']) ?? 0.0,
      alertsCount: _toInt(data['alerts_count']) ?? 0,
    );
  }

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