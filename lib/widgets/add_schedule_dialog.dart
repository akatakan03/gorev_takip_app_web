import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatı için

class AddScheduleDialog extends StatefulWidget {
  const AddScheduleDialog({super.key});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  // Firma listesi ve seçimi
  List<QueryDocumentSnapshot> _companies = [];
  bool _isLoadingData = true;
  String? _selectedCompanyId;
  String? _selectedCompanyName; // Firma adını da kaydedeceğiz (kolaylık olsun diye)

  // Tarih ve Saat
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  // Firmaları çek
  Future<void> _fetchCompanies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('name')
          .get();

      if (mounted) {
        setState(() {
          _companies = snapshot.docs;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Firma yükleme hatası: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // Tarih Seçici
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Saat Seçici
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Kayıt İşlemi
  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tarih ve saat seçin.'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      setState(() => _isSaving = true);

      // Tarih ve saati birleştir
      final DateTime scheduleDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      try {
        // 'schedules' koleksiyonuna ekle
        await FirebaseFirestore.instance.collection('schedules').add({
          'company_id': _selectedCompanyId,
          'company_name': _selectedCompanyName,
          'date_time': Timestamp.fromDate(scheduleDateTime),
          'notes': _notesController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Çekim takvime eklendi.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        debugPrint("Kayıt hatası: $e");
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Çekim Planla'),
      content: SizedBox(
        width: 400, // Genişlik
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Firma Seçimi
                DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  hint: const Text('Firma Seçin'),
                  icon: const Icon(Icons.business),
                  isExpanded: true,
                  items: _companies.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'İsimsiz';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(name),
                      onTap: () {
                        // Seçilen firmanın ismini de sakla
                        _selectedCompanyName = name;
                      },
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCompanyId = val),
                  validator: (val) => val == null ? 'Lütfen firma seçin.' : null,
                ),
                const SizedBox(height: 16),

                // Tarih ve Saat Butonları
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDate == null
                            ? 'Tarih'
                            : DateFormat('dd.MM.yyyy').format(_selectedDate!)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime == null
                            ? 'Saat'
                            : _selectedTime!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notlar
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (Örn: Drone çekimi)',
                    icon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                  validator: (val) => val!.isEmpty ? 'Lütfen bir not girin.' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSchedule,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}