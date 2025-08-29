// lib/screens/car_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/car.dart';
import 'rent_car_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarDetailScreen extends StatefulWidget {
  static const routeName = '/detail';
  final Car car;
  const CarDetailScreen({super.key, required this.car});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  bool _isFav = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchFavorite();
  }

  Future<void> _fetchFavorite() async {
    if (_user == null) return;
    final favDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('favorites')
            .doc(widget.car.id)
            .get();
    setState(() {
      _isFav = favDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_user == null) return;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .doc(widget.car.id);
    if (_isFav) {
      await favRef.delete();
      setState(() => _isFav = false);
    } else {
      await favRef.set({'addedAt': FieldValue.serverTimestamp()});
      setState(() => _isFav = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ignore: unused_local_variable

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.car.name} ${widget.car.model}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isFav ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Görsel
            Hero(
              tag: 'car-${widget.car.name}',
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      widget.car.imageUrl,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. İçerik Bölümü
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -30, 0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fiyat kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Günlük Fiyat',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '₺${widget.car.pricePerDay.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(padding: const EdgeInsets.all(12)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Features
                    const Text(
                      'Özellikler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.car.ozellikler.isNotEmpty
                              ? widget.car.ozellikler
                                  .map(
                                    (ozellik) => _buildFeatureChip(
                                      _getFeatureIcon(ozellik),
                                      ozellik,
                                      _getFeatureColor(ozellik),
                                    ),
                                  )
                                  .toList()
                              : [
                                // Varsayılan özellikler (eğer ozellikler listesi boşsa)
                                _buildFeatureChip(
                                  Icons.local_parking,
                                  'Park Sensörü',
                                  Colors.blue,
                                ),
                                _buildFeatureChip(
                                  Icons.navigation,
                                  'Navigasyon',
                                  Colors.green,
                                ),
                                _buildFeatureChip(
                                  Icons.bluetooth_audio,
                                  'Bluetooth',
                                  Colors.purple,
                                ),
                                _buildFeatureChip(
                                  Icons.ac_unit,
                                  'Klima',
                                  Colors.cyan,
                                ),
                                _buildFeatureChip(
                                  Icons.security,
                                  'Güvenlik',
                                  Colors.orange,
                                ),
                              ],
                    ),

                    const SizedBox(height: 24),

                    // Specs
                    const Text(
                      'Teknik Özellikler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.speed,
                            label: 'Maksimum Hız',
                            value: '${widget.car.topSpeed} km/h',
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.speed_outlined,
                            label: 'Kilometre',
                            value: '${widget.car.kilometers} KM',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.power,
                            label: 'Beygir Gücü',
                            value: '${widget.car.horsePower} HP',
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.local_gas_station,
                            label: 'Yakıt Tipi',
                            value: widget.car.fuelType,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.battery_std,
                            label: 'Yakıt Yüzdesi',
                            value: '${widget.car.fuelPercentage}%',
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.group,
                            label: 'Koltuk Sayısı',
                            value: '${widget.car.seats}',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Model Yılı',
                            value: '${widget.car.year}',
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 8),
                          InfoRow(
                            icon: Icons.directions_car,
                            label: 'Kasa Tipi',
                            value: widget.car.bodyType,
                            color: Colors.indigo,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.car.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Rent Now Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final userDoc =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                          final ehliyetOnUrl =
                              userDoc.data()?['ehliyetOnUrl'] ?? '';
                          final ehliyetArkaUrl =
                              userDoc.data()?['ehliyetArkaUrl'] ?? '';
                          final ehliyetOnayDurumu =
                              userDoc.data()?['ehliyetOnayDurumu'] ?? '';

                          // Önce onay durumunu kontrol et (reddedildi/beklemede),
                          // ardından eksik bilgi uyarısını göster.
                          if (ehliyetOnayDurumu == 'beklemede') {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text(
                                        'Ehliyet Onay Bekliyor',
                                      ),
                                      content: const Text(
                                        'Ehliyet bilgileriniz admin tarafından onaylanmayı bekliyor. Onaylandıktan sonra kiralama yapabilirsiniz.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Tamam'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          } else if (ehliyetOnayDurumu == 'reddedildi') {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Ehliyet Onaylanmadı'),
                                      content: const Text(
                                        'Ehliyet bilgileriniz onaylanmadı. Lütfen profil düzenleme kısmından ehliyet fotoğraflarınızı tekrar yükleyin.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Tamam'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          } else if (ehliyetOnUrl.isEmpty ||
                              ehliyetArkaUrl.isEmpty) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text(
                                        'Ehliyet Bilgisi Eksik',
                                      ),
                                      content: const Text(
                                        'Lütfen profil düzenleme kısmından ehliyet ön ve arka fotoğraflarınızı yükleyin.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Tamam'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          } else if (ehliyetOnayDurumu == 'onaylandi' ||
                              ehliyetOnayDurumu == '') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RentCarScreen(car: widget.car),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Şimdi Kirala',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Özellik adına göre icon döndür
  IconData _getFeatureIcon(String ozellik) {
    switch (ozellik.toLowerCase()) {
      case 'park sensörü':
        return Icons.local_parking;
      case 'navigasyon':
        return Icons.navigation;
      case 'bluetooth':
        return Icons.bluetooth_audio;
      case 'klima':
        return Icons.ac_unit;
      case 'güvenlik':
        return Icons.security;
      case 'otomatik vites':
        return Icons.settings;
      case 'sunroof':
        return Icons.roofing;
      case 'deri koltuk':
        return Icons.airline_seat_recline_normal;
      default:
        return Icons.check_circle;
    }
  }

  // Özellik adına göre renk döndür
  Color _getFeatureColor(String ozellik) {
    switch (ozellik.toLowerCase()) {
      case 'park sensörü':
        return Colors.blue;
      case 'navigasyon':
        return Colors.green;
      case 'bluetooth':
        return Colors.purple;
      case 'klima':
        return Colors.cyan;
      case 'güvenlik':
        return Colors.orange;
      case 'otomatik vites':
        return Colors.indigo;
      case 'sunroof':
        return Colors.teal;
      case 'deri koltuk':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

// Specs ve InfoRow widget'ı
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
