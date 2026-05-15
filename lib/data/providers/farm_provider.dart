import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_paths.dart';
import '../models/farm_model.dart';

class FarmProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FarmModel? _currentFarm;
  List<FarmModel> _farms = [];
  bool _isLoading = true;
  String? _error;

  StreamSubscription<User?>? _authSub;

  FarmModel? get currentFarm => _currentFarm;
  List<FarmModel> get farms => List.unmodifiable(_farms);
  bool get isLoading => _isLoading;
  String? get error => _error;

  FarmProvider() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _currentFarm = null;
        _farms = [];
        _isLoading = false;
        _error = null;
        notifyListeners();
        return;
      }
      load();
    });
    load();
  }

  Future<void> load() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentFarm = null;
      _farms = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userDoc = await _firestore.collection(FirebasePaths.users).doc(user.uid).get();
      final role = userDoc.data()?['role']?.toString() ?? 'operator';
      final farmId = userDoc.data()?['farm_id']?.toString();

      if (role == 'super_admin') {
        final snap = await _firestore.collection(FirebasePaths.farmsCollection).get();
        _farms = snap.docs.map(FarmModel.fromFirestore).toList();
        _currentFarm = null;
      } else if (farmId != null && farmId.isNotEmpty) {
        final doc = await _firestore.collection(FirebasePaths.farmsCollection).doc(farmId).get();
        _currentFarm = doc.exists ? FarmModel.fromFirestore(doc) : null;
        _farms = _currentFarm == null ? [] : [_currentFarm!];
      } else {
        _currentFarm = null;
        _farms = [];
      }
    } catch (e) {
      _error = 'Failed to load farm information';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}