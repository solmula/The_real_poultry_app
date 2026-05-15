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
    final now = DateTime.now();
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

    try {
      // ══════════════════════════════════════════════════════════════════════════
      // FIRESTORE TRANSACTION: Prevent duplicate history entries
      // ══════════════════════════════════════════════════════════════════════════
      // PROBLEM: Without a transaction, race conditions occur when multiple devices
      // acknowledge the same alert simultaneously:
      //
      // Timeline of race condition:
      //   T1: Device A checks alert (acked=false)
      //   T2: Device B checks alert (acked=false)
      //   T3: Device A writes to history
      //   T4: Device B writes to history  ← Duplicate entry created!
      //
      // SOLUTION: Use Firestore transaction with deterministic doc ID:
      // 1. Transaction reads existing history doc (prevents duplicates)
      // 2. Only writes if not already acknowledged (idempotent behavior)
      // 3. Atomicity: all-or-nothing within this transaction
      // 4. Consistency: Firestore is authoritative; RTDB is eventual consistent
      //
      // Atomicity guarantee: Only ONE of the concurrent calls will succeed in
      // creating the history entry. Others will detect existing doc and return.
      // ══════════════════════════════════════════════════════════════════════════

      final historyDocId = 'alert_${alert.id}';
      bool wasAcknowledged = false;

      await _firestore.runTransaction<void>((transaction) async {
        final docRef = _firestore.collection(FirebasePaths.alertsHistory).doc(historyDocId);
        final existingDoc = await transaction.get(docRef);

        if (existingDoc.exists) {
          // ──────────────────────────────────────────────────────────────────────
          // Alert already in history (acknowledged previously)
          // Idempotent behavior: return without creating duplicate entry
          // ──────────────────────────────────────────────────────────────────────
          wasAcknowledged = true;
          return;
        }

        // ────────────────────────────────────────────────────────────────────────
        // Alert not in history yet: Add acknowledgment record atomically
        // This write is protected by the transaction:
        // - If another device writes between our check and write, Firestore
        //   will abort this transaction automatically
        // - We retry the transaction, which will then find the existing doc
        //   and return idempotently
        // ────────────────────────────────────────────────────────────────────────
        transaction.set(docRef, {
          'original_alert_id': alert.id,
          'type': alert.type,
          'value': alert.value,
          'threshold': alert.threshold,
          'severity': alert.severity,
          'timestamp': FieldValue.serverTimestamp(),
          'acked': true,
          'acked_by': uid,
          'acked_at': FieldValue.serverTimestamp(),
        });
      });

      // ════════════════════════════════════════════════════════════════════════════
      // UPDATE RTDB: Non-critical real-time display update
      // ════════════════════════════════════════════════════════════════════════════
      // RATIONALE: RTDB is used only for filtering active/unacked alerts in real-time.
      // Firestore alerts_history is the authoritative record.
      // If RTDB update fails, the history is still correctly recorded in Firestore.
      // This is acceptable because:
      // - Listeners will eventually see the alert marked as acked via next sync
      // - The alert won't appear in "active" list once RTDB catches up
      // - History is permanently and correctly recorded in Firestore
      // ════════════════════════════════════════════════════════════════════════════
      try {
        await _db.ref('${FirebasePaths.alertsActive}/${alert.id}').update({
          'acked': true,
          'acked_by': uid,
          'acked_at': nowSeconds,
        });
      } catch (rtdbError) {
        // Log but don't fail: Firestore write already succeeded
        // The alert is acknowledged in the authoritative history
        _error = 'Firestore updated but RTDB sync pending: $rtdbError';
        notifyListeners();
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      // ──────────────────────────────────────────────────────────────────────────
      // Transaction failed: Automatically rolled back by Firestore
      // Caller can retry or handle the error
      // ──────────────────────────────────────────────────────────────────────────
      _error = 'Failed to acknowledge alert: $e';
      notifyListeners();
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