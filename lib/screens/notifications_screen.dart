// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // DateFormat için ekledim

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const Center(child: Text('Giriş yapmalısınız.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFF7B68EE),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // Hata kontrolü ekledim
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  Text('Hata: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }

          // Veri yükleniyor kontrolü
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz bildirim yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final title = notification['title'] ?? '';
              final message = notification['message'] ?? '';
              final read = notification['read'] ?? false;
              final createdAt =
                  notification['createdAt'] != null
                      ? (notification['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

              return Dismissible(
                key: Key(notifications[index].id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildirim silindi')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  color: read ? Colors.white : Colors.grey.shade50,
                  child: InkWell(
                    onTap: () async {
                      // Bildirimi okundu olarak işaretle
                      if (!read) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(notifications[index].id)
                            .update({'read': true});
                      }

                      // Bildirim türüne göre yönlendirme yap
                      final type = notification['type'] ?? '';
                      if (type == 'cancelled_rental') {
                        // İptal edilen kiralama bildirimi
                        final rentalId =
                            notification['data']?['rentalId'] ?? '';
                        // İsterseniz burada kiralama detay ekranına yönlendirme yapabilirsiniz
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: read ? Colors.black : Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(createdAt), // this ekledim
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: TextStyle(
                              color: read ? Colors.grey : Colors.black87,
                            ),
                          ),
                          if (!read)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      // Daha net tarih formatı
      return DateFormat('dd MMM').format(date);
    }
  }
}
