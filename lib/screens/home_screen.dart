import 'package:flutter/material.dart';
import 'cars_screen.dart';
import 'profile_screen.dart';
import 'my_rentals_screen.dart';
import '../models/car.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'car_detail_screen.dart';
// Added import for AdminDashboardScreen

class HomeScreen extends StatefulWidget {
  final List<Car> cars;
  final User? user;
  // final String userName; // Bunu kaldırıyoruz

  const HomeScreen({super.key, required this.cars, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String searchQuery = '';
  String selectedCategory = 'Tümü';

  String? _userRole; // Kullanıcı rolü burada tutulacak
  bool get isAdmin => _userRole == 'admin';

  // --- Filtreleme için state ---
  String? _filterCarType;
  String? _filterFuelType;
  RangeValues _filterPrice = const RangeValues(0, 50000);
  RangeValues _filterYear = const RangeValues(2015, 2024);
  RangeValues _filterFuelPercent = const RangeValues(0, 100);
  List<String> _filterOzellikler = [];
  int? _filterSeats;
  RangeValues _filterHorsePower = const RangeValues(0, 5000);

  final List<String> _carTypes = [
    'Sedan',
    'Hatchback',
    'SUV',
    'Coupe',
    'Cabrio',
    'Pickup',
    'Minivan',
    'Station Wagon',
    'Crossover',
    'Roadster',
  ];
  final List<String> _fuelTypes = [
    'Benzin',
    'Dizel',
    'Elektrik',
    'Hybrid',
    'LPG',
  ];
  final List<String> _ozellikler = [
    'Park Sensörü',
    'Navigasyon',
    'Bluetooth',
    'Klima',
    'Güvenlik',
    'Otomatik Vites',
    'Sunroof',
    'Deri Koltuk',
  ];

  final List<String> categories = [
    'Tümü',
    'Sedan',
    'SUV',
    'Elektrikli',
    'Ekonomi',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _fetchUserRole();

    _pages = [
      _buildHomeTab(),
      CarsScreen(cars: widget.cars, userRole: _userRole),
      MyRentalsScreen(),
      ProfileScreen(),
    ];
  }

  Future<void> _fetchUserRole() async {
    final user = widget.user;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!mounted) return;
    setState(() {
      _userRole = doc.data()?['rol'] ?? 'üye';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String> _fetchUserName() async {
    final user = widget.user;
    if (user == null) return '';
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['adSoyad'] ?? '';
  }

  Widget _buildHomeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cars').snapshots(),
      builder: (context, carSnapshot) {
        if (!carSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cars =
            carSnapshot.data!.docs
                .map(
                  (doc) =>
                      Car.fromMap(doc.id, doc.data() as Map<String, dynamic>),
                )
                .toList();

        // İLK ÖNCE TÜM ARAÇLAR ÜZERİNDE DETAYLI FİLTRELEME YAP
        List<Car> detailedFilteredCars =
            cars.where((car) {
              // Araç Tipi filtresi
              if (_filterCarType != null &&
                  car.bodyType.toLowerCase() != _filterCarType!.toLowerCase()) {
                return false;
              }

              // Yakıt Türü filtresi
              if (_filterFuelType != null &&
                  !car.fuelType.toLowerCase().contains(
                    _filterFuelType!.toLowerCase(),
                  )) {
                return false;
              }

              // Fiyat filtresi
              if (car.pricePerDay < _filterPrice.start ||
                  car.pricePerDay > _filterPrice.end) {
                return false;
              }

              // Yıl filtresi
              if (car.year < _filterYear.start || car.year > _filterYear.end) {
                return false;
              }

              // Özellikler filtresi
              if (_filterOzellikler.isNotEmpty) {
                final carFeatures =
                    car.ozellikler.map((e) => e.toString()).toList();
                bool hasAnyFeature = false;

                for (var feature in _filterOzellikler) {
                  if (carFeatures.contains(feature)) {
                    hasAnyFeature = true;
                    break;
                  }
                }

                if (!hasAnyFeature) return false;
              }

              // Koltuk sayısı filtresi
              if (_filterSeats != null && car.seats != _filterSeats) {
                return false;
              }

              // Beygir gücü filtresi (eğer Car modelinde horsePower property'si varsa)
              if (car.horsePower < _filterHorsePower.start ||
                  car.horsePower > _filterHorsePower.end) {
                return false;
              }
              // Yakıt yüzdesi filtresi
              if (car.fuelPercentage < _filterFuelPercent.start ||
                  car.fuelPercentage > _filterFuelPercent.end) {
                return false;
              }

              return true;
            }).toList();

        // SONRA KATEGORİ FİLTRELEMESİ YAP (detaylı filtrelenmiş araçlar üzerinde)
        List<Car> categoryFilteredCars = detailedFilteredCars;
        if (selectedCategory != 'Tümü') {
          categoryFilteredCars =
              detailedFilteredCars.where((car) {
                if (selectedCategory == 'Sedan') {
                  return car.bodyType.toLowerCase() == 'sedan';
                }
                if (selectedCategory == 'SUV') {
                  return car.bodyType.toLowerCase() == 'suv';
                }
                if (selectedCategory == 'Elektrikli') {
                  final ft = car.fuelType.toLowerCase();
                  return ft.contains('elektrik') || ft.contains('hybrid');
                }
                if (selectedCategory == 'Ekonomi') {
                  return car.group.toLowerCase().contains('economy');
                }
                return true;
              }).toList();
        }

        // ARAMA İÇİN TÜM ARAÇLARI KULLAN (kategori ve detaylı filtre uygulanmış)
        final searchResults =
            searchQuery.isEmpty
                ? categoryFilteredCars
                : categoryFilteredCars
                    .where(
                      (car) => ('${car.name} ${car.model}')
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()),
                    )
                    .toList();

        // En çok kiralananlar için rentals'ı dinle
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
          builder: (context, rentalSnapshot) {
            List<Car> popularCars = [];
            if (rentalSnapshot.hasData) {
              final rentals = rentalSnapshot.data!.docs;
              // Her carId için kiralama sayısını hesapla
              final Map<String, int> rentalCounts = {};
              for (var rental in rentals) {
                final data = rental.data() as Map<String, dynamic>;
                final carId = data['carId'] ?? '';
                if (carId.isNotEmpty) {
                  rentalCounts[carId] = (rentalCounts[carId] ?? 0) + 1;
                }
              }
              // En çok kiralanan ilk 3 carId'yi bul
              final topCarIds =
                  rentalCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
              final top3Ids = topCarIds.take(3).map((e) => e.key).toList();
              // Bu id'lere karşılık gelen Car objelerini bul
              popularCars =
                  top3Ids
                      .map(
                        (id) => cars.firstWhere(
                          (c) => c.id == id,
                          orElse: () => cars.first,
                        ),
                      )
                      .toList();
            } else {
              // Rentals yoksa, ilk 3 arabayı göster
              popularCars = cars.take(3).toList();
            }
            return FutureBuilder<String>(
              future: _fetchUserName(),
              builder: (context, snapshot) {
                final userName = snapshot.data ?? '';
                return Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Header Section
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Hoş geldin,',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                Text(
                                                  ' $userName 👋',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                              onPressed:
                                                  () => setState(
                                                    () => _selectedIndex = 3,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Hangi araçla seyahat etmek istersin?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Search Bar ve filtreli sonuçlar
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: const InputDecoration(
                                                  hintText:
                                                      'Aracınızı buradan arayın',
                                                  prefixIcon: Icon(
                                                    Icons.search,
                                                    color: Color(0xFF667eea),
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                ),
                                                onChanged: (val) {
                                                  setState(() {
                                                    searchQuery = val;
                                                  });
                                                },
                                              ),
                                            ),
                                            // Filtre ikonu
                                            IconButton(
                                              icon: const Icon(
                                                Icons.filter_list,
                                                color: Color(0xFF667eea),
                                              ),
                                              tooltip: 'Filtrele',
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            24,
                                                          ),
                                                        ),
                                                  ),
                                                  builder: (context) {
                                                    return StatefulBuilder(
                                                      builder: (
                                                        context,
                                                        setModalState,
                                                      ) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 16,
                                                              ),
                                                          child: SingleChildScrollView(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Center(
                                                                  child: Container(
                                                                    width: 40,
                                                                    height: 4,
                                                                    margin:
                                                                        const EdgeInsets.only(
                                                                          bottom:
                                                                              16,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .grey[300],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            2,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const Text(
                                                                  'Filtrele',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 16,
                                                                ),
                                                                // Araç Tipi
                                                                DropdownButtonFormField<
                                                                  String
                                                                >(
                                                                  initialValue:
                                                                      _filterCarType ??
                                                                      '',
                                                                  decoration:
                                                                      const InputDecoration(
                                                                        labelText:
                                                                            'Araç Tipi',
                                                                      ),
                                                                  items:
                                                                      [
                                                                        const DropdownMenuItem(
                                                                          value:
                                                                              '',
                                                                          child: Text(
                                                                            'Hepsi',
                                                                          ),
                                                                        ),
                                                                      ] +
                                                                      _carTypes
                                                                          .map(
                                                                            (
                                                                              type,
                                                                            ) => DropdownMenuItem(
                                                                              value:
                                                                                  type,
                                                                              child: Text(
                                                                                type,
                                                                              ),
                                                                            ),
                                                                          )
                                                                          .toList(),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterCarType =
                                                                                (val == ''
                                                                                    ? null
                                                                                    : val),
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Yakıt Türü
                                                                DropdownButtonFormField<
                                                                  String
                                                                >(
                                                                  initialValue:
                                                                      _filterFuelType ??
                                                                      '',
                                                                  decoration:
                                                                      const InputDecoration(
                                                                        labelText:
                                                                            'Yakıt Türü',
                                                                      ),
                                                                  items:
                                                                      [
                                                                        const DropdownMenuItem(
                                                                          value:
                                                                              '',
                                                                          child: Text(
                                                                            'Hepsi',
                                                                          ),
                                                                        ),
                                                                      ] +
                                                                      _fuelTypes
                                                                          .map(
                                                                            (
                                                                              type,
                                                                            ) => DropdownMenuItem(
                                                                              value:
                                                                                  type,
                                                                              child: Text(
                                                                                type,
                                                                              ),
                                                                            ),
                                                                          )
                                                                          .toList(),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterFuelType =
                                                                                (val == ''
                                                                                    ? null
                                                                                    : val),
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Fiyat Aralığı
                                                                const Text(
                                                                  'Fiyat Aralığı (₺)',
                                                                ),
                                                                RangeSlider(
                                                                  values:
                                                                      _filterPrice,
                                                                  min: 0,
                                                                  max: 50000,
                                                                  divisions:
                                                                      100,
                                                                  labels: RangeLabels(
                                                                    _filterPrice
                                                                        .start
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                    _filterPrice
                                                                        .end
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                  ),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterPrice =
                                                                                val,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Yıl Aralığı
                                                                const Text(
                                                                  'Model Yılı',
                                                                ),
                                                                RangeSlider(
                                                                  values:
                                                                      _filterYear,
                                                                  min: 2015,
                                                                  max: 2024,
                                                                  divisions: 9,
                                                                  labels: RangeLabels(
                                                                    _filterYear
                                                                        .start
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                    _filterYear
                                                                        .end
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                  ),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterYear =
                                                                                val,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Benzin Seviyesi
                                                                const Text(
                                                                  'Benzin Seviyesi (%)',
                                                                ),
                                                                RangeSlider(
                                                                  values:
                                                                      _filterFuelPercent,
                                                                  min: 0,
                                                                  max: 100,
                                                                  divisions: 20,
                                                                  labels: RangeLabels(
                                                                    _filterFuelPercent
                                                                        .start
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                    _filterFuelPercent
                                                                        .end
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                  ),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterFuelPercent =
                                                                                val,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Özellikler
                                                                const Text(
                                                                  'Özellikler',
                                                                ),
                                                                Wrap(
                                                                  spacing: 8,
                                                                  children:
                                                                      _ozellikler.map((
                                                                        ozellik,
                                                                      ) {
                                                                        final selected =
                                                                            _filterOzellikler.contains(
                                                                              ozellik,
                                                                            );
                                                                        return FilterChip(
                                                                          label: Text(
                                                                            ozellik,
                                                                          ),
                                                                          selected:
                                                                              selected,
                                                                          onSelected: (
                                                                            val,
                                                                          ) {
                                                                            setModalState(() {
                                                                              if (val) {
                                                                                _filterOzellikler.add(
                                                                                  ozellik,
                                                                                );
                                                                              } else {
                                                                                _filterOzellikler.remove(
                                                                                  ozellik,
                                                                                );
                                                                              }
                                                                            });
                                                                          },
                                                                        );
                                                                      }).toList(),
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Koltuk Sayısı
                                                                Row(
                                                                  children: [
                                                                    const Text(
                                                                      'Koltuk Sayısı: ',
                                                                    ),
                                                                    DropdownButton<
                                                                      int?
                                                                    >(
                                                                      value:
                                                                          _filterSeats,
                                                                      hint: const Text(
                                                                        'Hepsi',
                                                                      ),
                                                                      items:
                                                                          [
                                                                                null,
                                                                                2,
                                                                                4,
                                                                                5,
                                                                                7,
                                                                                8,
                                                                              ]
                                                                              .map(
                                                                                (
                                                                                  s,
                                                                                ) => DropdownMenuItem(
                                                                                  value:
                                                                                      s,
                                                                                  child: Text(
                                                                                    s ==
                                                                                            null
                                                                                        ? 'Hepsi'
                                                                                        : s.toString(),
                                                                                  ),
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                      onChanged:
                                                                          (
                                                                            val,
                                                                          ) => setModalState(
                                                                            () =>
                                                                                _filterSeats =
                                                                                    val,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                // Beygir Gücü
                                                                const Text(
                                                                  'Beygir Gücü (HP)',
                                                                ),
                                                                RangeSlider(
                                                                  values:
                                                                      _filterHorsePower,
                                                                  min: 0,
                                                                  max: 5000,
                                                                  divisions: 50,
                                                                  labels: RangeLabels(
                                                                    _filterHorsePower
                                                                        .start
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                    _filterHorsePower
                                                                        .end
                                                                        .toStringAsFixed(
                                                                          0,
                                                                        ),
                                                                  ),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            _filterHorsePower =
                                                                                val,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        setModalState(() {
                                                                          _filterCarType =
                                                                              null;
                                                                          _filterFuelType =
                                                                              null;
                                                                          _filterPrice = const RangeValues(
                                                                            0,
                                                                            50000,
                                                                          );
                                                                          _filterYear = const RangeValues(
                                                                            2015,
                                                                            2024,
                                                                          );
                                                                          _filterFuelPercent = const RangeValues(
                                                                            0,
                                                                            100,
                                                                          );
                                                                          _filterOzellikler =
                                                                              [];
                                                                          _filterSeats =
                                                                              null;
                                                                          _filterHorsePower = const RangeValues(
                                                                            0,
                                                                            5000,
                                                                          );
                                                                        });
                                                                      },
                                                                      child: const Text(
                                                                        'Temizle',
                                                                      ),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        setState(
                                                                          () {},
                                                                        ); // BU SATIR ÇOK ÖNEMLİ
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop();
                                                                      },
                                                                      child: const Text(
                                                                        'Filtrele',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (searchQuery.isNotEmpty &&
                                          searchResults.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: searchResults.length,
                                            itemBuilder: (ctx, i) {
                                              final car = searchResults[i];
                                              return ListTile(
                                                leading: CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                    car.imageUrl,
                                                  ),
                                                ),
                                                title: Text(
                                                  '${car.name} ${car.model}',
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    searchQuery = '';
                                                  });
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              CarDetailScreen(
                                                                car: car,
                                                              ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Main Content with White Background
                              Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Categories
                                      const Text(
                                        'Kategoriler',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 60,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: categories.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(width: 12),
                                          itemBuilder: (context, index) {
                                            final cat = categories[index];
                                            final isSelected =
                                                selectedCategory == cat;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedCategory = cat;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      isSelected
                                                          ? const LinearGradient(
                                                            colors: [
                                                              Color(0xFF667eea),
                                                              Color(0xFF764ba2),
                                                            ],
                                                          )
                                                          : null,
                                                  color:
                                                      isSelected
                                                          ? null
                                                          : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          isSelected
                                                              ? const Color(
                                                                0xFF667eea,
                                                              ).withOpacity(0.3)
                                                              : Colors.black
                                                                  .withOpacity(
                                                                    0.05,
                                                                  ),
                                                      blurRadius:
                                                          isSelected ? 10 : 5,
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cat,
                                                    style: TextStyle(
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : const Color(
                                                                0xFF2C3E50,
                                                              ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      // Popular Cars (en çok kiralananlar)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Bu hafta en çok kiralananlar',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => setState(
                                                  () => _selectedIndex = 1,
                                                ),
                                            child: const Text(
                                              'Tümünü Gör',
                                              style: TextStyle(
                                                color: Color(0xFF667eea),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 220,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: popularCars.length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(width: 16),
                                          itemBuilder: (ctx, i) {
                                            final car = popularCars[i];
                                            return GestureDetector(
                                              onTap:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pushNamed(
                                                    '/detail',
                                                    arguments: car,
                                                  ),
                                              child: Container(
                                                width: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 15,
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                          child: Image.network(
                                                            car.imageUrl,
                                                            height: 120,
                                                            width: 200,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${car.name} ${car.model}',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                  color: Color(
                                                                    0xFF2C3E50,
                                                                  ),
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              gradient: const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xFF667eea,
                                                                  ),
                                                                  Color(
                                                                    0xFF764ba2,
                                                                  ),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    15,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              '${car.pricePerDay.toStringAsFixed(0)}₺ / günde',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      // Action Cards
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionCard(
                                              'Kiralama\nGeçmişi',
                                              Icons.receipt_long,
                                              Colors.blue,
                                              () => setState(
                                                () => _selectedIndex = 2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildActionCard(
                                              'Hemen\nKirala',
                                              Icons.car_rental,
                                              Colors.green,
                                              () => setState(
                                                () => _selectedIndex = 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      // Promo Banner
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFFF6B6B),
                                              Color(0xFFFFE66D),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFF6B6B,
                                              ).withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '🎉 Özel Kampanya',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    '%20 indirimli kiralama fırsatı!\nŞimdi kirala, kazançlı çık!',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.local_offer,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          ],
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

                    // ADMIN DASHBOARD BUTONU (sadece adminler görür)

                    // ARAÇ EKLE BUTONU (sadece adminler görür)
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı rolü yüklenene kadar loading göster
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
        final pages = [
          _buildHomeTab(),
          CarsScreen(cars: cars, userRole: _userRole), // rolü ilet
          MyRentalsScreen(),
          ProfileScreen(),
        ];
        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Anasayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car),
                  label: 'Araçlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Kiralıklarım',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profilim',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
