class User {
  final String username;

  User({required this.username});

  Map<String, dynamic> toJson() {
    return {'username': username};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(username: json['username']);
  }
}
