import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' | 'operator' | 'viewer'
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool disabled;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastLogin,
    this.disabled = false,
  });

  bool get isAdmin    => role == 'admin';
  bool get isOperator => role == 'operator';
  bool get isViewer   => role == 'viewer';

  String get roleLabel {
    switch (role) {
      case 'admin':    return 'Admin';
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
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      lastLogin: (d['last_login'] as Timestamp?)?.toDate(),
      disabled:  d['disabled'] == true,
    );
  }

  UserModel copyWith({String? role, bool? disabled}) => UserModel(
    uid:       uid,
    email:     email,
    role:      role ?? this.role,
    createdAt: createdAt,
    lastLogin: lastLogin,
    disabled:  disabled ?? this.disabled,
  );
}