import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  int get adminCount    => _users.where((u) => u.isAdmin    && !u.disabled).length;
  int get operatorCount => _users.where((u) => u.isOperator && !u.disabled).length;
  int get viewerCount   => _users.where((u) => u.isViewer   && !u.disabled).length;
  int get disabledCount => _users.where((u) => u.disabled).length;

  Future<void> loadUsers() async {
    _status = UserMgmtStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final snap = await _firestore.collection('users').get();
      _users = snap.docs.map(UserModel.fromFirestore).toList()
        ..sort((a, b) {
          if (a.disabled != b.disabled) return a.disabled ? 1 : -1;
          const order = {'admin': 0, 'operator': 1, 'viewer': 2};
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
    required String password,
    required String role,
    required String adminEmail,
    required String adminPassword,
  }) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();

    User? restoredAdmin;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final newUid = cred.user!.uid;

      await _auth.signOut();
      final adminCred = await _auth.signInWithEmailAndPassword(
        email: adminEmail.trim(),
        password: adminPassword.trim(),
      );
      restoredAdmin = adminCred.user;

      await _firestore.collection('users').doc(newUid).set({
        'email':      email.trim().toLowerCase(),
        'role':       role,
        'disabled':   false,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': null,
      });

      _status = UserMgmtStatus.idle;
      notifyListeners();
      await loadUsers();
      return null;
    } on FirebaseAuthException catch (e) {
      _status = UserMgmtStatus.error;
      _error = _mapAuthError(e.code);
      if (restoredAdmin == null && _auth.currentUser == null) {
        _error = '$_error\n\nAdmin session lost — please log in again.';
      }
      notifyListeners();
      return _error;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<String?> changeRole(String uid, String newRole) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      final idx = _users.indexWhere((u) => u.uid == uid);
      if (idx != -1) _users[idx] = _users[idx].copyWith(role: newRole);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      return null;
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
      await _firestore.collection('users').doc(uid).update({'disabled': disabled});
      final idx = _users.indexWhere((u) => u.uid == uid);
      if (idx != -1) _users[idx] = _users[idx].copyWith(disabled: disabled);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      return null;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to update user: $e';
      notifyListeners();
      return _error;
    }
  }

  // Note: removes Firestore doc only. Full Auth account deletion needs Admin SDK.
  Future<String?> deleteUser(String uid) async {
    _status = UserMgmtStatus.saving;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('users').doc(uid).delete();
      _users.removeWhere((u) => u.uid == uid);
      _status = UserMgmtStatus.idle;
      notifyListeners();
      return null;
    } catch (e) {
      _status = UserMgmtStatus.error;
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return _error;
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'This email is already registered.';
      case 'invalid-email':          return 'Invalid email address.';
      case 'weak-password':          return 'Password must be at least 6 characters.';
      case 'wrong-password':         return 'Admin password is incorrect.';
      case 'network-request-failed': return 'No internet connection.';
      default:                       return 'Error: $code';
    }
  }
}