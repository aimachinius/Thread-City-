class UserModel {
  final int id;
  final String username;
  final String email;
  final String? nickname;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;
  bool isOnline;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
    this.bio,
    this.avatarUrl,
    this.createdAt,
    this.isOnline = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 0,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      isOnline: map['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'is_online': isOnline,
    };
  }
}
