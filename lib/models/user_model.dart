class UserModel {
  final int id;
  final String email;
  final String username;
  final String fullName;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      isAdmin: json['is_admin'] ?? false,
    );
  }
}