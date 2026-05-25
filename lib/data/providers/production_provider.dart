import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_paths.dart';
import '../models/daily_report.dart';
import '../models/flock_config.dart';

class ProductionProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductionEggData? _todayEggs;
  double? _todayH1FeedKg;
  double? _todayH2FeedKg;
  List<DailyReport> _historyReports = [];
  FlockConfig? _flockConfig;
  bool _isLoadingToday = true;
  bool _isLoadingHistory = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _todaySubscription;
  StreamSubscription<DatabaseEvent>? _h1Subscription;
  StreamSubscription<DatabaseEvent>? _h2Subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _historySubscription;

  ProductionProvider() {
    startListening();
  }

  ProductionEggData? get todayEggs => _todayEggs;
  List<DailyReport> get historyReports => _historyReports;
  bool get isLoadingToday => _isLoadingToday;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoading => _isLoadingToday && _isLoadingHistory;
  String? get error => _error;

  DailyReport? get latestReport =>
      _historyReports.isNotEmpty ? _historyReports.first : null;

  String _todayDateString() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  int? get todayTotalEggs => _todayEggs?.totalToday;

  FlockConfig? get flockConfig => _flockConfig;
  int? get activeBirdCount => _flockConfig?.effectiveBirdCount;
  double? get mortalityRatePercent => _flockConfig?.mortalityRatePercent;
  double? get estimatedDailyFeedKg => _flockConfig?.estimatedDailyFeedKg();
  double? get estimatedDailyWaterLiters => _flockConfig?.estimatedDailyWaterLiters();

  void setFlockConfig(FlockConfig? config) {
    final previousId = _flockConfig?.id;
    final nextId = config?.id;
    final previousBirds = _flockConfig?.effectiveBirdCount;
    final nextBirds = config?.effectiveBirdCount;
    if (previousId == nextId && previousBirds == nextBirds) {
      return;
    }
    _flockConfig = config;
    notifyListeners();
  }

  double? get todayLayingRate {
    final eggCount = _todayEggs?.totalToday;
    if (eggCount == null || eggCount <= 0) return null;

    final birdCount = activeBirdCount;
    if (birdCount != null && birdCount > 0) {
      return (eggCount / birdCount) * 100.0;
    }

    return _todayEggs?.layingRate;
  }

  double? get todayH1LayingRate {
    // Note: divides by total flock bird count, not per-house count.
    // This gives percentage of total flock laying in this house, not per-house laying rate.
    final h1Count = _todayEggs?.h1TotalToday;
    final birdCount = activeBirdCount;
    if (h1Count == null || birdCount == null || birdCount <= 0) return null;
    return (h1Count / birdCount) * 100.0;
  }

  double? get todayH2LayingRate {
    // Note: divides by total flock bird count, not per-house count.
    // This gives percentage of total flock laying in this house, not per-house laying rate.
    final h2Count = _todayEggs?.h2TotalToday;
    final birdCount = activeBirdCount;
    if (h2Count == null || birdCount == null || birdCount <= 0) return null;
    return (h2Count / birdCount) * 100.0;
  }

  double? get todayFeedConsumedKg {
    if (_todayH1FeedKg == null && _todayH2FeedKg == null) return null;
    return (_todayH1FeedKg ?? 0.0) + (_todayH2FeedKg ?? 0.0);
  }

  /// Today's FCR calculated from current feed consumed and egg total.
  /// FCR = feed (kg) / (total eggs × 0.06 kg per egg)
  double? get todayFcr {
    final feedConsumed = todayFeedConsumedKg;
    final eggs = todayTotalEggs;
    if (feedConsumed == null || eggs == null || eggs <= 0) return null;
    return feedConsumed / (eggs * 0.06);
  }

  /// Returns yesterday's FCR because today's daily report has not yet been archived.
  /// Uses latestReport.feedConsumedKg which is the most recently archived daily record.
  double? get yesterdayFcr {
    final report = latestReport;
    if (report == null || report.totalEggs <= 0) return null;
    return report.feedConsumedKg / (report.totalEggs * 0.06);
  }

  double? get sevenDayAverageEggs {
    if (_historyReports.isEmpty) return null;
    final total = _historyReports.fold<int>(0, (sum, report) => sum + report.totalEggs);
    return total / 7.0;  // Always divide by 7 for true 7-day average
  }

  double? get eggTrendPercent {
    if (_historyReports.length < 2) return null;
    final latest = _historyReports.first.totalEggs;
    final previous = _historyReports[1].totalEggs;
    if (previous <= 0) return null;
    return ((latest - previous) / previous) * 100.0;
  }

  void startListening() {
    _error = null;

    _todaySubscription?.cancel();
    _todaySubscription = _db.ref(FirebasePaths.eggs).onValue.listen(
      (event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          try {
            final json = event.snapshot.value as Map<dynamic, dynamic>;
            _todayEggs = ProductionEggData.fromJson(json);
          } catch (e) {
            _error = 'Failed to parse production data';
          }
        } else {
          _todayEggs = null;
        }
        _isLoadingToday = false;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load today\'s production data';
        _isLoadingToday = false;
        notifyListeners();
      },
    );

    _h1Subscription?.cancel();
    _h1Subscription = _db.ref(FirebasePaths.h1).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final json = event.snapshot.value as Map<dynamic, dynamic>;
          final v = json['feed_kg'];
          _todayH1FeedKg = v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0');
        } catch (e) {
          _todayH1FeedKg = null;
        }
      } else {
        _todayH1FeedKg = null;
      }
      notifyListeners();
    }, onError: (err) {
      _error = 'Failed to load H1 feed data';
      notifyListeners();
    });

    _h2Subscription?.cancel();
    _h2Subscription = _db.ref(FirebasePaths.h2).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final json = event.snapshot.value as Map<dynamic, dynamic>;
          final v = json['feed_kg'];
          _todayH2FeedKg = v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0');
        } catch (e) {
          _todayH2FeedKg = null;
        }
      } else {
        _todayH2FeedKg = null;
      }
      notifyListeners();
    }, onError: (err) {
      _error = 'Failed to load H2 feed data';
      notifyListeners();
    });

    _historySubscription?.cancel();
    _historySubscription = _firestore
        .collection(FirebasePaths.dailyReports)
        .where('date', isLessThan: _todayDateString())
        .orderBy('date', descending: true)
        .limit(7)
        .snapshots()
        .listen(
      (snapshot) {
        _historyReports = snapshot.docs
            .map((doc) => DailyReport.fromFirestore(doc))
            .toList();
        _isLoadingHistory = false;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load production history';
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }

  List<ProductionBeltSlot> get beltSlots {
    final d = _todayEggs;
    if (d == null) return const [];

    return [
      ProductionBeltSlot(label: 'H1 T1 L', value: d.h1LeftT1),
      ProductionBeltSlot(label: 'H1 T1 R', value: d.h1RightT1),
      ProductionBeltSlot(label: 'H1 T2 L', value: d.h1LeftT2),
      ProductionBeltSlot(label: 'H1 T2 R', value: d.h1RightT2),
      ProductionBeltSlot(label: 'H1 T3 L', value: d.h1LeftT3),
      ProductionBeltSlot(label: 'H1 T3 R', value: d.h1RightT3),
      ProductionBeltSlot(label: 'H1 T4 L', value: d.h1LeftT4),
      ProductionBeltSlot(label: 'H1 T4 R', value: d.h1RightT4),
      ProductionBeltSlot(label: 'H2 T1 L', value: d.h2LeftT1),
      ProductionBeltSlot(label: 'H2 T1 R', value: d.h2RightT1),
      ProductionBeltSlot(label: 'H2 T2 L', value: d.h2LeftT2),
      ProductionBeltSlot(label: 'H2 T2 R', value: d.h2RightT2),
      ProductionBeltSlot(label: 'H2 T3 L', value: d.h2LeftT3),
      ProductionBeltSlot(label: 'H2 T3 R', value: d.h2RightT3),
      ProductionBeltSlot(label: 'H2 T4 L', value: d.h2LeftT4),
      ProductionBeltSlot(label: 'H2 T4 R', value: d.h2RightT4),
    ];
  }

  void stopListening() {
    _todaySubscription?.cancel();
    _historySubscription?.cancel();
    _h1Subscription?.cancel();
    _h2Subscription?.cancel();
    _todaySubscription = null;
    _historySubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

class ProductionEggData {
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

  const ProductionEggData({
    this.h1LeftT1,
    this.h1LeftT2,
    this.h1LeftT3,
    this.h1LeftT4,
    this.h1RightT1,
    this.h1RightT2,
    this.h1RightT3,
    this.h1RightT4,
    this.h2LeftT1,
    this.h2LeftT2,
    this.h2LeftT3,
    this.h2LeftT4,
    this.h2RightT1,
    this.h2RightT2,
    this.h2RightT3,
    this.h2RightT4,
  });

  int get h1TotalToday {
    return (h1LeftT1 ?? 0) + (h1LeftT2 ?? 0) + (h1LeftT3 ?? 0) + (h1LeftT4 ?? 0) +
        (h1RightT1 ?? 0) + (h1RightT2 ?? 0) + (h1RightT3 ?? 0) + (h1RightT4 ?? 0);
  }

  int get h2TotalToday {
    return (h2LeftT1 ?? 0) + (h2LeftT2 ?? 0) + (h2LeftT3 ?? 0) + (h2LeftT4 ?? 0) +
        (h2RightT1 ?? 0) + (h2RightT2 ?? 0) + (h2RightT3 ?? 0) + (h2RightT4 ?? 0);
  }

  int get totalToday => h1TotalToday + h2TotalToday;

  double get layingRate {
    const int totalBirds = 1040;
    final rate = (totalToday / totalBirds) * 100.0;
    return double.parse(rate.toStringAsFixed(1));
  }

  factory ProductionEggData.fromJson(Map<dynamic, dynamic> json) {
    final eggs = json['eggs'] is Map ? json['eggs'] as Map<dynamic, dynamic> : json;

    return ProductionEggData(
      h1LeftT1: _toInt(eggs['h1_left_t1']),
      h1LeftT2: _toInt(eggs['h1_left_t2']),
      h1LeftT3: _toInt(eggs['h1_left_t3']),
      h1LeftT4: _toInt(eggs['h1_left_t4']),
      h1RightT1: _toInt(eggs['h1_right_t1']),
      h1RightT2: _toInt(eggs['h1_right_t2']),
      h1RightT3: _toInt(eggs['h1_right_t3']),
      h1RightT4: _toInt(eggs['h1_right_t4']),
      h2LeftT1: _toInt(eggs['h2_left_t1']),
      h2LeftT2: _toInt(eggs['h2_left_t2']),
      h2LeftT3: _toInt(eggs['h2_left_t3']),
      h2LeftT4: _toInt(eggs['h2_left_t4']),
      h2RightT1: _toInt(eggs['h2_right_t1']),
      h2RightT2: _toInt(eggs['h2_right_t2']),
      h2RightT3: _toInt(eggs['h2_right_t3']),
      h2RightT4: _toInt(eggs['h2_right_t4']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ProductionBeltSlot {
  final String label;
  final int? value;

  const ProductionBeltSlot({required this.label, required this.value});
}