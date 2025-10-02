import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile data model
///
/// Represents basic user profile information:
/// - Basic user details (ID, name, photo)
class UserProfileModel {
  final String id;
  final String displayName;
  final String? photoUrl;

  const UserProfileModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
  });

  factory UserProfileModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'], // Fixed: was 'photoURL', should be 'photoUrl'
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel &&
        other.id == id &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(id, displayName, photoUrl);
}
