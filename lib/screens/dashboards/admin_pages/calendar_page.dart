import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  // --- YENİ: Salt Okunur Parametresi ---
  // Eğer true ise, düzenleme/silme butonları gizlenir.
  // Varsayılan değeri 'false' (yani admin modu).
  final bool isReadOnly;

  const CalendarPage({
    super.key,
    this.isReadOnly = false,
  });
  // -------------------------------------

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();

  String? _selectedCompanyId;
  List<QueryDocumentSnapshot> _companies = [];

  List<QueryDocumentSnapshot> _schedulesForMonth = [];
  bool _isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _fetchSchedulesForMonth();
  }

  Future<void> _fetchCompanies() async {
    final snapshot = await FirebaseFirestore.instance.collection('companies').orderBy('name').get();
    if (mounted) {
      setState(() {
        _companies = snapshot.docs;
      });
    }
  }

  Future<void> _fetchSchedulesForMonth() async {
    setState(() => _isLoadingSchedules = true);

    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

    try {
      Query query = FirebaseFirestore.instance
          .collection('schedules')
          .where('date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));

      if (_selectedCompanyId != null) {
        query = query.where('company_id', isEqualTo: _selectedCompanyId);
      }

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _schedulesForMonth = snapshot.docs;
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      debugPrint("Takvim verisi hatası: $e");
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  List<QueryDocumentSnapshot> _getSchedulesForDay(DateTime day) {
    return _schedulesForMonth.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['date_time'] == null) return false;
      DateTime scheduleDate = (data['date_time'] as Timestamp).toDate();
      return scheduleDate.year == day.year && scheduleDate.month == day.month && scheduleDate.day == day.day;
    }).toList();
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + increment);
    });
    _fetchSchedulesForMonth();
  }

  Future<void> _deleteSchedule(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('schedules').doc(docId).delete();
      if (mounted) {
        Navigator.pop(context);
        _fetchSchedulesForMonth();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çekim silindi.")));
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final int firstWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;
    final int emptySlots = firstWeekday - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(
                DateFormat('MMMM yyyy', 'tr_TR').format(_focusedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),

              const Spacer(),

              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  hint: const Text('Tüm Firmalar'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text("Tüm Firmalar")),
                    ..._companies.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text((doc.data() as Map<String, dynamic>)['name'] ?? 'İsimsiz'),
                      );
                    })
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCompanyId = val);
                    _fetchSchedulesForMonth();
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        _isLoadingSchedules
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                      .map((d) => Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
                      .toList(),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: daysInMonth + emptySlots,
                  itemBuilder: (context, index) {
                    if (index < emptySlots) return const SizedBox();

                    final int day = index - emptySlots + 1;
                    final DateTime date = DateTime(_focusedDay.year, _focusedDay.month, day);
                    final List<QueryDocumentSnapshot> daySchedules = _getSchedulesForDay(date);
                    final bool isToday = DateUtils.isSameDay(date, DateTime.now());

                    return InkWell(
                      onTap: daySchedules.isEmpty ? null : () {
                        _showDaySchedulesDialog(context, date, daySchedules);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday ? Colors.indigo.withOpacity(0.3) : Colors.grey[900],
                          border: Border.all(color: Colors.grey[800]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                "$day",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.indigoAccent : Colors.white
                                )
                            ),
                            if (daySchedules.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${daySchedules.length}",
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDaySchedulesDialog(BuildContext context, DateTime date, List<QueryDocumentSnapshot> schedules) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${DateFormat('dd MMMM yyyy', 'tr_TR').format(date)} Çekimleri"),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final data = schedules[index].data() as Map<String, dynamic>;
                final String companyName = data['company_name'] ?? 'Firma Yok';
                final String timeStr = DateFormat('HH:mm').format((data['date_time'] as Timestamp).toDate());
                final String notes = data['notes'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.redAccent),
                    title: Text("$timeStr - $companyName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notes),

                    // --- DÜZELTME BURADA ---
                    // Eğer salt okunur moddaysa (widget.isReadOnly == true),
                    // 'trailing' (sondaki buton) kısmını 'null' yap (gösterme).
                    // Değilse, 'Sil' butonunu göster.
                    trailing: widget.isReadOnly
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        _deleteSchedule(schedules[index].id);
                      },
                    ),
                    // -----------------------
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          ],
        );
      },
    );
  }
}