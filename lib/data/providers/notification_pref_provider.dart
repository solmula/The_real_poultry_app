import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPrefProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  String? _uid;
  bool _isLoading = true;
  String? _error;
  bool _critical = true;
  bool _high = true;
  bool _warning = true;
  bool _info = true;

  NotificationPrefProvider() {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _handleAuthChanged(_auth.currentUser);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get critical => _critical;
  bool get high => _high;
  bool get warning => _warning;
  bool get info => _info;

  Map<String, bool> get preferences => {
        'CRITICAL': true,
        'HIGH': _high,
        'WARNING': _warning,
        'INFO': _info,
      };

  Future<void> _handleAuthChanged(User? user) async {
    _uid = user?.uid;
    if (user == null) {
      _isLoading = false;
      _error = null;
      _critical = true;
      _high = true;
      _warning = true;
      _info = true;
      notifyListeners();
      return;
    }

    await loadPreferences();
  }

  Future<void> loadPreferences() async {
    final uid = _uid ?? _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      _error = 'No signed-in user';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      final farmId = doc.data()?['farm_id']?.toString();

      final rawPrefs = doc.data()?['notification_prefs'];
      final prefs = rawPrefs is Map ? rawPrefs : const <String, dynamic>{};

      _critical = true;
      _high = _toBool(prefs['HIGH']) ?? true;
      _warning = _toBool(prefs['WARNING']) ?? true;
      _info = _toBool(prefs['INFO']) ?? true;

      // Only write to Firestore if at least one preference differs from its default value
      final shouldWrite = _high != true || _warning != true || _info != true;
      if (shouldWrite) {
        await docRef.set(
          {
            if (farmId != null) 'farm_id': farmId,
            'notification_prefs': {
              'CRITICAL': true,
              'HIGH': _high,
              'WARNING': _warning,
              'INFO': _info,
            },
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      _error = 'Failed to load notification preferences';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setHigh(bool value) => _updatePreference('HIGH', value);

  Future<void> setWarning(bool value) => _updatePreference('WARNING', value);

  Future<void> setInfo(bool value) => _updatePreference('INFO', value);

  Future<void> _updatePreference(String key, bool value) async {
    final uid = _uid ?? _auth.currentUser?.uid;
    if (uid == null) return;

    if (key == 'CRITICAL') return;

    _setLocal(key, value);
    notifyListeners();

    try {
      final farmId = (await _firestore.collection('users').doc(uid).get()).data()?['farm_id']?.toString();
      await _firestore.collection('users').doc(uid).set(
        {
          if (farmId != null) 'farm_id': farmId,
          'notification_prefs': {
            'CRITICAL': true,
            'HIGH': _high,
            'WARNING': _warning,
            'INFO': _info,
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      _error = 'Failed to save notification preferences';
      notifyListeners();
    }
  }

  void _setLocal(String key, bool value) {
    switch (key) {
      case 'HIGH':
        _high = value;
        break;
      case 'WARNING':
        _warning = value;
        break;
      case 'INFO':
        _info = value;
        break;
    }
  }

  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}