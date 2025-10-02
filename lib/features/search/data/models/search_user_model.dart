/// Search user data model
///
/// Represents a user in search results with:
/// - Basic user information (ID, name, photo)
class SearchUserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final String email;

  const SearchUserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.email,
  });

  /// Create SearchUserModel from Firestore document
  factory SearchUserModel.fromDoc(Map<String, dynamic> data, String docId) {
    return SearchUserModel(
      id: docId,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      email: data['email'] ?? '',
    );
  }

  /// Convert to Map for Firestore operations
  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
    'email': email,
  };

  /// Create a copy with updated fields
  SearchUserModel copyWith({
    String? id,
    String? displayName,
    String? photoUrl,
    String? email,
  }) {
    return SearchUserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchUserModel &&
        other.id == id &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, displayName, photoUrl, email);
}
