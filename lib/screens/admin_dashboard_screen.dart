import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<DashboardTab> _tabs = [
    DashboardTab(Icons.car_rental, 'İlanlar', 0),
    DashboardTab(Icons.assignment, 'Kiralamalar', 1),
    DashboardTab(Icons.people, 'Kullanıcılar', 2),
    DashboardTab(Icons.chat, 'Destek', 3),
    DashboardTab(Icons.notifications, 'Bildirimler', 4),
    DashboardTab(Icons.analytics, 'İstatistikler', 5),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Horizontal Tab Bar
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () => _selectTab(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF2C3E50)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF2C3E50)
                                : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildCarsTab(),
                _buildRentalsTab(),
                _buildUsersTab(),
                _buildSupportMessagesTab(),
                _buildNotificationTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add-car');
                },
                backgroundColor: const Color(0xFF2C3E50),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Improved Notification Tab with better layout
  Widget _buildNotificationTab() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String notificationType = 'all';
    String? specificUserId;
    String? specificUserEmail;
    // String? specificUserName; // unused

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Notification Form Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yeni Bildirim',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Title Field
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message Field
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mesaj',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Kime:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs;

                      return Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Tüm Kullanıcılar'),
                            value: 'all',
                            groupValue: notificationType,
                            onChanged: (value) {
                              setState(() {
                                notificationType = value!;
                                specificUserId = null;
                                specificUserEmail = null;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Belirli Kullanıcı'),
                            value: 'specific',
                            groupValue: notificationType,
                            onChanged: (value) {
                              setState(() {
                                notificationType = value!;
                              });
                            },
                          ),
                          if (notificationType == 'specific')
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: specificUserId,
                                hint: const Text('Kullanıcı Seçin'),
                                isExpanded: true,
                                items:
                                    users.map((user) {
                                      final userData =
                                          user.data() as Map<String, dynamic>;
                                      return DropdownMenuItem(
                                        value: user.id,
                                        child: Text(
                                          userData['adSoyad'] ??
                                              'İsimsiz Kullanıcı',
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    specificUserId = value;
                                    final selectedUser = users.firstWhere(
                                      (user) => user.id == value,
                                    );
                                    final userData =
                                        selectedUser.data()
                                            as Map<String, dynamic>;
                                    specificUserEmail = userData['email'];
                                  });
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => _sendNotificationAction(
                            titleController,
                            messageController,
                            notificationType,
                            specificUserId,
                            specificUserEmail,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C3E50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Bildirim Gönder',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSentNotificationsList(),
        ],
      ),
    );
  }

  Future<void> _sendNotificationAction(
    TextEditingController titleController,
    TextEditingController messageController,
    String notificationType,
    String? specificUserId,
    String? specificUserEmail,
  ) async {
    if (titleController.text.isEmpty || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık ve mesaj boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (notificationType == 'all') {
        final usersSnapshot =
            await FirebaseFirestore.instance.collection('users').get();
        int count = 0;

        for (var userDoc in usersSnapshot.docs) {
          await _sendNotification(
            userDoc.id,
            titleController.text,
            messageController.text,
            'announcement',
          );
          count++;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count adet kullanıcıya bildirim gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (notificationType == 'specific' && specificUserId != null) {
        await _sendNotification(
          specificUserId,
          titleController.text,
          messageController.text,
          'announcement',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$specificUserEmail adlı kullanıcıya bildirim gönderildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      titleController.clear();
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Keep all other existing methods unchanged
  Widget _buildSupportMessagesTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF2C3E50),
              tabs: [
                Tab(text: 'Destek Mesajları'),
                Tab(text: 'Ehliyet Onayları'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildSupportMessages(), _buildEhliyetOnaylari()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('support_messages')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return const Center(
            child: Text('Henüz destek mesajı bulunmamaktadır'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final userId = message['userId'] ?? '';
            final userName = message['userName'] ?? 'İsimsiz Kullanıcı';
            final email = message['email'] ?? 'E-posta yok';

            // Eğer userName yoksa Firestore'dan çek
            if (userName == 'İsimsiz Kullanıcı' && userId.isNotEmpty) {
              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userSnap) {
                  String displayName = userName;
                  String displayEmail = email;
                  if (userSnap.connectionState == ConnectionState.done &&
                      userSnap.hasData &&
                      userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>;
                    displayName =
                        userData['adSoyad'] ?? userData['email'] ?? userName;
                    displayEmail = userData['email'] ?? email;
                  }
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('$displayName ($displayEmail)'),
                      subtitle: Text(
                        message['message'] ?? 'Mesaj yok',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap:
                          () => _showMessageDetails(
                            message,
                            userId,
                            displayName,
                            displayEmail,
                          ),
                    ),
                  );
                },
              );
            } else {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('$userName ($email)'),
                  subtitle: Text(
                    message['message'] ?? 'Mesaj yok',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      () =>
                          _showMessageDetails(message, userId, userName, email),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEhliyetOnaylari() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('ehliyetOnayDurumu', isEqualTo: 'beklemede')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const Center(
            child: Text('Bekleyen ehliyet onay talebi bulunmamaktadır'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final userName = userData['adSoyad'] ?? 'İsimsiz Kullanıcı';
            final email = userData['email'] ?? '';
            final ehliyetOnUrl = userData['ehliyetOnUrl'] ?? '';
            final ehliyetArkaUrl = userData['ehliyetArkaUrl'] ?? '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2C3E50),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(userName),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => _showEhliyetDetails(
                            userId,
                            userName,
                            email,
                            ehliyetOnUrl,
                            ehliyetArkaUrl,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('İncele'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEhliyetDetails(
    String userId,
    String userName,
    String email,
    String ehliyetOnUrl,
    String ehliyetArkaUrl,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
              builder: (context, snap) {
                String displayName = userName;
                String displayEmail = email;
                if (snap.connectionState == ConnectionState.done &&
                    snap.hasData &&
                    snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>;
                  displayName = data['adSoyad'] ?? displayName;
                  displayEmail = data['email'] ?? displayEmail;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName - Ehliyet Onayı',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                );
              },
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ehliyetOnUrl.isNotEmpty) ...[
                      const Text(
                        'Ehliyet Ön Yüz:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap:
                            () => _showFullScreenImage(
                              ehliyetOnUrl,
                              'Ehliyet Ön Yüz',
                            ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ehliyetOnUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (ehliyetArkaUrl.isNotEmpty) ...[
                      const Text(
                        'Ehliyet Arka Yüz:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap:
                            () => _showFullScreenImage(
                              ehliyetArkaUrl,
                              'Ehliyet Arka Yüz',
                            ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ehliyetArkaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => _rejectEhliyet(userId, userName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reddet'),
              ),
              ElevatedButton(
                onPressed: () => _approveEhliyet(userId, userName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Onayla'),
              ),
            ],
          ),
    );
  }

  void _showFullScreenImage(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 64,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _approveEhliyet(String userId, String userName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'ehliyetOnayDurumu': 'onaylandi',
        'ehliyetOnayTarihi': FieldValue.serverTimestamp(),
      });

      // Kullanıcıya bildirim gönder
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Ehliyet Onaylandı',
        'message':
            'Ehliyet bilgileriniz onaylandı. Artık araç kiralayabilirsiniz.',
        'type': 'ehliyet_onaylandi',
        'data': {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName adlı kullanıcının ehliyeti onaylandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectEhliyet(String userId, String userName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'ehliyetOnayDurumu': 'reddedildi',
        'ehliyetOnayTarihi': FieldValue.serverTimestamp(),
        // Eski ehliyet görsellerini kaldır
        'ehliyetOnUrl': FieldValue.delete(),
        'ehliyetArkaUrl': FieldValue.delete(),
      });

      // Kullanıcıya bildirim gönder
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Ehliyet Onaylanmadı',
        'message': 'Ehliyet bilgileriniz onaylanmadı. Lütfen tekrar yükleyin.',
        'type': 'ehliyet_reddedildi',
        'data': {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName adlı kullanıcının ehliyeti reddedildi'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showMessageDetails(
    Map<String, dynamic> message,
    String userId,
    String userName,
    String email,
  ) {
    final createdAt =
        message['createdAt'] != null
            ? (message['createdAt'] as Timestamp).toDate()
            : DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(createdAt);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gönderilme Tarihi: $formattedDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message['message'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _replyToUser(userId, userName, email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cevapla'),
              ),
            ],
          ),
    );
  }

  void _replyToUser(String userId, String userName, String email) {
    final subjectController = TextEditingController(text: 'Destek Cevabı');
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('$userName adlı kullanıcıya cevap'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Konu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Mesaj',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Cevabınızı buraya yazın...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                          'userId': userId,
                          'title': subjectController.text.trim(),
                          'message': messageController.text.trim(),
                          'type': 'support_reply',
                          'data': {
                            'supportMessageId':
                                DateTime.now().millisecondsSinceEpoch,
                          },
                          'read': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$userName adlı kullanıcıya cevap gönderildi',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Gönder'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendNotification(
    String userId,
    String title,
    String message,
    String type, {
    Map<String, dynamic>? data,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildSentNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;

        if (notifications.isEmpty) {
          return const Center(child: Text('Henüz bildirim gönderilmemiş'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification =
                notifications[index].data() as Map<String, dynamic>;
            final userId = notification['userId'] as String?;
            final createdAt = notification['createdAt'] as Timestamp?;
            final formattedDate =
                createdAt != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
                    : 'Tarih yok';

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
              builder: (context, userSnapshot) {
                String recipientName = 'Tüm Kullanıcılar';
                if (userId != null &&
                    userSnapshot.hasData &&
                    userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  recipientName = userData['adSoyad'] ?? 'İsimsiz Kullanıci';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(notification['title'] ?? 'Başlıksız'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message'] ?? 'Mesaj yok'),
                        const SizedBox(height: 4),
                        Text(
                          'Alıcı: $recipientName',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Gönderilme: $formattedDate',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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
    );
  }

  // Keep all other existing methods from the original code...
  Widget _buildCarsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('cars')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final cars = snapshot.data!.docs;

        if (cars.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.car_rental, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Henüz ilan yok',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text('Yeni ilan eklemek için + butonuna tıklayın'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final car = cars[index].data() as Map<String, dynamic>;
            final carId = cars[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildCarImage(car['imageUrl']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car['marka']} ${car['model']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${car['yil']} • ${car['tip']}'),
                          Text('${car['gunlukKira']}₺/gün'),
                          Text('${car['km']} km • ${car['yakitTuru']}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusChip(car),
                              const Spacer(),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editCar(carId, car);
                                      break;
                                    case 'delete':
                                      _deleteCar(carId, car);
                                      break;
                                    case 'toggle':
                                      _toggleCarStatus(carId, car);
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Düzenle'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Row(
                                          children: [
                                            Icon(
                                              car['isActive'] == false
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              car['isActive'] == false
                                                  ? 'Aktif Et'
                                                  : 'Pasif Et',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sil',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCarImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.car_rental, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        return Image.memory(bytes, width: 80, height: 60, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          width: 80,
          height: 60,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        width: 80,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    }
  }

  Widget _buildStatusChip(Map<String, dynamic> car) {
    final isActive = car['isActive'] ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Pasif',
        style: TextStyle(
          color: isActive ? Colors.green[800] : Colors.red[800],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _editCar(String carId, Map<String, dynamic> carData) {
    final TextEditingController markaController = TextEditingController(
      text: carData['marka'] ?? '',
    );
    final TextEditingController modelController = TextEditingController(
      text: carData['model'] ?? '',
    );
    final TextEditingController gunlukKiraController = TextEditingController(
      text: carData['gunlukKira']?.toString() ?? '',
    );
    final TextEditingController kmController = TextEditingController(
      text: carData['km']?.toString() ?? '',
    );
    final TextEditingController yakitTuruController = TextEditingController(
      text: carData['yakitTuru'] ?? '',
    );
    final TextEditingController yakitYuzdeController = TextEditingController(
      text: carData['yakitYuzde']?.toString() ?? '',
    );
    final TextEditingController modelYiliController = TextEditingController(
      text: carData['modelYili']?.toString() ?? '',
    );
    final TextEditingController aracTipiController = TextEditingController(
      text: carData['aracTipi'] ?? '',
    );
    final TextEditingController maxHizController = TextEditingController(
      text: carData['maxHiz']?.toString() ?? '',
    );
    final TextEditingController beygirGucuController = TextEditingController(
      text: carData['beygirGucu']?.toString() ?? '',
    );
    final TextEditingController koltukSayisiController = TextEditingController(
      text: carData['koltukSayisi']?.toString() ?? '',
    );
    final TextEditingController aciklamaController = TextEditingController(
      text: carData['aciklama'] ?? '',
    );

    Map<String, bool> ozellikler = {
      'parkSensoru': carData['parkSensoru'] ?? false,
      'navigasyon': carData['navigasyon'] ?? false,
      'bluetooth': carData['bluetooth'] ?? false,
      'klima': carData['klima'] ?? false,
      'guvenlik': carData['guvenlik'] ?? false,
      'otomatikVites': carData['otomatikVites'] ?? false,
      'sunroof': carData['sunroof'] ?? false,
      'deriKoltuk': carData['deriKoltuk'] ?? false,
    };

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Araç Düzenle'),
            contentPadding: const EdgeInsets.all(20),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Temel Bilgiler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: markaController,
                            decoration: const InputDecoration(
                              labelText: 'Marka',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Fiyat ve Teknik Bilgiler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: gunlukKiraController,
                            decoration: const InputDecoration(
                              labelText: 'Günlük Kira',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: kmController,
                            decoration: const InputDecoration(
                              labelText: 'Kilometre',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yakitTuruController,
                      decoration: const InputDecoration(
                        labelText: 'Yakıt Türü',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yakitYuzdeController,
                            decoration: const InputDecoration(
                              labelText: 'Yakıt Yüzdesi',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: modelYiliController,
                            decoration: const InputDecoration(
                              labelText: 'Model Yılı',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aracTipiController,
                      decoration: const InputDecoration(
                        labelText: 'Araç Tipi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Performans Bilgileri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: maxHizController,
                            decoration: const InputDecoration(
                              labelText: 'Max Hız (km/h)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: beygirGucuController,
                            decoration: const InputDecoration(
                              labelText: 'Beygir Gücü',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: koltukSayisiController,
                      decoration: const InputDecoration(
                        labelText: 'Koltuk Sayısı',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Araç Özellikleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _buildCheckboxTile(
                          'Park Sensörü',
                          'parkSensoru',
                          ozellikler,
                        ),
                        _buildCheckboxTile(
                          'Navigasyon',
                          'navigasyon',
                          ozellikler,
                        ),
                        _buildCheckboxTile(
                          'Bluetooth',
                          'bluetooth',
                          ozellikler,
                        ),
                        _buildCheckboxTile('Klima', 'klima', ozellikler),
                        _buildCheckboxTile('Güvenlik', 'guvenlik', ozellikler),
                        _buildCheckboxTile(
                          'Otomatik Vites',
                          'otomatikVites',
                          ozellikler,
                        ),
                        _buildCheckboxTile('Sunroof', 'sunroof', ozellikler),
                        _buildCheckboxTile(
                          'Deri Koltuk',
                          'deriKoltuk',
                          ozellikler,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Araç hakkında detaylı bilgi...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    Map<String, dynamic> updateData = {
                      'marka': markaController.text.trim(),
                      'model': modelController.text.trim(),
                      'yakitTuru': yakitTuruController.text.trim(),
                      'aracTipi': aracTipiController.text.trim(),
                      'aciklama': aciklamaController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (gunlukKiraController.text.trim().isNotEmpty) {
                      updateData['gunlukKira'] =
                          int.tryParse(gunlukKiraController.text.trim()) ?? 0;
                    }
                    if (kmController.text.trim().isNotEmpty) {
                      updateData['km'] =
                          int.tryParse(kmController.text.trim()) ?? 0;
                    }
                    if (yakitYuzdeController.text.trim().isNotEmpty) {
                      updateData['yakitYuzde'] =
                          int.tryParse(yakitYuzdeController.text.trim()) ?? 0;
                    }
                    if (modelYiliController.text.trim().isNotEmpty) {
                      updateData['modelYili'] =
                          int.tryParse(modelYiliController.text.trim()) ?? 0;
                    }
                    if (maxHizController.text.trim().isNotEmpty) {
                      updateData['maxHiz'] =
                          int.tryParse(maxHizController.text.trim()) ?? 0;
                    }
                    if (beygirGucuController.text.trim().isNotEmpty) {
                      updateData['beygirGucu'] =
                          int.tryParse(beygirGucuController.text.trim()) ?? 0;
                    }
                    if (koltukSayisiController.text.trim().isNotEmpty) {
                      updateData['koltukSayisi'] =
                          int.tryParse(koltukSayisiController.text.trim()) ?? 0;
                    }

                    updateData.addAll(ozellikler);

                    await FirebaseFirestore.instance
                        .collection('cars')
                        .doc(carId)
                        .update(updateData);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Araç başarıyla güncellendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    String key,
    Map<String, bool> ozellikler,
  ) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 12)),
        value: ozellikler[key],
        onChanged: (value) {
          setState(() {
            ozellikler[key] = value ?? false;
          });
        },
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _deleteCar(String carId, Map<String, dynamic> carData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('İlanı Sil'),
            content: Text(
              '${carData['marka']} ${carData['model']} ilanını silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('cars')
                        .doc(carId)
                        .delete();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İlan başarıyla silindi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _toggleCarStatus(String carId, Map<String, dynamic> carData) async {
    final currentStatus = carData['isActive'] ?? true;
    try {
      await FirebaseFirestore.instance.collection('cars').doc(carId).update({
        'isActive': !currentStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus ? 'İlan pasif edildi' : 'İlan aktif edildi',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRentalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('rentals')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, rentalSnap) {
        if (!rentalSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rentals = rentalSnap.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = {
              for (var u in userSnap.data!.docs)
                u.id: u.data() as Map<String, dynamic>,
            };

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rentals.length,
              itemBuilder: (context, i) {
                final rental = rentals[i].data() as Map<String, dynamic>;
                final rentalId = rentals[i].id;
                final userId = rental['userId'] ?? '';
                final user = users[userId];
                final userName =
                    user != null
                        ? (user['adSoyad'] ?? user['email'] ?? userId)
                        : userId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rental['carName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildRentalStatusChip(rental['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRentalInfo('Kiralayan', userName),
                        if (rental['startDate'] != null &&
                            rental['endDate'] != null)
                          _buildRentalInfo(
                            'Tarih',
                            '${_formatDate(rental['startDate'])} - ${_formatDate(rental['endDate'])}',
                          ),
                        if (rental['guvencePaketi'] != null &&
                            rental['guvencePaketi'] != '-')
                          _buildRentalInfo('Güvence', rental['guvencePaketi']),
                        if (rental['toplamFiyat'] != null)
                          _buildRentalInfo(
                            'Fiyat',
                            '${rental['toplamFiyat']}₺',
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (rental['status'] != 'cancelled')
                              ElevatedButton.icon(
                                onPressed:
                                    () => _cancelRental(rentalId, rental),
                                icon: const Icon(Icons.cancel, size: 16),
                                label: const Text('İptal Et'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () => _showRentalDetails(rental, userName),
                              icon: const Icon(Icons.info, size: 16),
                              label: const Text('Detay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C3E50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
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
    );
  }

  Widget _buildRentalInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildRentalStatusChip(String? status) {
    final rentalStatus = status ?? 'active';
    Color color;
    String text;

    switch (rentalStatus) {
      case 'cancelled':
        color = Colors.red;
        text = 'İptal';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      default:
        color = Colors.blue;
        text = 'Aktif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  void _cancelRental(String rentalId, Map<String, dynamic> rental) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kiralama İptali'),
            content: Text(
              '${rental['carName']} kiralamasını iptal etmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('rentals')
                        .doc(rentalId)
                        .update({
                          'status': 'cancelled',
                          'cancelledAt': FieldValue.serverTimestamp(),
                          'cancelledBy': 'admin',
                        });

                    final userId = rental['userId'];
                    if (userId != null) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .add({
                            'userId': userId,
                            'title': 'Kiralama İptal Edildi',
                            'message':
                                '${rental['carName']} kiralamanız admin tarafından iptal edildi.',
                            'type': 'cancelled_rental',
                            'data': {
                              'rentalId': rentalId,
                              'carName': rental['carName'],
                            },
                            'read': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kiralama başarıyla iptal edildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Evet', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showRentalDetails(Map<String, dynamic> rental, String userName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(rental['carName'] ?? 'Kiralama Detayı'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Kiralayan', userName),
                  _buildDetailRow('Araç', rental['carName'] ?? ''),
                  if (rental['startDate'] != null)
                    _buildDetailRow(
                      'Başlangıç',
                      _formatDate(rental['startDate']),
                    ),
                  if (rental['endDate'] != null)
                    _buildDetailRow('Bitiş', _formatDate(rental['endDate'])),
                  if (rental['guvencePaketi'] != null)
                    _buildDetailRow('Güvence', rental['guvencePaketi']),
                  if (rental['toplamFiyat'] != null)
                    _buildDetailRow(
                      'Toplam Fiyat',
                      '${rental['toplamFiyat']}₺',
                    ),
                  _buildDetailRow('Durum', rental['status'] ?? 'active'),
                  if (rental['paymentStatus'] != null)
                    _buildDetailRow('Ödeme', rental['paymentStatus']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = userSnap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final user = users[i].data() as Map<String, dynamic>;
            final userId = users[i].id;
            final userName = user['adSoyad'] ?? user['email'] ?? userId;
            final userEmail = user['email'] ?? '';
            final rol = user['rol'] ?? 'user';
            return ListTile(
              leading: Icon(
                rol == 'admin' ? Icons.admin_panel_settings : Icons.person,
                color: rol == 'admin' ? Colors.red : Colors.blue,
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(userEmail),
              // trailing: Text(rol, ... ) kaldırıldı, sadece Row ile olan trailing bırakıldı
              onTap: () {
                // Kiralama geçmişi eskisi gibi açılır
                _showUserRentals(context, userId, userName);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final rentalsSnap =
                          await FirebaseFirestore.instance
                              .collection('rentals')
                              .where('userId', isEqualTo: userId)
                              .orderBy('createdAt', descending: true)
                              .limit(1)
                              .get();
                      String phone = user['telefon'] ?? '';
                      String address = '';
                      if (rentalsSnap.docs.isNotEmpty) {
                        final rental = rentalsSnap.docs.first.data();
                        if (phone.isEmpty && rental['phone'] != null) {
                          phone = rental['phone'];
                        }
                        address = rental['address'] ?? '';
                      }
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (ctx) => Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'İletişim Bilgileri',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('E-posta: $userEmail'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Telefon: ${phone.isNotEmpty ? phone : 'Yok'}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Adres: ${address.isNotEmpty ? address : 'Yok'}',
                                  ),
                                  const SizedBox(height: 16),
                                  if ((user['ehliyetOnUrl'] ?? '').isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ehliyet Ön:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Image.network(
                                          user['ehliyetOnUrl'],
                                          height: 120,
                                        ),
                                      ],
                                    ),
                                  if ((user['ehliyetArkaUrl'] ?? '').isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ehliyet Arka:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Image.network(
                                          user['ehliyetArkaUrl'],
                                          height: 120,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                      );
                    },
                    child: const Text('İletişim Bilgileri'),
                  ),
                ],
              ),
              // ...existing code...
            );
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cars').snapshots(),
      builder: (context, carsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
          builder: (context, rentalsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (!carsSnapshot.hasData ||
                    !rentalsSnapshot.hasData ||
                    !usersSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalCars = carsSnapshot.data!.docs.length;
                final activeCars =
                    carsSnapshot.data!.docs
                        .where(
                          (doc) => (doc.data() as Map)['isActive'] != false,
                        )
                        .length;
                final totalRentals = rentalsSnapshot.data!.docs.length;
                final activeRentals =
                    rentalsSnapshot.data!.docs
                        .where(
                          (doc) => (doc.data() as Map)['status'] != 'cancelled',
                        )
                        .length;
                final totalUsers = usersSnapshot.data!.docs.length;

                double totalRevenue = 0;
                for (var rental in rentalsSnapshot.data!.docs) {
                  final data = rental.data() as Map<String, dynamic>;
                  if (data['status'] != 'cancelled' &&
                      data['toplamFiyat'] != null) {
                    totalRevenue += (data['toplamFiyat'] as num).toDouble();
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: const Color(0xFF2C3E50)),
                          const SizedBox(width: 8),
                          const Text(
                            'Genel İstatistikler',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatCard(
                            'Toplam Araç',
                            totalCars.toString(),
                            Icons.car_rental,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Aktif Araç',
                            activeCars.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Toplam Kiralama',
                            totalRentals.toString(),
                            Icons.assignment,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Aktif Kiralama',
                            activeRentals.toString(),
                            Icons.trending_up,
                            Colors.purple,
                          ),
                          _buildStatCard(
                            'Toplam Kullanıcı',
                            totalUsers.toString(),
                            Icons.people,
                            Colors.indigo,
                          ),
                          _buildStatCard(
                            'Toplam Gelir',
                            '${totalRevenue.toStringAsFixed(0)}₺',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserRentals(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$userName - Kiralamalar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('rentals')
                              .where('userId', isEqualTo: userId)
                              .snapshots(),
                      builder: (context, rentalSnap) {
                        if (!rentalSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final rentals = rentalSnap.data!.docs;
                        if (rentals.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Bu kullanıcının kiralaması yok.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: rentals.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final rental =
                                rentals[i].data() as Map<String, dynamic>;
                            final carName = rental['carName'] ?? '';
                            final guvence = rental['guvencePaketi'] ?? '-';
                            final price =
                                rental['toplamFiyat'] ?? rental['price'] ?? '';
                            final paymentStatus =
                                rental['paymentStatus'] ?? 'Başarılı';
                            final startDate =
                                rental['startDate'] != null
                                    ? (rental['startDate'] as Timestamp)
                                        .toDate()
                                    : null;
                            final endDate =
                                rental['endDate'] != null
                                    ? (rental['endDate'] as Timestamp).toDate()
                                    : null;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions_car,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            carName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        _buildRentalStatusChip(
                                          rental['status'],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (startDate != null && endDate != null)
                                      _buildDetailRow(
                                        'Tarih',
                                        '${startDate.day}.${startDate.month}.${startDate.year} - ${endDate.day}.${endDate.month}.${endDate.year}',
                                      ),
                                    if (guvence != '-')
                                      _buildDetailRow('Güvence', guvence),
                                    if (price != null &&
                                        price.toString().isNotEmpty)
                                      _buildDetailRow('Fiyat', '$price₺'),
                                    _buildDetailRow(
                                      'Ödeme Durumu',
                                      paymentStatus,
                                    ),
                                  ],
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
            );
          },
        );
      },
    );
  }
}

class DashboardTab {
  final IconData icon;
  final String label;
  final int index;

  DashboardTab(this.icon, this.label, this.index);
}
