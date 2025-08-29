import 'package:flutter/material.dart';
import '../models/car.dart';
import 'package:rentcar/screens/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class RentCarScreen extends StatefulWidget {
  final Car car;
  const RentCarScreen({super.key, required this.car});

  @override
  State<RentCarScreen> createState() => _RentCarScreenState();
}

class _RentCarScreenState extends State<RentCarScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final bool _isLoading = false;
  String? _error;

  // Güvence paketleri
  final List<Map<String, dynamic>> _guvencePaketleri = [
    {
      'ad': 'Standart',
      'fiyat': 0,
      'aciklama': 'Temel koruma',
      'icon': Icons.shield_outlined,
    },
    {
      'ad': 'Genişletilmiş',
      'fiyat': 200,
      'aciklama': 'Gelişmiş koruma + Yol yardımı',
      'icon': Icons.security,
    },
    {
      'ad': 'Premium',
      'fiyat': 400,
      'aciklama': 'Tam koruma + Ücretsiz iptal',
      'icon': Icons.verified_user,
    },
  ];
  int _secilenGuvence = 0;

  List<DateTime> _doluGunler = [];
  List<DateTime> _iptalGunler = []; // İptal edilen günler için liste

  final List<String> subeler = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Malatya',
    'Trabzon',
  ];
  String? teslimSube;
  String? birakmaSube;

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
  }

  Future<void> _loadReservedDates() async {
    final rentals =
        await FirebaseFirestore.instance
            .collection('rentals')
            .where('carId', isEqualTo: widget.car.id)
            .get();
    List<DateTime> reserved = [];
    List<DateTime> cancelled = [];
    for (var doc in rentals.docs) {
      final data = doc.data();
      final status = data['status'];
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      for (
        var d = start;
        d.isBefore(end.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        if (status == 'cancelled') {
          cancelled.add(d);
        } else {
          reserved.add(d);
        }
      }
    }
    setState(() {
      _doluGunler = reserved; // Takvimde disable edilecek günler
      _iptalGunler = cancelled; // Takvimde gösterilecek ama seçilebilir günler
    });
  }

  bool _isDayReserved(DateTime day) {
    return _doluGunler.contains(DateTime(day.year, day.month, day.day));
  }

  int get _gunSayisi {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  double get _toplamFiyat {
    final gunlukFiyat = widget.car.pricePerDay;
    final guvenceFiyat = _guvencePaketleri[_secilenGuvence]['fiyat'] as int;
    return (gunlukFiyat + guvenceFiyat) * (_gunSayisi > 0 ? _gunSayisi : 1);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
      helpText: isStart ? 'Başlangıç Tarihi Seç' : 'Bitiş Tarihi Seç',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<bool> _isCarAvailable(DateTime start, DateTime end) async {
    final rentals =
        await FirebaseFirestore.instance
            .collection('rentals')
            .where('carId', isEqualTo: widget.car.id)
            .get();
    for (var doc in rentals.docs) {
      final data = doc.data();
      final status = data['status'];
      if (status == 'cancelled') continue; // İptal edilenler dolu sayılmasın
      final dbStart = (data['startDate'] as Timestamp).toDate();
      final dbEnd = (data['endDate'] as Timestamp).toDate();
      // Seçilen aralık ile çakışma kontrolü
      if (!(end.isBefore(dbStart) || start.isAfter(dbEnd))) {
        return false;
      }
    }
    return true;
  }

  void _devamEt() async {
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Lütfen başlangıç ve bitiş tarihi seçin.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'Bitiş tarihi başlangıçtan önce olamaz.');
      return;
    }
    setState(() {
      _error = null;
    });
    // Müsaitlik kontrolü
    final available = await _isCarAvailable(_startDate!, _endDate!);
    if (!available) {
      setState(
        () =>
            _error =
                'Seçilen tarihlerde araç zaten rezerve edilmiş. Lütfen başka tarih seçin.',
      );
      return;
    }
    // PaymentScreen'e teslim ve bırakma şubesi de parametre olarak gönderilmeli
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => PaymentScreen(
              car: widget.car,
              startDate: _startDate!,
              endDate: _endDate!,
              guvencePaketi: _guvencePaketleri[_secilenGuvence]['ad'],
              toplamFiyat: _toplamFiyat,
              teslimSube: teslimSube,
              birakmaSube: birakmaSube,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Aracı Kirala',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Araç Bilgi Kartı
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.car.imageUrl,
                          height: 100,
                          width: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.car.name} ${widget.car.model}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.car.pricePerDay.toStringAsFixed(0)}₺/gün',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tarih Seçimi Kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Kiralama Tarihleri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _startDate ?? DateTime.now(),
                      selectedDayPredicate: (day) {
                        if (_startDate != null && _endDate != null) {
                          return !day.isBefore(_startDate!) &&
                              !day.isAfter(_endDate!);
                        } else if (_startDate != null && _endDate == null) {
                          return day.year == _startDate!.year &&
                              day.month == _startDate!.month &&
                              day.day == _startDate!.day;
                        }
                        return false;
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        if (_isDayReserved(selectedDay)) return;
                        setState(() {
                          if (_startDate == null ||
                              (_startDate != null && _endDate != null)) {
                            _startDate = selectedDay;
                            _endDate = null;
                          } else if (_startDate != null &&
                              _endDate == null &&
                              !selectedDay.isBefore(_startDate!)) {
                            _endDate = selectedDay;
                          }
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, date, _) {
                          if (_iptalGunler.any(
                            (d) =>
                                d.year == date.year &&
                                d.month == date.month &&
                                d.day == date.day,
                          )) {
                            // İptal edilen günler silik/farklı renkte gösterilsin
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            );
                          }
                          return null; // Diğer günler varsayılan şekilde
                        },
                        disabledBuilder: (context, date, _) {
                          // Dolu günler (status yok veya confirmed) disable
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          );
                        },
                      ),
                      enabledDayPredicate: (date) {
                        // Sadece dolu günler seçilemez, iptal edilenler seçilebilir
                        return !_doluGunler.any(
                          (d) =>
                              d.year == date.year &&
                              d.month == date.month &&
                              d.day == date.day,
                        );
                      },
                      calendarStyle: CalendarStyle(
                        disabledTextStyle: const TextStyle(color: Colors.red),
                        rangeHighlightColor: Colors.blue.shade100,
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      rangeSelectionMode: RangeSelectionMode.toggledOn,
                      headerVisible: true,
                      daysOfWeekVisible: true,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Ay',
                      }, // Format butonunu kaldır
                      onFormatChanged:
                          (_) {}, // Format değişimini devre dışı bırak
                    ),
                    if (_gunSayisi > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 20,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Toplam kiralama süresi: $_gunSayisi gün',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Güvence Paketi Kartı
            if (_gunSayisi > 0) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.orange.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Güvence Paketi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._guvencePaketleri.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final paket = entry.value;
                        final isSelected = _secilenGuvence == idx;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                isSelected
                                    ? Colors.blue.shade50
                                    : Colors.transparent,
                          ),
                          child: RadioListTile<int>(
                            value: idx,
                            groupValue: _secilenGuvence,
                            onChanged:
                                (val) => setState(() => _secilenGuvence = val!),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  paket['icon'] as IconData,
                                  color:
                                      isSelected
                                          ? Colors.blue.shade600
                                          : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paket['ad'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? Colors.blue.shade700
                                            : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  paket['fiyat'] == 0
                                      ? 'Ücretsiz'
                                      : '+${paket['fiyat']}₺/gün',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        paket['fiyat'] == 0
                                            ? Colors.green.shade600
                                            : Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              paket['aciklama'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: Colors.blue.shade600,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Fiyat Özeti Kartı
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Toplam Tutar:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_toplamFiyat.toStringAsFixed(0)}₺',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Şube Seçimi Kartı
            if (_gunSayisi > 0) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Şube Seçimi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Teslim Alınacak Şube',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: teslimSube,
                        items:
                            subeler
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => teslimSube = v),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bırakılacak Şube',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: birakmaSube,
                        items:
                            subeler
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => birakmaSube = v),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Hata Mesajı
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Devam Et Butonu
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _devamEt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Ödeme Sayfasına Geç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.shade50 : Colors.white,
          foregroundColor:
              isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
