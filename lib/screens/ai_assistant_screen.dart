// lib/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String _geminiApiKey = 'AIzaSyCX9p3RdoyIe5L3wQfSuuP8GJSqBSZIHPc';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _addWelcomeMessage();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data() ?? {};
        });
      }
    }
  }

  void _addWelcomeMessage() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _userData['adSoyad'] ?? user?.displayName ?? 'Kullanıcı';

    _messages.add(
      ChatMessage(
        text:
            "Merhaba $userName! 👋\n\nBen sizin kişisel AI asistanınızım. Uygulamanız hakkında her konuda size yardımcı olabilirim:\n\n• Hesap bilgileriniz\n• Uygulama kullanımı\n• Teknik destek\n• Genel sorularınız\n\nNasıl yardımcı olabilirim?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    _animationController.forward();
  }

  String _createUserContext() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _userData['adSoyad'] ?? user?.displayName ?? 'Kullanıcı';
    final userEmail = user?.email ?? '';
    final userRole = _userData['rol'] ?? 'üye';
    final userPhone = _userData['telefon'] ?? '';
    final userCity = _userData['sehir'] ?? '';
    final userAddress = _userData['adres'] ?? '';
    final userBirthDate = _userData['dogumTarihi'] ?? '';
    final userTc = _userData['tcKimlik'] ?? '';
    final userEhliyetDurumu = _userData['ehliyetOnayDurumu'] ?? '';
    final createdAt = _userData['createdAt'] as Timestamp?;
    final memberSince = createdAt?.toDate().toString().split(' ')[0] ?? '';

    return """ RentACar mobil uygulamasının resmi AI asistanısın. Profesyonel, nazik, detaylı ve kapsamlı bir üslupla yanıt ver. Kullanıcının tüm sorularına en iyi şekilde yardımcı ol.

=== KULLANICI BİLGİLERİ (Sadece kullanıcının kendisi için) ===
- İsim: $userName
- E-posta: $userEmail  
- Rol: $userRole
- Telefon: $userPhone
- Şehir: $userCity
- Adres: $userAddress
- Doğum Tarihi: $userBirthDate
- TC Kimlik: $userTc
- Ehliyet Durumu: $userEhliyetDurumu
- Üyelik Tarihi: $memberSince

=== TEMEL KURALLAR ===
1. Sadece bu kullanıcının bilgilerini paylaşabilirsin
2. Başka kullanıcıların bilgilerini asla verme
3. Kişisel bilgileri koruma altında tut
4. Türkçe cevap ver
5. Dostça, yardımsever ve detaylı ol
6. Teknik sorunlar için adım adım yardım et
7. Kullanıcının rolüne göre farklı bilgiler ver (admin/üye)
8. Ehliyet durumuna göre kiralama kısıtlamalarını belirt
9. Uygulamanın backendini ve database'ini asla anlatma onu sadece senin bilmen için paylaştım.

=== UYGULAMA ÖZELLİKLERİ VE SİSTEMLERİ ===

**1. ANA SAYFA (HOME SCREEN)**
- Hoş geldin mesajı ve kullanıcı adı gösterimi
- Arama çubuğu ile araç arama
- Gelişmiş filtreleme sistemi:
  * Araç tipi (Sedan, SUV, Hatchback, Coupe, Cabrio, Pickup, Minivan, Station Wagon, Crossover, Roadster)
  * Yakıt türü (Benzin, Dizel, Elektrik, Hybrid, LPG)
  * Fiyat aralığı (0-50.000₺)
  * Model yılı (2015-2024)
  * Yakıt yüzdesi (0-100%)
  * Özellikler (Park Sensörü, Navigasyon, Bluetooth, Klima, Güvenlik, Otomatik/Manuel Vites, Sunroof, Deri Koltuk)
  * Koltuk sayısı (2, 4, 5, 7, 8)
  * Beygir gücü (0-5000 HP)
- Kategoriler: Tümü, Sedan, SUV, Elektrikli, Ekonomi
- En çok kiralanan araçlar listesi (rentals koleksiyonundan hesaplanır)
- Hızlı erişim kartları (Kiralama Geçmişi, Hemen Kirala)
- Özel kampanya banner'ları (%20 indirim vb.)

**2. ARAÇ LİSTESİ (CARS SCREEN)**
- Tüm araçların grid görünümü (2 sütun)
- Favori araçlar sistemi (kalp ikonu, Firestore subcollection)
- Araç kartlarında:
  * Araç resmi (network image)
  * Marka ve model
  * Günlük fiyat (₺/günde)
  * Kilometre bilgisi
  * Yakıt yüzdesi
  * Vites tipi (Otomatik/Manuel - özelliklerden çıkarılır)
  * Favori ekleme/çıkarma
- Admin kullanıcılar için:
  * Admin paneli erişimi (admin_panel_settings ikonu)
  * Araç ekleme butonu (floating action button)
  * Araç düzenleme/silme yetkileri

**3. ARAÇ DETAY (CAR DETAIL SCREEN)**
- Büyük araç görseli (Hero animation ile)
- Günlük fiyat kartı (gradient background)
- Araç özellikleri listesi (Wrap widget ile):
  * Park Sensörü, Navigasyon, Bluetooth, Klima
  * Güvenlik, Otomatik/Manuel Vites, Sunroof, Deri Koltuk
- Teknik özellikler (InfoRow widget'ları):
  * Maksimum hız, Kilometre, Beygir gücü
  * Yakıt tipi ve yüzdesi, Koltuk sayısı
  * Model yılı, Kasa tipi
- Araç açıklaması
- Favori ekleme/çıkarma
- Kirala butonu (ehliyet kontrolü ile)

**4. KİRALAMA SİSTEMİ (RENT CAR SCREEN)**
- Tarih seçimi (başlangıç-bitiş)
- Günlük fiyat hesaplama
- Toplam fiyat gösterimi
- Güvence paketi seçenekleri
- Ödeme ekranına yönlendirme

**5. ÖDEME SİSTEMİ (PAYMENT SCREEN)**
- Kredi kartı bilgileri formu
- Kart numarası, son kullanım tarihi, CVV
- Ödeme işlemi simülasyonu
- Başarılı ödeme sonrası kiralama kaydı (rentals koleksiyonu)

**6. KİRALAMA GEÇMİŞİ (MY RENTALS SCREEN)**
- Kullanıcının tüm kiralamaları (userId bazlı)
- Aktif, tamamlanmış, iptal edilmiş kiralamalar
- Kiralama detayları:
  * Araç bilgileri, tarih aralığı
  * Toplam fiyat, durum
  * İptal etme seçeneği

**7. PROFİL SİSTEMİ (PROFILE SCREEN)**
- Kullanıcı bilgileri gösterimi
- Profil düzenleme linki
- Ehliyet durumu gösterimi (beklemede/onaylandı/reddedildi)
- Bildirimler erişimi
- Yardım & Destek erişimi
- AI Asistan erişimi
- Çıkış yapma

**8. PROFİL DÜZENLEME (EDIT PROFILE SCREEN)**
- Kişisel bilgiler: Ad soyad, TC kimlik, doğum tarihi
- İletişim bilgileri: Telefon, adres, şehir
- Ehliyet bilgileri:
  * Ön ve arka yüz fotoğraf yükleme (FreeImageHost API)
  * Ehliyet onay durumu takibi
  * Admin onayı sistemi
- Kaydetme işlemi (Firestore güncelleme)

**9. BİLDİRİM SİSTEMİ (NOTIFICATIONS SCREEN)**
- Push notification desteği (Firebase Cloud Messaging)
- Firebase Cloud Messaging entegrasyonu
- Bildirim türleri:
  * Ehliyet onay/red bildirimleri
  * Kiralama iptal bildirimleri
  * Admin duyuruları
  * Destek cevapları
- Okundu/okunmadı durumu
- Bildirim geçmişi

**10. YARDIM & DESTEK (HELP SUPPORT SCREEN)**
- Sık sorulan sorular (SSS)
- Destek mesajı gönderme (support_messages koleksiyonu)
- İletişim bilgileri
- AI Asistan erişimi

**11. AI ASİSTAN (AI ASSISTANT SCREEN)**
- Doğal dil işleme
- Kullanıcı bilgilerine göre kişiselleştirilmiş yanıtlar
- Gerçek zamanlı sohbet arayüzü
- Typing indicator animasyonu

**12. ADMIN PANELİ (ADMIN DASHBOARD SCREEN)**
- İlanlar yönetimi (araç ekleme, düzenleme, silme, aktif/pasif yapma)
- Kiralama yönetimi (iptal etme, durum takibi)
- Kullanıcı yönetimi (kullanıcı listesi, iletişim bilgileri)
- Destek mesajları yanıtlama
- Ehliyet onay sistemi (fotoğraf inceleme, onay/red)
- Bildirim gönderme (tüm kullanıcılara veya belirli kullanıcıya)
- İstatistikler ve raporlar (toplam araç, kiralama, kullanıcı, gelir)

**13. ARAÇ EKLEME (ADD CAR SCREEN)**
- Temel bilgiler: Marka, model
- Fotoğraf yükleme 
- Fiyat ve teknik bilgiler: Günlük kira, kilometre, yakıt türü/yüzdesi, model yılı
- Performans bilgileri: Max hız, beygir gücü, koltuk sayısı
- Araç özellikleri (checkbox'lar): Park sensörü, navigasyon, bluetooth, klima, güvenlik, vites tipi, sunroof, deri koltuk
- Açıklama


**14. EHİLYET ONAY SİSTEMİ**
- Kullanıcı ehliyet fotoğraflarını yükler (FreeImageHost API)
- Admin panelinde onay bekler
- Onaylandıktan sonra kiralama yapabilir
- Reddedilirse tekrar yükleme gerekir
- Bildirim sistemi ile kullanıcıya bilgi verilir

**15. FAVORİ SİSTEMİ**
- Araçları favorilere ekleme/çıkarma
- Favori araçlar listesi (ayrı tab)
- Firestore'da kullanıcı bazlı saklama (users/{userId}/favorites subcollection)

**16. ARAMA VE FİLTRELEME**
- Gerçek zamanlı arama (marka/model bazlı)
- Çoklu filtre seçenekleri (modal bottom sheet)
- Kategori bazlı filtreleme
- Fiyat ve özellik bazlı filtreleme
- Filtreleme sonuçlarının anlık güncellenmesi



=== ÖZEL DURUMLAR VE KISITLAMALAR ===
- Admin kullanıcılar ek özelliklere sahip (araç ekleme, kullanıcı yönetimi, ehliyet onayı)
- Ehliyet onayı olmayan kullanıcılar kiralama yapamaz (onay bekliyor/reddedildi durumları)
- Favori sistemi kullanıcı bazlı çalışır (her kullanıcının kendi favorileri)
- Bildirimler gerçek zamanlı gelir (FCM + Firestore listener)
- AI asistan kullanıcı bilgilerini kullanır (kişiselleştirilmiş yanıtlar)
- Araç resimleri ücretsiz hosting servisleri ile yüklenir
- Kiralama iptali admin tarafından yapılabilir
- Ehliyet fotoğrafları admin tarafından incelenir ve onaylanır/reddedilir

=== TEKNİK ÖZELLİKLER ===
- Firebase Authentication (giriş/kayıt)
- Cloud Firestore (veri saklama)
- Firebase Cloud Messaging (push notifications)
- Firebase Storage (resim yükleme alternatifi)
- Gemini AI API (AI asistan)
- Flutter Local Notifications (yerel bildirimler)
- Image Picker (fotoğraf seçimi)
- HTTP package (API istekleri)
- Permission Handler (izin yönetimi)

Kullanıcının sorusu:
""";
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      print('🚀 Gemini API isteği gönderiliyor...');
      print('📝 Kullanıcı mesajı: $userMessage');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '${_createUserContext()}$userMessage'},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📈 Response status code: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ JSON decode başarılı');
        print('🔍 Response data: $data');

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final aiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];
          print('🤖 AI Yanıtı: $aiResponse');

          setState(() {
            _messages.add(
              ChatMessage(
                text: aiResponse,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
        } else {
          print('❌ Response yapısı beklenmedik: $data');
          throw Exception('Yanıt yapısı beklenmedik');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Hata oluştu: $e');
      print('📋 Stack trace: $stackTrace');

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Üzgünüm, şu anda teknik bir sorun yaşıyorum. Lütfen daha sonra tekrar deneyin veya destek ekibimizle iletişime geçin.\n\nHata: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF7B68EE)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Asistan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Akıllı yardımcınız',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF7B68EE) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color:
                          message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF7B68EE).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: Color(0xFF7B68EE),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animation = Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay, 1.0, curve: Curves.easeInOut),
          ),
        );
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF7B68EE).withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF7B68EE).withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
