class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Convert the model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  // Optional: Construct the model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
    );
  }
}
