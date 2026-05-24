import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _roleCacheKey = 'cached_user_role';
  static const String _farmIdCacheKey = 'cached_user_farm_id';

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
      notifyListeners();
      return;
    }

    _user = user;

    // ── Load from SharedPreferences immediately — no network needed ──
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString(_roleCacheKey) ?? 'operator';
      _farmId = prefs.getString(_farmIdCacheKey);
    } catch (_) {
      _role = 'operator';
      _farmId = null;
    }

    // Show the app RIGHT NOW before any network call
    _status = AuthStatus.authenticated;
    notifyListeners();

    // Refresh from Firestore in background — no await
    _fetchUserRole(user.uid);
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      // Cache only — never wait for network during background refresh
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        _role = data?['role']?.toString() ?? 'operator';
        _farmId = data?['farm_id']?.toString();
      } else {
        // Doc not in cache — do nothing, keep SharedPreferences values
        // Will correct itself next time the user is online
        return;
      }

      // Persist refreshed values to SharedPreferences
      _cacheUserRole(_role, _farmId);

      // Update last_login only when online — fire and forget
      _firestore.collection('users').doc(uid).update({
        'last_login': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      notifyListeners();
    } catch (e) {
      // Cache miss or any error — silently keep the values already
      // loaded from SharedPreferences in _onAuthStateChanged.
      // Do NOT set _errorMessage here — the app opened fine.
    }
  }

  Future<void> _cacheUserRole(String? role, String? farmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleCacheKey, role ?? 'operator');
      if (farmId == null) {
        await prefs.remove(_farmIdCacheKey);
      } else {
        await prefs.setString(_farmIdCacheKey, farmId);
      }
    } catch (_) {
      // Ignore local cache failures.
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
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

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      _errorMessage =
          'Could not send reset email. Check the address and try again.';
      notifyListeners();
      return false;
    }
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