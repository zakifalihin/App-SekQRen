class User {
  final int id;
  final String nama;
  final String nip;
  final String role;

  User({
    required this.id,
    required this.nama,
    required this.nip,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nama: json['nama'],
      nip: json['nip'],
      role: json['role'],
    );
  }
}
