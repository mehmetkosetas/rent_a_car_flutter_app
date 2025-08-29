class AppUser {
  final String adSoyad;
  final String email;
  final String rol;
  final String telefon;

  AppUser({
    required this.adSoyad,
    required this.email,
    required this.rol,
    required this.telefon,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      adSoyad: data['adSoyad'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? '',
      telefon: data['telefon'] ?? '',
    );
  }
}
