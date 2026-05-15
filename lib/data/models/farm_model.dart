import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String id;
  final String name;
  final String ownerUid;
  final String subscriptionPlan;
  final DateTime? createdAt;

  const FarmModel({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.subscriptionPlan,
    this.createdAt,
  });

  factory FarmModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FarmModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      ownerUid: data['owner_uid']?.toString() ?? '',
      subscriptionPlan: data['subscription_plan']?.toString() ?? 'starter',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}