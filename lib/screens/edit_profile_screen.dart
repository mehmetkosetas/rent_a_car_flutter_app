// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _tcController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isUploadingEhliyetOn = false;
  bool _isUploadingEhliyetArka = false;
  File? _ehliyetOnFile;
  File? _ehliyetArkaFile;
  String? _ehliyetOnUrl;
  String? _ehliyetArkaUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['adSoyad'] ?? '';
        _phoneController.text = data['telefon'] ?? '';
        _addressController.text = data['adres'] ?? '';
        _cityController.text = data['sehir'] ?? '';
        _birthdateController.text = data['dogumTarihi'] ?? '';
        _tcController.text = data['tcKimlik'] ?? '';
        _emergencyContactController.text = data['acilDurumKisi'] ?? '';
        _emergencyPhoneController.text = data['acilDurumTelefon'] ?? '';
        _ehliyetOnUrl = data['ehliyetOnUrl'];
        _ehliyetArkaUrl = data['ehliyetArkaUrl'];
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
            'FreeImageHost yükleme başarısız: \\${jsonResponse['error']['message']}',
          );
        }
      } else {
        throw Exception('HTTP Error: \\${response.statusCode}');
      }
    } catch (e) {
      print('FreeImageHost yükleme hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  Future<void> _pickEhliyetImage({required bool isOn}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        if (isOn) {
          _isUploadingEhliyetOn = true;
        } else {
          _isUploadingEhliyetArka = true;
        }
      });
      try {
        final url = await _uploadImageToFreeImageHost(File(picked.path));
        setState(() {
          if (isOn) {
            _ehliyetOnFile = File(picked.path);
            _ehliyetOnUrl = url;
            _isUploadingEhliyetOn = false;
          } else {
            _ehliyetArkaFile = File(picked.path);
            _ehliyetArkaUrl = url;
            _isUploadingEhliyetArka = false;
          }
        });
      } catch (e) {
        setState(() {
          if (isOn) {
            _isUploadingEhliyetOn = false;
          } else {
            _isUploadingEhliyetArka = false;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resim yüklenemedi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final updateData = <String, dynamic>{
        'adSoyad': _nameController.text.trim(),
        'telefon': _phoneController.text.trim(),
        'adres': _addressController.text.trim(),
        'sehir': _cityController.text.trim(),
        'dogumTarihi': _birthdateController.text.trim(),
        'tcKimlik': _tcController.text.trim(),
        'acilDurumKisi': _emergencyContactController.text.trim(),
        'acilDurumTelefon': _emergencyPhoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Boş alanları kaldır
      updateData.removeWhere((key, value) => value == '');

      // Ehliyet resimleri yüklendi mi kontrol et
      bool ehliyetYuklendi = false;
      if (_ehliyetOnUrl != null && _ehliyetOnUrl!.isNotEmpty) {
        updateData['ehliyetOnUrl'] = _ehliyetOnUrl;
        ehliyetYuklendi = true;
      }
      if (_ehliyetArkaUrl != null && _ehliyetArkaUrl!.isNotEmpty) {
        updateData['ehliyetArkaUrl'] = _ehliyetArkaUrl;
        ehliyetYuklendi = true;
      }

      // Eğer ehliyet resimleri yüklendiyse onay durumunu "beklemede" yap
      if (ehliyetYuklendi) {
        updateData['ehliyetOnayDurumu'] = 'beklemede';
        updateData['ehliyetOnayTarihi'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      // Eğer ehliyet yüklendiyse admin'e bildirim gönder
      if (ehliyetYuklendi) {
        await _sendEhliyetNotification(user.uid, _nameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Color(0xFF7B68EE),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEhliyetNotification(String userId, String userName) async {
    try {
      // Tüm admin kullanıcılarına bildirim gönder
      final adminUsers =
          await FirebaseFirestore.instance
              .collection('users')
              .where('rol', isEqualTo: 'admin')
              .get();

      for (var adminDoc in adminUsers.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': adminDoc.id,
          'title': 'Yeni Ehliyet Onay Talebi',
          'message':
              '$userName adlı kullanıcı ehliyet bilgilerinin onaylanmasını istiyor.',
          'type': 'ehliyet_onay',
          'data': {
            'userId': userId,
            'userName': userName,
            'ehliyetOnUrl': _ehliyetOnUrl,
            'ehliyetArkaUrl': _ehliyetArkaUrl,
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Ehliyet bildirimi gönderilemedi: $e');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 yaş
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (date != null) {
      _birthdateController.text = '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7B68EE)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kişisel Bilgiler
              _buildSectionHeader('Kişisel Bilgiler'),
              _buildTextField(
                controller: _nameController,
                label: 'Ad Soyad',
                icon: Icons.person,
                validator:
                    (value) =>
                        value?.isEmpty == true ? 'Ad soyad gerekli' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tcController,
                label: 'TC Kimlik No',
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _birthdateController,
                label: 'Doğum Tarihi',
                icon: Icons.cake,
                readOnly: true,
                onTap: _selectDate,
              ),

              const SizedBox(height: 24),

              // İletişim Bilgileri
              _buildSectionHeader('İletişim Bilgileri'),
              _buildTextField(
                controller: _phoneController,
                label: 'Telefon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Adres',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'Şehir ',
                icon: Icons.location_city,
              ),

              const SizedBox(height: 24),

              // Ehliyet Bilgileri
              _buildSectionHeader('Ehliyet Bilgileri'),

              // Ehliyet durumu bilgisi
              FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final ehliyetDurumu = data?['ehliyetOnayDurumu'] ?? '';
                    if (ehliyetDurumu.isNotEmpty) {
                      Color statusColor;
                      String statusText;
                      IconData statusIcon;

                      switch (ehliyetDurumu) {
                        case 'beklemede':
                          statusColor = Colors.orange;
                          statusText = 'Ehliyet onay bekliyor';
                          statusIcon = Icons.schedule;
                          break;
                        case 'onaylandi':
                          statusColor = Colors.green;
                          statusText = 'Ehliyet onaylandı';
                          statusIcon = Icons.check_circle;
                          break;
                        case 'reddedildi':
                          statusColor = Colors.red;
                          statusText = 'Ehliyet reddedildi';
                          statusIcon = Icons.cancel;
                          break;
                        default:
                          statusColor = Colors.grey;
                          statusText = 'Ehliyet durumu bilinmiyor';
                          statusIcon = Icons.help;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Ön Yüz',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickEhliyetImage(isOn: true),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _ehliyetOnFile != null
                                  ? Image.file(
                                    _ehliyetOnFile!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : (_ehliyetOnUrl != null &&
                                      _ehliyetOnUrl!.isNotEmpty)
                                  ? Image.network(
                                    _ehliyetOnUrl!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    height: 80,
                                    width: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.add_a_photo,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                              if (_isUploadingEhliyetOn)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black26,
                                    child: Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color(0xFF7B68EE),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Arka Yüz',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickEhliyetImage(isOn: false),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _ehliyetArkaFile != null
                                  ? Image.file(
                                    _ehliyetArkaFile!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : (_ehliyetArkaUrl != null &&
                                      _ehliyetArkaUrl!.isNotEmpty)
                                  ? Image.network(
                                    _ehliyetArkaUrl!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    height: 80,
                                    width: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.add_a_photo,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                              if (_isUploadingEhliyetArka)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black26,
                                    child: Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color(0xFF7B68EE),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B68EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7B68EE),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7B68EE)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B68EE), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: maxLength != null ? '' : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _birthdateController.dispose();
    _tcController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}
