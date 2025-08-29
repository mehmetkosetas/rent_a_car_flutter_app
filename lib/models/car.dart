// lib/models/car.dart

class Car {
  final String id;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final String description;
  final int kilometers;
  final int fuelPercentage;
  final String fuelType;
  final String bodyType;
  final int year;
  final String model;
  final String group;
  final int topSpeed;
  final int horsePower;
  final int seats;
  final List<String> ozellikler; // Yeni alan: araç özellikleri

  Car({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.description,
    required this.kilometers,
    required this.fuelPercentage,
    required this.fuelType,
    required this.bodyType,
    required this.year,
    required this.model,
    required this.group,
    required this.topSpeed,
    required this.horsePower,
    required this.seats,
    required this.ozellikler, // Yeni alan
  });

  factory Car.fromMap(String id, Map<String, dynamic> data) {
    // ozellikler alanını güvenli şekilde parse et
    List<String> ozellikler = [];
    if (data['ozellikler'] != null) {
      if (data['ozellikler'] is List) {
        ozellikler = List<String>.from(data['ozellikler']);
      }
    }

    return Car(
      id: id,
      name: data['marka'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pricePerDay: (data['gunlukKira'] ?? 0).toDouble(),
      description: data['description'] ?? '', // Firestore'dan description çek
      kilometers: data['km'] ?? 0,
      fuelPercentage: data['yakitYuzde'] ?? 0,
      fuelType: data['yakitTuru'] ?? '',
      bodyType: data['tip'] ?? '',
      year: data['yil'] ?? 0,
      model: data['model'] ?? '',
      group: '',
      topSpeed: data['topSpeed'] ?? 0, // Firestore'dan topSpeed çek
      horsePower: data['horsePower'] ?? 0, // Firestore'dan horsePower çek
      seats: data['seats'] ?? 0, // Firestore'dan seats çek
      ozellikler: ozellikler, // Güvenli şekilde parse edilmiş özellikler
    );
  }
}

// Örnek sabit veri
final sampleCars = [
  Car(
    id: '1',
    name: 'Renault Clio',
    imageUrl:
        'https://ayderrentacar.com.tr/uploads/p/vehicles/renault-clio-benzin-otomatik_1.jpg',
    pricePerDay: 8000.0,
    description: 'Uygun fiyatlı ve şehir içi kullanıma uygun bir araç.',
    kilometers: 15000,
    fuelPercentage: 85,
    fuelType: 'Benzin',
    bodyType: 'Hatchback',
    year: 2023,
    model: 'Clio',
    group: 'Economy',
    topSpeed: 180,
    horsePower: 90,
    seats: 5,
    ozellikler: ['Otomatik', 'Klima', 'Navigasyon', 'Kara Kapı'],
  ),
  Car(
    id: '2',
    name: 'BMW i8',
    imageUrl:
        'https://www.kosifleroto.com.tr/Bmw/Contents/images/T%C3%BCmSeriler/Bmwi/i8/iSerisi81.jpg',
    pricePerDay: 40000.0,
    description: 'Lüks hibrit spor araç. Hem çevreci hem güçlü.',
    kilometers: 32000,
    fuelPercentage: 60,
    fuelType: 'Hybrid',
    bodyType: 'Coupe',
    year: 2022,
    model: 'i8',
    group: 'Luxury',
    topSpeed: 250,
    horsePower: 369,
    seats: 2,
    ozellikler: ['Hibrit', 'Spor', 'Lüks', 'Navigasyon'],
  ),
  Car(
    id: '3',
    name: 'Audi A4',
    imageUrl:
        'https://images.cdn.autocar.co.uk/sites/autocar.co.uk/files/styles/gallery_slide/public/audi-a4-rt-2015-0024_0.jpg?itok=7cJ1PI3F',
    pricePerDay: 30000.0,
    description: 'Konforlu sürüş sunan güçlü bir sedan.',
    kilometers: 22000,
    fuelPercentage: 40,
    fuelType: 'Diesel',
    bodyType: 'Sedan',
    year: 2020,
    model: 'A4',
    group: 'Business',
    topSpeed: 240,
    horsePower: 150,
    seats: 5,
    ozellikler: ['Konforlu', 'Güçlü', 'Sedan', 'Navigasyon'],
  ),
  Car(
    id: '4',
    name: 'Mercedes A180',
    imageUrl: 'https://i0.shbdn.com/photos/88/49/32/x5_1246884932gdp.jpg',
    pricePerDay: 5000.0,
    description: 'Şık tasarım ve verimli motor performansı.',
    kilometers: 25000,
    fuelPercentage: 70,
    fuelType: 'Benzin',
    bodyType: 'Sedan',
    year: 2021,
    model: 'A180',
    group: 'Premium',
    topSpeed: 210,
    horsePower: 136,
    seats: 5,
    ozellikler: ['Şık', 'Verimli', 'Sedan', 'Navigasyon'],
  ),
];
