import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../../core/constants/firebase_paths.dart';

class AlertProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AlertModel> _activeAlerts = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _subscription;

  List<AlertModel> get activeAlerts => _activeAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeCount => _activeAlerts.length;
  bool get hasCritical => _activeAlerts.any((a) => a.severity == 'CRITICAL');
  bool get hasHigh => _activeAlerts.any((a) => a.severity == 'HIGH');

  Color get badgeColor {
    if (hasCritical) return const Color(0xFFB71C1C);
    if (hasHigh) return const Color(0xFFE65100);
    if (_activeAlerts.any((a) => a.severity == 'WARNING')) return const Color(0xFFF57F17);
    return const Color(0xFF1565C0);
  }

  void startListening() {
    _subscription = _db.ref(FirebasePaths.alertsActive).onValue.listen(
      (event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          try {
            final map = event.snapshot.value as Map<dynamic, dynamic>;
            _activeAlerts = map.entries
                .map((e) => AlertModel.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>))
                .where((a) => !a.acked)
                .toList();
            _activeAlerts.sort((a, b) {
              final order = {'CRITICAL': 0, 'HIGH': 1, 'WARNING': 2, 'INFO': 3};
              final sA = order[a.severity] ?? 4;
              final sB = order[b.severity] ?? 4;
              if (sA != sB) return sA.compareTo(sB);
              return b.timestamp.compareTo(a.timestamp);
            });
            _error = null;
          } catch (e) {
            _error = 'Failed to parse alerts';
          }
        } else {
          _activeAlerts = [];
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load alerts';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> acknowledgeAlert(AlertModel alert) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      await _db.ref('${FirebasePaths.alertsActive}/${alert.id}').update({
        'acked': true,
        'acked_by': uid,
        'acked_at': now,
      });
      await _firestore.collection(FirebasePaths.alertsHistory).add({
        'type': alert.type,
        'value': alert.value,
        'threshold': alert.threshold,
        'severity': alert.severity,
        'timestamp': FieldValue.serverTimestamp(),
        'acked': true,
        'acked_by': uid,
        'acked_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = 'Failed to acknowledge alert';
      notifyListeners();
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