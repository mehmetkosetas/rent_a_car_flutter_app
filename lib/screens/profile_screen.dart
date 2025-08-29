// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'ai_assistant_screen.dart'; // Yeni import
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data() ?? {};
    return {
      'name': data['adSoyad'] ?? user.displayName ?? 'Kullanıcı',
      'email': user.email ?? '',
      'createdAt': data['createdAt'] as Timestamp?,
      'role': data['rol'] ?? 'üye',
      'phone': data['telefon'] ?? '',
      'photoUrl': data['photoUrl'] ?? '',
      'address': data['adres'] ?? '',
      'city': data['sehir'] ?? '',
      'tcKimlik': data['tcKimlik'] ?? '',
      'dogumTarihi': data['dogumTarihi'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B68EE)),
              );
            }

            final info = snap.data ?? {};
            final name = info['name'] as String;
            final email = info['email'] as String;
            final role = info['role'] as String;
            final phone = info['phone'] as String;
            final photoUrl = info['photoUrl'] as String;
            final address = info['address'] as String;
            final city = info['city'] as String;
            final createdAtTs = info['createdAt'] as Timestamp?;
            final createdAt = createdAtTs?.toDate();

            return SingleChildScrollView(
              child: Column(
                children: [
                  // --- HEADER ---
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Başlık ve ayarlar ikonu
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profilim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // BİLDİRİM ÇANI VE SAYACI
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('notifications')
                                        .where(
                                          'userId',
                                          isEqualTo:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid,
                                        )
                                        .where('read', isEqualTo: false)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  int unreadCount = 0;
                                  if (snapshot.hasData) {
                                    unreadCount = snapshot.data!.docs.length;
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const NotificationsScreen(),
                                          ),
                                        );
                                      },
                                      icon: Stack(
                                        children: [
                                          const Icon(
                                            Icons.notifications,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          // Bildirim sayısı varsa göster
                                          if (unreadCount > 0)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  ),
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                child: Text(
                                                  unreadCount > 9
                                                      ? '9+'
                                                      : unreadCount.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Avatar ve bilgiler
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child:
                                        photoUrl.isNotEmpty
                                            ? ClipOval(
                                              child: Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : Center(
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${role[0].toUpperCase()}${role.substring(1)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- STAT KARTLARI ---
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.calendar_today,
                                  title: 'Üyelik',
                                  subtitle:
                                      createdAt != null
                                          ? '${createdAt.day}.${createdAt.month}.${createdAt.year}'
                                          : '-',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.phone,
                                  title: 'Telefon',
                                  subtitle:
                                      phone.isNotEmpty
                                          ? phone
                                          : 'Belirtilmemiş',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.location_on,
                                  title: 'Şehir',
                                  subtitle:
                                      city.isNotEmpty ? city : 'Belirtilmemiş',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.home,
                                  title: 'Adres',
                                  subtitle:
                                      address.isNotEmpty
                                          ? (address.length > 15
                                              ? '${address.substring(0, 15)}...'
                                              : address)
                                          : 'Belirtilmemiş',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- MENÜ ve DESTEK BÖLÜMLERİ ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Hesap ayarları
                        _buildSectionHeader('Hesap'),
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Şifre Sıfırla',
                          subtitle: 'E-posta ile şifre değiştir',
                          onTap: () async {
                            await auth.sendPasswordResetEmail(email: email);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Şifre sıfırlama bağlantısı gönderildi.',
                                  ),
                                  backgroundColor: Color(0xFF7B68EE),
                                ),
                              );
                            }
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.edit_outlined,
                          title: 'Profili Düzenle',
                          subtitle: 'Kişisel bilgilerini güncelle',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // AI Asistan Bölümü - YENİ
                        _buildSectionHeader('Akıllı Asistan'),
                        _buildMenuItem(
                          icon: Icons.psychology_outlined,
                          title: 'AI Asistan',
                          subtitle: 'Sorularınız için akıllı yardımcınız',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIAssistantScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Destek
                        _buildSectionHeader('Destek'),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'Hakkımızda',
                          subtitle: 'Uygulama hakkında bilgi',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Gizlilik Politikası',
                          subtitle: 'Veri kullanım koşulları',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Yardım',
                          subtitle: 'SSS ve destek',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Çıkış Yap
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder:
                                  (c) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Çıkış Yap'),
                                    content: const Text(
                                      'Çıkış yapmak istediğinize emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(c, false),
                                        child: const Text('İptal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Çıkış Yap'),
                                      ),
                                    ],
                                  ),
                            );
                            if (yes == true) await auth.signOut();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.logout,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Çıkış Yap',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.red.shade300,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    ),
  );

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7B68EE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF7B68EE), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B68EE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7B68EE), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    ),
  );
}
