import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cars_screen.dart';
import 'package:intl/intl.dart';

class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  String _getRentalStatus(
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic> rental,
  ) {
    // Admin tarafından iptal edilmiş mi kontrol et
    final status = rental['status'] as String?;
    if (status == 'cancelled') {
      return 'İptal Edildi';
    }

    // Mevcut mantık
    if (startDate == null) return 'Belirsiz';
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      final diff = startDate.difference(now);
      return '${diff.inDays} gün kaldı';
    } else if (endDate != null && now.isBefore(endDate)) {
      return 'Devam ediyor';
    } else {
      return 'Tamamlandı';
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'İptal Edildi') return Colors.red;
    if (status.contains('kaldı')) return const Color(0xFF7B68EE);
    if (status == 'Devam ediyor') return Colors.green;
    if (status == 'Tamamlandı') return Colors.grey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapmalısınız.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B68EE), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kiralıklarım',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mevcut ve geçmiş kiralamaların',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('rentals')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B68EE),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bir hata oluştu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final rentals = snapshot.data?.docs ?? [];

                  // Tarihe göre sıralama
                  rentals.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aCreated = aData['createdAt'];
                    final bCreated = bData['createdAt'];
                    if (aCreated == null && bCreated == null) return 0;
                    if (aCreated == null) return 1;
                    if (bCreated == null) return -1;
                    return (bCreated as Timestamp).compareTo(
                      aCreated as Timestamp,
                    );
                  });

                  if (rentals.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_car_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Henüz kiraladığınız araç yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Araçları keşfetmeye başla ve ilk aracını kirala!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CarsScreen(cars: []),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B68EE),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Araçları Keşfet',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rentals.length,
                    itemBuilder: (context, index) {
                      final rental =
                          rentals[index].data() as Map<String, dynamic>;
                      final carName = rental['carName'] ?? '';
                      final carImage = rental['carImage'] ?? '';
                      final startDate =
                          rental['startDate'] != null
                              ? (rental['startDate'] as Timestamp).toDate()
                              : null;
                      final endDate =
                          rental['endDate'] != null
                              ? (rental['endDate'] as Timestamp).toDate()
                              : null;
                      final price =
                          rental['toplamFiyat'] ?? rental['price'] ?? '';
                      final guvence = rental['guvencePaketi'] ?? 'Standart';

                      final status = _getRentalStatus(
                        startDate,
                        endDate,
                        rental,
                      );
                      final statusColor = _getStatusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Araç Resmi
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            carImage.isNotEmpty
                                                ? Image.network(
                                                  carImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Icon(
                                                      Icons.directions_car,
                                                      size: 40,
                                                      color:
                                                          Colors.grey.shade400,
                                                    );
                                                  },
                                                )
                                                : Icon(
                                                  Icons.directions_car,
                                                  size: 40,
                                                  color: Colors.grey.shade400,
                                                ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Araç Bilgileri
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  carName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Favori İkonu
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          // Durum
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Fiyat
                                          if (price != null &&
                                              price.toString().isNotEmpty)
                                            Text(
                                              '$price₺ / günde',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF7B68EE),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                if (startDate != null && endDate != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Başlangıç',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat(
                                                  'dd\nMMM',
                                                ).format(startDate),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 40,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              1,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Bitiş',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat(
                                                  'dd\nMMM',
                                                ).format(endDate),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Şube bilgileri
                                if ((rental['teslimSube'] ?? '')
                                        .toString()
                                        .isNotEmpty ||
                                    (rental['birakmaSube'] ?? '')
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if ((rental['teslimSube'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Teslim Şubesi',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                rental['teslimSube'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if ((rental['birakmaSube'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Bırakma Şubesi',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                rental['birakmaSube'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],

                                // Araç İptali butonu
                                if (status != 'İptal Edildi') ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        final uid = user?.uid;
                                        if (uid == null) return;
                                        final userDoc =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(uid)
                                                .get();
                                        final adSoyad =
                                            userDoc.data()?['adSoyad'] ??
                                            'İsimsiz';
                                        final email = user?.email ?? '';
                                        final dateFormat = DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                        );
                                        final startStr =
                                            startDate != null
                                                ? dateFormat.format(startDate)
                                                : '-';
                                        final endStr =
                                            endDate != null
                                                ? dateFormat.format(endDate)
                                                : '-';
                                        final detayliMesaj =
                                            'Kullanıcı $adSoyad ($email), $startStr tarihinde kiraladığı $carName aracını $startStr - $endStr aralığında iptal etmek istiyor.\n'
                                            'Kiralama fiyatı: $price₺\n'
                                            'Güvence paketi: $guvence';
                                        await FirebaseFirestore.instance
                                            .collection('support_messages')
                                            .add({
                                              'userId': uid,
                                              'adSoyad': adSoyad,
                                              'email': email,
                                              'message': detayliMesaj,
                                              'subject': 'Araç İptali',
                                              'rentalId':
                                                  rental['rentalId'] ?? '',
                                              'carName': carName,
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Yetkili sizinle en yakın zamanda iletişime geçecek.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Araç İptali'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
    );
  }
}
