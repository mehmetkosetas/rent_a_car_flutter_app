// lib/screens/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;
  String? _feedback;

  // Örnek SSS verisi; isterseniz Firestore'dan da çekebilirsiniz.
  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'Rezervasyon nasıl yapılıyor?',
      answer:
          'Araç listesinden istediğiniz aracı seçin, tarihleri girin ve "Kirala" butonuna basın.',
    ),
    _FaqItem(
      question: 'Ödeme yöntemleri nelerdir?',
      answer:
          'Kredi kartı, banka kartı veya havale/EFT ile ödeme yapabilirsiniz.',
    ),
    _FaqItem(
      question: 'İptal ve iade koşulları?',
      answer:
          'Rezervasyonunuzu kiralama tarihinden 24 saat önce iptal ederseniz tam iade alırsınız.',
    ),
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSupportMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _feedback = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid == null) throw Exception("Kullanıcı oturumu yok.");

      // Firestore'dan kullanıcı bilgilerini çek
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final adSoyad = userDoc.data()?['adSoyad'] ?? 'İsimsiz';
      final email = user?.email ?? '';
      final message = _messageCtrl.text.trim();

      // Boş mesaj gönderilmesini engelle
      if (message.isEmpty) {
        setState(() {
          _feedback = 'Mesaj boş olamaz.';
        });
        return;
      }

      // Mesajı Firestore'a kaydet
      await FirebaseFirestore.instance.collection('support_messages').add({
        'userId': uid,
        'adSoyad': adSoyad,
        'email': email,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _feedback = 'Mesajınız gönderildi, en kısa sürede size döneceğiz.';
        _messageCtrl.clear();
      });
    } catch (e) {
      print('Destek mesajı hatası: $e');
      setState(() {
        _feedback = 'Hata oluştu. Lütfen tekrar deneyin.';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Profil ekranıyla uyumlu gradient başlık
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yardım & Destek',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  const SizedBox(height: 12),

                  // Sık Sorulan Sorular
                  const Text(
                    'Sık Sorulan Sorular',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._buildFaqList(),

                  const SizedBox(height: 24),

                  // Canlı Destek Formu
                  const Text(
                    'Bize Mesaj Gönder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _messageCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Sorununuzu veya talebinizi buraya yazın...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'En az 5 karakter girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_feedback != null)
                          Text(
                            _feedback!,
                            style: TextStyle(
                              color:
                                  _feedback!.startsWith('Hata')
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendSupportMessage,
                            icon:
                                _isSending
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.send),
                            label: Text(
                              _isSending ? 'Gönderiliyor...' : 'Gönder',
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // İletişim Bilgileri
                  const Text(
                    'Hızlı İletişim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.email, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(child: Text('support@rentacar.com')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.phone, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('+90 123 456 7890'),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFaqList() {
    return _faqs.map((item) {
      return ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(item.answer),
          ),
        ],
      );
    }).toList();
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
