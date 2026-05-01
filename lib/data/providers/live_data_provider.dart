import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../../core/constants/firebase_paths.dart';

class LiveDataProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  SensorData? _data;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _subscription;

  SensorData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStale => _data?.isStale ?? true;
  String get lastUpdateText => _data?.lastUpdateText ?? 'Never';

  void startListening() {
    _isLoading = true;
    notifyListeners();
    _subscription = _db.ref(FirebasePaths.live).onValue.listen(
      (event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          try {
            final json = event.snapshot.value as Map<dynamic, dynamic>;
            _data = SensorData.fromJson(json);
            _error = null;
          } catch (e) {
            _error = 'Failed to parse sensor data';
          }
        } else {
          _error = 'No data available';
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Connection error — showing last known data';
        _isLoading = false;
        notifyListeners();
      },
    );
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