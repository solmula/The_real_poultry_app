import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'super_admin' | 'admin' | 'operator' | 'viewer'
  final String? farmId;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool disabled;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.farmId,
    this.createdAt,
    this.lastLogin,
    this.disabled = false,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isOperator => role == 'operator' || role == 'admin' || role == 'super_admin';
  bool get isViewer => role == 'viewer';

  String get roleLabel {
    switch (role) {
      case 'admin':    return 'Admin';
      case 'super_admin': return 'Super Admin';
      case 'operator': return 'Operator';
      case 'viewer':   return 'Viewer';
      default:         return role;
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid:       doc.id,
      email:     d['email']?.toString() ?? '',
      role:      d['role']?.toString() ?? 'operator',
      farmId:    d['farm_id']?.toString(),
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      lastLogin: (d['last_login'] as Timestamp?)?.toDate(),
      disabled:  d['disabled'] == true,
    );
  }

  UserModel copyWith({String? role, String? farmId, bool? disabled}) => UserModel(
    uid:       uid,
    email:     email,
    role:      role ?? this.role,
    farmId:    farmId ?? this.farmId,
    createdAt: createdAt,
    lastLogin: lastLogin,
    disabled:  disabled ?? this.disabled,
  );
}