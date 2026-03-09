class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] ?? '',
    email: m['email'] ?? '',
    displayName: m['displayName'] ?? '',
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );
}