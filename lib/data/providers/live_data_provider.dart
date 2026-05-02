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
  Timer? _loadingTimeout;

  SensorData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStale => _data?.isStale ?? true;
  String get lastUpdateText => _data?.lastUpdateText ?? 'Never';

  void startListening() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // ── Timeout: if no data arrives in 5 seconds, stop spinner ───────────
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 5), () {
      if (_isLoading) {
        _isLoading = false;
        if (_data == null) {
          _error = 'No internet connection — showing last known data';
        }
        notifyListeners();
      }
    });

    _subscription?.cancel();
    _subscription = _db.ref(FirebasePaths.live).onValue.listen(
      (event) {
        _loadingTimeout?.cancel();
        if (event.snapshot.exists && event.snapshot.value != null) {
          try {
            final json = event.snapshot.value as Map<dynamic, dynamic>;
            _data = SensorData.fromJson(json);
            _error = null;
          } catch (e) {
            _error = 'Failed to parse sensor data';
          }
        } else {
          if (_data == null) {
            _error = 'No data available';
          }
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _loadingTimeout?.cancel();
        _error = 'Connection error — showing last known data';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}