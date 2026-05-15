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
  List<DailyReport> _historyReports = [];
  FlockConfig? _flockConfig;
  bool _isLoadingToday = true;
  bool _isLoadingHistory = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _todaySubscription;
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

  int? get todayTotalEggs => _todayEggs?.totalToday ?? latestReport?.totalEggs;

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
    if (birdCount == null) {
      return latestReport?.layingRatePct;
    }
    if (birdCount <= 0) return null;
    return (eggCount / birdCount) * 100.0;
  }

  double? get todayFeedConsumedKg => latestReport?.feedConsumedKg;

  double? get todayFcr {
    final report = latestReport;
    if (report == null || report.totalEggs <= 0) return null;
    return report.feedConsumedKg / (report.totalEggs * 0.06);
  }

  double? get sevenDayAverageEggs {
    if (_historyReports.isEmpty) return null;
    final total = _historyReports.fold<int>(0, (sum, report) => sum + report.totalEggs);
    return total / _historyReports.length;
  }

  double? get eggTrendPercent {
    final today = todayTotalEggs;
    final average = sevenDayAverageEggs;
    if (today == null || average == null || average == 0) return null;
    return ((today - average) / average) * 100;
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

    _historySubscription?.cancel();
    _historySubscription = _firestore
        .collection(FirebasePaths.dailyReports)
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
  final int? totalToday;
  final int? h1TotalToday;
  final int? h2TotalToday;
  final double? layingRate;
  final double? h2LayingRate;

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
    this.totalToday,
    this.h1TotalToday,
    this.h2TotalToday,
    this.layingRate,
    this.h2LayingRate,
  });

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
      totalToday: _toInt(eggs['total_today']),
      h1TotalToday: _toInt(eggs['h1_total_today']),
      h2TotalToday: _toInt(eggs['h2_total_today']),
      layingRate: _toDouble(eggs['laying_rate']),
      h2LayingRate: _toDouble(eggs['h2_laying_rate']),
    );
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
}

class ProductionBeltSlot {
  final String label;
  final int? value;

  const ProductionBeltSlot({required this.label, required this.value});
}