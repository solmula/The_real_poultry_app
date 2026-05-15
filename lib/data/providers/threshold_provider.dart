import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/threshold_model.dart';
import '../../core/constants/firebase_paths.dart';

class ThresholdProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  ThresholdModel _thresholds = const ThresholdModel();
  StreamSubscription<DatabaseEvent>? _subscription;

  ThresholdModel get thresholds => _thresholds;

  void startListening() {
    _subscription = _db.ref(FirebasePaths.thresholds).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final json = event.snapshot.value as Map<dynamic, dynamic>;
          _thresholds = ThresholdModel.fromJson(json);
          notifyListeners();
        } catch (e) {}
      }
    });
  }

  Future<void> saveThresholds(ThresholdModel updated) async {
    try {
      await _db.ref(FirebasePaths.thresholds).set(updated.toJson());
    } catch (e) {
      rethrow;
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}