class User {
  final String email;
  final String phone;
  final String firstName;
  final String lastName;

  User({
    required this.email,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
  });
}
