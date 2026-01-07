class User {
  final int id;
  final String nama;
  final String nip;
  final String password;
  final String email;
  final String role;

  User({
    required this.id,
    required this.nama,
    required this.nip,
    required this.password,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? "Tanpa Nama",
      nip: json['nip'] ?? "-",
      email: json['email'] ?? "-",
      role: json['role'] ?? "user",
      password: "",
    );
  }
}
