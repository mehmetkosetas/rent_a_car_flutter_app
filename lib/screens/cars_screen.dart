// lib/screens/cars_screen.dart

import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_car_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard_screen.dart';

class CarsScreen extends StatefulWidget {
  final List<Car> cars;
  final String? userRole;

  const CarsScreen({super.key, required this.cars, this.userRole});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _favoriteCarIds = {};
  User? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _user = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavorites();
    });
  }

  Future<void> _fetchFavorites() async {
    if (_user == null) return;

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .collection('favorites')
              .get();

      // Ekran hâlâ monteyse devam et
      if (!mounted) return;

      setState(() {
        _favoriteCarIds = snap.docs.map((d) => d.id).toSet();
      });
    } catch (e) {
      // Hata da olsa mounted kontrolüyle bitsin
      if (!mounted) return;
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String carId) async {
    if (_user == null) return;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .doc(carId);

    try {
      if (_favoriteCarIds.contains(carId)) {
        await favRef.delete();
        if (!mounted) return;
        setState(() => _favoriteCarIds.remove(carId));
      } else {
        await favRef.set({'addedAt': FieldValue.serverTimestamp()});
        if (!mounted) return;
        setState(() => _favoriteCarIds.add(carId));
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error toggling favorite: $e');
    }
  }

  String _getTransmissionType(List<dynamic>? features) {
    if (features == null) return '';
    for (var feature in features) {
      String featureStr = feature.toString().toLowerCase();
      if (featureStr.contains('otomatik')) {
        return 'Otomatik';
      } else if (featureStr.contains('manuel')) {
        return 'Manuel';
      }
    }
    return '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cars').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cars =
            snapshot.data!.docs
                .map(
                  (doc) =>
                      Car.fromMap(doc.id, doc.data() as Map<String, dynamic>),
                )
                .toList();
        final allCars = cars;
        final favoriteCars =
            cars.where((car) => _favoriteCarIds.contains(car.id)).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Uygun Araçlar'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Tümü'), Tab(text: 'Favoriler')],
            ),
            actions: [
              if (widget.userRole == 'admin')
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Admin Paneli',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [_buildCarGrid(allCars), _buildCarGrid(favoriteCars)],
          ),
          floatingActionButton:
              (widget.userRole == 'admin')
                  ? Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 8),
                    child: SizedBox(
                      width: 180,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 28),
                        label: const Text(
                          'Araç Ekle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shadowColor: const Color(0xFF667eea).withOpacity(0.3),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddCarScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  : null,
          floatingActionButtonLocation:
              (widget.userRole == 'admin')
                  ? FloatingActionButtonLocation.endFloat
                  : null,
        );
      },
    );
  }

  Widget _buildCarGrid(List<Car> cars) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: cars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.52,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (ctx, i) {
            final car = cars[i];
            final isFav = _favoriteCarIds.contains(car.id);
            final transmissionType = _getTransmissionType(car.ozellikler);

            return Hero(
              tag: 'car-${car.name}-$i',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CarDetailScreen(car: car),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Resim bölümü
                          Container(
                            height: 100,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Image.network(
                                    car.imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                                // Vites tipi
                                if (transmissionType.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF667eea),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        transmissionType,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Favorilere ekle ikonu
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _toggleFavorite(car.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // İçerik bölümü
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.name} ${car.model}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${car.pricePerDay.toStringAsFixed(0)}₺ / günde',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Araç bilgileri
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoItem(
                                        Icons.speed,
                                        '${car.kilometers} KM',
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoItem(
                                        Icons.local_gas_station,
                                        '%${car.fuelPercentage}',
                                        Colors.green,
                                      ),
                                    ],
                                  ),

                                  const Spacer(),
                                  // Detay butonu
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    CarDetailScreen(car: car),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Detayları Gör',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
