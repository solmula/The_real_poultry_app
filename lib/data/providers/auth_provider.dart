import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _role;
  String? _farmId;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get role => _role;
  String? get farmId => _farmId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSuperAdmin => _role == 'super_admin';
  bool get isAdmin => _role == 'admin' || _role == 'super_admin';
  bool get isOperator => _role == 'operator' || _role == 'admin' || _role == 'super_admin';
  bool get isViewer => _role == 'viewer';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _user = null;
      _role = null;
      _farmId = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _user = user;
      await _fetchUserRole(user.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _role = doc.data()?['role']?.toString() ?? 'operator';
        _farmId = doc.data()?['farm_id']?.toString();
      } else {
        _errorMessage = 'Account not found. Contact your administrator.';
        await signOut();
        return;
      }
      await _firestore.collection('users').doc(uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _errorMessage = 'Failed to verify account. Please try again.';
      await signOut();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapAuthError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {}
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'network-request-failed':
        return 'No internet connection. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}