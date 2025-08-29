import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _markaCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _gunlukKiraCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _yakitYuzdeCtrl = TextEditingController();
  final _yilCtrl = TextEditingController();
  final _topSpeedCtrl = TextEditingController();
  final _horsePowerCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  bool _isLoading = false;

  // Fotoğraf seçimi
  File? _selectedImage;
  String? _uploadedImageUrl;

  // Araç özellikleri için checkbox'lar
  bool _parkSensoru = false;
  bool _navigasyon = false;
  bool _bluetooth = false;
  bool _klima = false;
  bool _guvenlik = false;
  bool _otomatikVites = false;
  bool _manuelVites = false;
  bool _sunroof = false;
  bool _deriKoltuk = false;

  // Kategori ve yakıt türü seçenekleri
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

  String? _selectedCarType;
  String? _selectedFuelType;

  @override
  void dispose() {
    _markaCtrl.dispose();
    _modelCtrl.dispose();
    _gunlukKiraCtrl.dispose();
    _kmCtrl.dispose();
    _yakitYuzdeCtrl.dispose();
    _yilCtrl.dispose();
    _topSpeedCtrl.dispose();
    _horsePowerCtrl.dispose();
    _seatsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Android 13+ için galeri izni, öncesi için storage izni
    final photosStatus = await Permission.photos.request();
    final storageStatus = await Permission.storage.request();

    // En az birinin granted olması yeterli!
    if (!(photosStatus.isGranted || storageStatus.isGranted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeriye erişim izni gerekli!')),
      );
      return;
    }
    if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // İyi kalite, makul boyut
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      print('Fotoğraf seçilemedi: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotoğraf seçilemedi: $e')));
    }
  }

  // ImgBB'ye resim yükleme fonksiyonu (ücretsiz - sınırsız boyut)
  Future<String> _uploadImageToImgBB(File imageFile) async {
    try {
      // ImgBB API key - ücretsiz hesap açıp alabilirsiniz: https://api.imgbb.com/
      const String apiKey =
          "YOUR_IMGBB_API_KEY"; // Buraya kendi API key'inizi yazın

      if (apiKey == "YOUR_IMGBB_API_KEY") {
        throw Exception("Lütfen ImgBB API key'inizi ayarlayın");
      }

      final String url = "https://api.imgbb.com/1/upload";

      // Dosyayı base64'e çevir
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(url),
        body: {
          'key': apiKey,
          'image': base64Image,
          'name': 'car_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['url'];
        } else {
          throw Exception(
            'ImgBB yükleme başarısız: ${jsonResponse['error']['message']}',
          );
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('ImgBB yükleme hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  // Supabase Storage'a yükleme (tamamen ücretsiz - 1GB)
  Future<String> _uploadImageToSupabase(File imageFile) async {
    try {
      const String supabaseUrl = "YOUR_SUPABASE_URL";
      const String supabaseKey = "YOUR_SUPABASE_ANON_KEY";
      const String bucketName = "car-images";

      if (supabaseUrl == "YOUR_SUPABASE_URL") {
        throw Exception("Lütfen Supabase bilgilerinizi ayarlayın");
      }

      String fileName = 'car_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$supabaseUrl/storage/v1/object/$bucketName/$fileName'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'multipart/form-data',
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        return '$supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
      } else {
        throw Exception('Supabase yükleme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Supabase yükleme hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  // Freeimage.host'a yükleme (tamamen ücretsiz - sınırsız)
  Future<String> _uploadImageToFreeImageHost(File imageFile) async {
    try {
      const String url = "https://freeimage.host/api/1/upload";
      const String apiKey = "6d207e02198a847aa98d0a2a901485a5"; // Public key

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['key'] = apiKey;
      request.fields['action'] = 'upload';
      request.fields['format'] = 'json';

      request.files.add(
        await http.MultipartFile.fromPath('source', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseData);
        if (jsonResponse['status_code'] == 200) {
          return jsonResponse['image']['url'];
        } else {
          throw Exception(
            'FreeImageHost yükleme başarısız: ${jsonResponse['error']['message']}',
          );
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('FreeImageHost yükleme hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  // Resmi otomatik sıkıştırma ve yükleme
  Future<String> _uploadImageWithBestOption(File imageFile) async {
    try {
      // Seçenek 1: FreeImageHost (en kolay, API key gerektirmez)
      try {
        return await _uploadImageToFreeImageHost(imageFile);
      } catch (e) {
        print('FreeImageHost başarısız, ImgBB deneniyor...');
      }

      // Seçenek 2: ImgBB (API key gerekli)
      try {
        return await _uploadImageToImgBB(imageFile);
      } catch (e) {
        print('ImgBB başarısız, Supabase deneniyor...');
      }

      // Seçenek 3: Supabase (kurulum gerekli)
      try {
        return await _uploadImageToSupabase(imageFile);
      } catch (e) {
        print('Tüm seçenekler başarısız');
      }

      throw Exception(
        'Resim yüklenemedi. Lütfen internet bağlantınızı kontrol edin.',
      );
    } catch (e) {
      throw Exception('Resim yükleme hatası: $e');
    }
  }

  Future<void> _addCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir fotoğraf seçin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl;

      // Otomatik en iyi seçeneği dene
      imageUrl = await _uploadImageWithBestOption(_selectedImage!);

      // Seçilen özellikleri listeye ekle
      List<String> ozellikler = [];
      if (_parkSensoru) ozellikler.add('Park Sensörü');
      if (_navigasyon) ozellikler.add('Navigasyon');
      if (_bluetooth) ozellikler.add('Bluetooth');
      if (_klima) ozellikler.add('Klima');
      if (_guvenlik) ozellikler.add('Güvenlik');
      if (_otomatikVites) ozellikler.add('Otomatik Vites');
      if (_manuelVites) ozellikler.add('Manuel Vites');
      if (_sunroof) ozellikler.add('Sunroof');
      if (_deriKoltuk) ozellikler.add('Deri Koltuk');

      // Firestore'a araç bilgilerini kaydet
      await FirebaseFirestore.instance.collection('cars').add({
        'marka': _markaCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'imageUrl': imageUrl,
        'gunlukKira': double.tryParse(_gunlukKiraCtrl.text) ?? 0,
        'km': int.tryParse(_kmCtrl.text) ?? 0,
        'yakitTuru': _selectedFuelType ?? '',
        'yakitYuzde': int.tryParse(_yakitYuzdeCtrl.text) ?? 0,
        'tip': _selectedCarType ?? '',
        'yil': int.tryParse(_yilCtrl.text) ?? 0,
        'ozellikler': ozellikler,
        'topSpeed': int.tryParse(_topSpeedCtrl.text) ?? 0,
        'horsePower': int.tryParse(_horsePowerCtrl.text) ?? 0,
        'seats': int.tryParse(_seatsCtrl.text) ?? 0,
        'description': _descriptionCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Araç başarıyla eklendi!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Araç ekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Araç eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Araba Ekle'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Temel Bilgiler Bölümü
              _buildSectionTitle('Temel Bilgiler'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _markaCtrl,
                decoration: _buildInputDecoration('Marka', Icons.car_rental),
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _modelCtrl,
                decoration: _buildInputDecoration(
                  'Model',
                  Icons.directions_car,
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),

              const SizedBox(height: 20),

              // Fotoğraf Bölümü
              _buildSectionTitle('Araç Fotoğrafı'),
              const SizedBox(height: 8),

              // Bilgi mesajı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sınırsız boyutta resim yükleyebilirsiniz',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child:
                    _selectedImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                        : Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2C3E50),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Color(0xFF2C3E50),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Fotoğraf seçmek için tıklayın',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '(Sınırsız boyut)',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),

              const SizedBox(height: 20),

              // Fiyat ve Teknik Bilgiler
              _buildSectionTitle('Fiyat ve Teknik Bilgiler'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gunlukKiraCtrl,
                      decoration: _buildInputDecoration(
                        'Günlük Kira (₺)',
                        Icons.monetization_on,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kmCtrl,
                      decoration: _buildInputDecoration(
                        'Kilometre',
                        Icons.speed,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dropdown'lar
              DropdownButtonFormField<String>(
                initialValue: _selectedFuelType,
                decoration: _buildInputDecoration(
                  'Yakıt Türü',
                  Icons.local_gas_station,
                ),
                items:
                    _fuelTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedFuelType = val),
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yakitYuzdeCtrl,
                      decoration: _buildInputDecoration(
                        'Yakıt Yüzde (%)',
                        Icons.battery_std,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yilCtrl,
                      decoration: _buildInputDecoration(
                        'Model Yılı',
                        Icons.calendar_today,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedCarType,
                decoration: _buildInputDecoration('Araç Tipi', Icons.category),
                items:
                    _carTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _selectedCarType = val),
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),

              const SizedBox(height: 20),

              // Performans Bilgileri
              _buildSectionTitle('Performans Bilgileri'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _topSpeedCtrl,
                      decoration: _buildInputDecoration(
                        'Max Hız (km/h)',
                        Icons.speed,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _horsePowerCtrl,
                      decoration: _buildInputDecoration(
                        'Beygir Gücü (HP)',
                        Icons.power,
                      ),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _seatsCtrl,
                decoration: _buildInputDecoration(
                  'Koltuk Sayısı',
                  Icons.airline_seat_recline_normal,
                ),
                keyboardType: TextInputType.number,
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),

              const SizedBox(height: 20),

              // Araç Özellikleri Bölümü
              _buildSectionTitle('Araç Özellikleri'),
              const SizedBox(height: 12),

              // Özellikler Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildFeatureCheckbox(
                    'Park Sensörü',
                    _parkSensoru,
                    Icons.sensors,
                    (value) => setState(() => _parkSensoru = value!),
                  ),
                  _buildFeatureCheckbox(
                    'Navigasyon',
                    _navigasyon,
                    Icons.navigation,
                    (value) => setState(() => _navigasyon = value!),
                  ),
                  _buildFeatureCheckbox(
                    'Bluetooth',
                    _bluetooth,
                    Icons.bluetooth,
                    (value) => setState(() => _bluetooth = value!),
                  ),
                  _buildFeatureCheckbox(
                    'Klima',
                    _klima,
                    Icons.ac_unit,
                    (value) => setState(() => _klima = value!),
                  ),
                  _buildFeatureCheckbox(
                    'Güvenlik',
                    _guvenlik,
                    Icons.security,
                    (value) => setState(() => _guvenlik = value!),
                  ),
                  // Otomatik Vites
                  _buildFeatureCheckbox(
                    'Otomatik Vites',
                    _otomatikVites,
                    Icons.settings,
                    (value) => setState(() {
                      if (value == true) {
                        _otomatikVites = true;
                        _manuelVites = false;
                      } else {
                        _otomatikVites = false;
                      }
                    }),
                  ),

                  // Manuel Vites
                  _buildFeatureCheckbox(
                    'Manuel Vites',
                    _manuelVites,
                    Icons.settings,
                    (value) => setState(() {
                      if (value == true) {
                        _manuelVites = true;
                        _otomatikVites = false;
                      } else {
                        _manuelVites = false;
                      }
                    }),
                  ),
                  _buildFeatureCheckbox(
                    'Sunroof',
                    _sunroof,
                    Icons.wb_sunny,
                    (value) => setState(() => _sunroof = value!),
                  ),
                  _buildFeatureCheckbox(
                    'Deri Koltuk',
                    _deriKoltuk,
                    Icons.chair,
                    (value) => setState(() => _deriKoltuk = value!),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Açıklama
              _buildSectionTitle('Açıklama'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: _buildInputDecoration(
                  'Araç hakkında detaylı bilgi...',
                  Icons.description,
                ),
                maxLines: 4,
                validator:
                    (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),

              const SizedBox(height: 30),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _addCar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Kaydediliyor...'),
                          ],
                        )
                        : const Text(
                          'Aracı Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2C3E50)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C3E50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildFeatureCheckbox(
    String title,
    bool value,
    IconData icon,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            value ? const Color(0xFF2C3E50).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? const Color(0xFF2C3E50) : Colors.grey[300]!,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2C3E50)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        activeColor: const Color(0xFF2C3E50),
      ),
    );
  }
}
