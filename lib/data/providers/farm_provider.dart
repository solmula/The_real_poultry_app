import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/firebase_paths.dart';
import '../models/farm_model.dart';

class FarmProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FarmModel? _currentFarm;
  List<FarmModel> _farms = [];
  bool _isLoading = true;
  String? _error;

  static const String _cachedFarmsKey = 'cached_farms';
  static const String _cachedCurrentFarmIdKey = 'cached_current_farm_id';

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

  Future<DocumentSnapshot<Map<String, dynamic>>> _getWithCacheFallback(
      DocumentReference<Map<String, dynamic>> ref) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.server));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryWithCacheFallback(
      Query<Map<String, dynamic>> query) async {
    try {
      return await query.get(const GetOptions(source: Source.cache));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.server));
    }
  }

  Future<void> _saveFarmCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final farmList = _farms
          .map((farm) => {
                'id': farm.id,
                'name': farm.name,
                'owner_uid': farm.ownerUid,
                'subscription_plan': farm.subscriptionPlan,
                'created_at': farm.createdAt?.millisecondsSinceEpoch,
              })
          .toList();
      await prefs.setString(_cachedFarmsKey, jsonEncode(farmList));
      await prefs.setString(
        _cachedCurrentFarmIdKey,
        _currentFarm?.id ?? '',
      );
    } catch (_) {
      // Ignore local cache failures.
    }
  }

  FarmModel _buildFarmFromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      ownerUid: map['owner_uid']?.toString() ?? '',
      subscriptionPlan: map['subscription_plan']?.toString() ?? 'starter',
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
    );
  }

  Future<bool> _loadFarmCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedFarmsKey);
      if (cached == null || cached.isEmpty) return false;

      final list = jsonDecode(cached) as List<dynamic>;
      _farms = list
          .whereType<Map<String, dynamic>>()
          .map(_buildFarmFromMap)
          .toList();
      final currentFarmId = prefs.getString(_cachedCurrentFarmIdKey) ?? '';
      _currentFarm = _farms.firstWhere(
        (farm) => farm.id == currentFarmId,
        orElse: () => _farms.first,
      );
      return _farms.isNotEmpty;
    } catch (_) {
      return false;
    }
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
      final userDoc = await _getWithCacheFallback(
        _firestore.collection(FirebasePaths.users).doc(user.uid),
      );
      final data = userDoc.data();
      final role = data?['role']?.toString() ?? 'operator';
      final farmId = data?['farm_id']?.toString();

      if (role == 'super_admin') {
        final snap = await _queryWithCacheFallback(
          _firestore.collection(FirebasePaths.farmsCollection),
        );
        _farms = snap.docs.map(FarmModel.fromFirestore).toList();
        _currentFarm = null;
      } else if (farmId != null && farmId.isNotEmpty) {
        final doc = await _getWithCacheFallback(
          _firestore.collection(FirebasePaths.farmsCollection).doc(farmId),
        );
        _currentFarm = doc.exists ? FarmModel.fromFirestore(doc) : null;
        _farms = _currentFarm == null ? [] : [_currentFarm!];
      } else {
        _currentFarm = null;
        _farms = [];
      }
      await _saveFarmCache();
    } catch (e) {
      final loaded = await _loadFarmCache();
      if (!loaded) {
        _error = 'Failed to load farm information';
      } else {
        _error = null;
      }
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