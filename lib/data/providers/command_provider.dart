import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firebase_paths.dart';

enum CommandStatus { idle, pending, executed, expired, error }

class CommandProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  CommandStatus _status = CommandStatus.idle;
  String? _errorMessage;
  StreamSubscription<DatabaseEvent>? _subscription;
  Timer? _expiryTimer;

  CommandStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isPending => _status == CommandStatus.pending;

  void startListening() {
    _subscription = _db.ref(FirebasePaths.commands).onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        final pending = map['pending'] as bool? ?? false;
        if (_status == CommandStatus.pending && !pending) {
          _status = CommandStatus.executed;
          _expiryTimer?.cancel();
          notifyListeners();
          Future.delayed(const Duration(seconds: 3), () {
            _status = CommandStatus.idle;
            notifyListeners();
          });
        }
      }
    });
  }

  Future<void> sendCommand({
    String? fanOverride,
    String? heaterOverride,
    String? lightsOverride,
    String? triggerFeeder,
    String? triggerManure,
    String? triggerPump,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expires = now + 60;
    try {
      await _db.ref(FirebasePaths.commands).set({
        'fan_override': fanOverride ?? '',
        'heater_override': heaterOverride ?? '',
        'lights_override': lightsOverride ?? '',
        'trigger_feeder': triggerFeeder ?? '',
        'trigger_manure': triggerManure ?? '',
        'trigger_pump': triggerPump ?? '',
        'issued_at': now,
        'expires_at': expires,
        'issued_by': uid,
        'pending': true,
      });
      _status = CommandStatus.pending;
      _errorMessage = null;
      notifyListeners();
      _expiryTimer?.cancel();
      _expiryTimer = Timer(const Duration(seconds: 65), () async {
        if (_status == CommandStatus.pending) {
          _status = CommandStatus.expired;
          _errorMessage = 'Command expired — ESP32 may be offline or disconnected.';
          notifyListeners();
          await clearCommands();
          Future.delayed(const Duration(seconds: 3), () {
            _status = CommandStatus.idle;
            _errorMessage = null;
            notifyListeners();
          });
        }
      });
    } catch (e) {
      _status = CommandStatus.error;
      _errorMessage = 'Cannot send command — no internet connection.';
      notifyListeners();
    }
  }

  Future<void> clearCommands() async {
    await _db.ref(FirebasePaths.commands).set({
      'fan_override': '',
      'heater_override': '',
      'lights_override': '',
      'trigger_feeder': '',
      'trigger_manure': '',
      'trigger_pump': '',
      'issued_at': 0,
      'expires_at': 0,
      'issued_by': '',
      'pending': false,
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _expiryTimer?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}