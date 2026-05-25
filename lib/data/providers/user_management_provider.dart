import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/firebase_paths.dart';
import '../models/user_model.dart';

enum UserMgmtStatus { idle, loading, saving, error }

class UserManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _users = [];
  UserMgmtStatus _status = UserMgmtStatus.idle;
  String? _error;

  List<UserModel> get users => List.unmodifiable(_users);
  UserMgmtStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == UserMgmtStatus.loading;
  bool get isSaving  => _status == UserMgmtStatus.saving;

  int get superAdminCount => _users.where((u) => u.isSuperAdmin && !u.disabled).length;
  int get adminCount    => _users.where((u) => u.role == 'admin'    && !u.disabled).length;
  int get operatorCount => _users.where((u) => u.isOperator && !u.disabled).length;
  int get viewerCount   => _users.where((u) => u.isViewer   && !u.disabled).length;
  int get disabledCount => _users.where((u) => u.disabled).length;

  Future<void> loadUsers() async {
    _status = UserMgmtStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final context = await _resolveCallerContext();
      Query<Map<String, dynamic>> query = _firestore.collection(FirebasePaths.users);
      if (!context.isSuperAdmin) {
        if (context.farmId != null && context.farmId!.isNotEmpty) {
          query = query.where('farm_id', isEqualTo: context.farmId);
        } else {
          query = query.where('farm_id', isNull: true);
        }
      }
      final snap = await query.get();
      _users = snap.docs.map(UserModel.fromFirestore).toList()
        ..sort((a, b) {
          if (a.disabled != b.disabled) return a.disabled ? 1 : -1;
          const order = {'super_admin': 0, 'admin': 1, 'operator': 2, 'viewer': 3};
          final ra = order[a.role] ?? 3;
          final rb = order[b.role] ?? 3;
          if (ra != rb) return ra.compareTo(rb);
          return a.email.compareTo(b.email);
        });
      _status = UserMgmtStatus.idle;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to load users: $e';
    }
    notifyListeners();
  }

  // IMPORTANT: createUserWithEmailAndPassword() signs in the new account,
  // logging out the admin. We re-authenticate the admin immediately after.
  // Production fix: use Firebase Admin SDK via a Cloud Function instead.
  Future<String?> inviteUser({
    required String email,
    required String role,
    String? farmId,
  }) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();

    try {
      final context = await _resolveCallerContext();
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('createUserAccount');
      final res = await callable.call(<String, dynamic>{
        'email': email.trim().toLowerCase(),
        'role': role,
        'farm_id': context.isSuperAdmin ? (farmId ?? context.farmId) : context.farmId,
      });
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        final msg = data?['error']?.toString() ?? 'Failed to create user.';
        throw StateError(msg);
      }

      _status = UserMgmtStatus.idle;
      notifyListeners();
      await loadUsers();
      return null;
    } on FirebaseFunctionsException catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.message ?? 'Failed to create user: ${e.code}';
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to create user: $e';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> changeRole(String uid, String newRole) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('changeUserRole');
      final res = await callable.call(<String, dynamic>{'targetUid': uid, 'newRole': newRole});
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        throw StateError('Failed to change role.');
      }
      final idx = _users.indexWhere((u) => u.uid == uid);
      if (idx != -1) _users[idx] = _users[idx].copyWith(role: newRole);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      return null;
    } on FirebaseFunctionsException catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.message ?? 'Failed to change role: ${e.code}';
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to change role: $e';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> toggleDisabled(String uid, bool disabled) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('toggleUserDisabled');
      final res = await callable.call(<String, dynamic>{'targetUid': uid, 'disabled': disabled});
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) throw StateError('Failed to update user.');
      final idx = _users.indexWhere((u) => u.uid == uid);
      if (idx != -1) _users[idx] = _users[idx].copyWith(disabled: disabled);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      return null;
    } on FirebaseFunctionsException catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.message ?? 'Failed to update user: ${e.code}';
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to update user: $e';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> deleteUser(String uid) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('deleteUserAccount');
      final result = await callable.call(<String, dynamic>{'targetUid': uid});
      final data = result.data;
      final payload = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      if (payload['success'] != true) {
        throw StateError(payload['message']?.toString() ?? 'User deletion failed.');
      }

      _users.removeWhere((u) => u.uid == uid);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      await loadUsers();
      return null;
    } on FirebaseFunctionsException catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.message ?? 'Failed to delete user: ${e.code}';
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> createFarmAdmin({
    required String farmName,
    required String adminEmail,
    required String subscriptionPlan,
  }) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('createFarmAdmin');
      final res = await callable.call(<String, dynamic>{
        'farm_name': farmName.trim(),
        'admin_email': adminEmail.trim().toLowerCase(),
        'subscription_plan': subscriptionPlan.trim(),
      });
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        throw StateError('Failed to create farm admin.');
      }

      _status = UserMgmtStatus.idle;
      notifyListeners();
      await loadUsers();
      return null;
    } on FirebaseFunctionsException catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.message ?? 'Failed to create farm admin: ${e.code}';
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to create farm admin: $e';
      notifyListeners();
      return _error;
    }
  }

  Future<_CallerContext> _resolveCallerContext() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const _CallerContext(role: 'operator', farmId: null);

    final doc = await _firestore.collection(FirebasePaths.users).doc(uid).get();
    final role = doc.data()?['role']?.toString() ?? 'operator';
    final farmId = doc.data()?['farm_id']?.toString();
    return _CallerContext(role: role, farmId: farmId);
  }
}

class _CallerContext {
  final String role;
  final String? farmId;
  const _CallerContext({required this.role, required this.farmId});

  bool get isSuperAdmin => role == 'super_admin';
}