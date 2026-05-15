import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('updateThresholds');
      final res = await callable.call(updated.toJson());
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) throw StateError('Failed to update thresholds');
    } on FirebaseFunctionsException {
      rethrow;
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