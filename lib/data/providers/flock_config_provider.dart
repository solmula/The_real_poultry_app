import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_paths.dart';
import '../models/flock_config.dart';

class FlockConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FlockConfig? _config;
  String? _activeFlockId;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _flockSubscription;

  FlockConfig? get config => _config;
  String? get activeFlockId => _activeFlockId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasConfig => _config != null;

  void startListening() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _settingsSubscription?.cancel();
    _settingsSubscription = _firestore
        .collection(FirebasePaths.flockSettingsCollection)
        .doc(FirebasePaths.flockSettingsCurrentDoc)
        .snapshots()
        .listen(
      (snapshot) {
        final nextActiveFlockId = snapshot.data()?['active_flock_id']?.toString().trim();
        if (nextActiveFlockId == null || nextActiveFlockId.isEmpty) {
          _activeFlockId = null;
          _setConfig(null, error: 'No active flock is configured.');
          _subscribeToActiveFlock(null);
          return;
        }

        if (nextActiveFlockId != _activeFlockId) {
          _activeFlockId = nextActiveFlockId;
          _subscribeToActiveFlock(nextActiveFlockId);
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _setConfig(null, error: 'Failed to load flock settings');
      },
    );
  }

  void _subscribeToActiveFlock(String? flockId) {
    _flockSubscription?.cancel();
    _flockSubscription = null;

    if (flockId == null) {
      _setConfig(null);
      return;
    }

    _flockSubscription = _firestore
        .collection(FirebasePaths.flocksCollection)
        .doc(flockId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          _setConfig(null, error: 'The active flock was deleted or is unavailable.');
          return;
        }

        _setConfig(FlockConfig.fromFirestore(snapshot));
      },
      onError: (error) {
        _setConfig(null, error: 'Failed to load active flock configuration');
      },
    );
  }

  void _setConfig(FlockConfig? config, {String? error}) {
    _config = config;
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void stopListening() {
    _settingsSubscription?.cancel();
    _flockSubscription?.cancel();
    _settingsSubscription = null;
    _flockSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
