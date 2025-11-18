import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Listeler
  List<QueryDocumentSnapshot> _employees = [];
  List<QueryDocumentSnapshot> _companies = []; // --- YENİ: Firma Listesi ---

  // Yüklenme durumları
  bool _isLoadingData = true;
  bool _isCreatingTask = false;

  // Seçimler
  String? _selectedEmployeeId;
  String? _selectedCompanyId; // --- YENİ: Seçilen Firma ID'si ---

  @override
  void initState() {
    super.initState();
    // Hem çalışanları hem firmaları çek
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Paralel olarak (aynı anda) her iki koleksiyonu da çekiyoruz
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'employee')
            .get(),
        FirebaseFirestore.instance.collection('companies').orderBy('name').get(),
      ]);

      if (mounted) {
        setState(() {
          _employees = results[0].docs;
          _companies = results[1].docs; // Firmalar ikinci sonuçta
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Veriler getirilirken hata: $e");
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreatingTask = true;
      });

      try {
        final String? adminId = FirebaseAuth.instance.currentUser?.uid;
        if (adminId == null) throw Exception('Admin kimliği bulunamadı.');

        await FirebaseFirestore.instance.collection('tasks').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'assignedTo': _selectedEmployeeId,
          'companyId': _selectedCompanyId, // --- YENİ: Firmayı kaydet ---
          'createdBy': adminId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni görev başarıyla oluşturuldu.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Görev oluşturulurken hata: $e");
        if (mounted) {
          setState(() {
            _isCreatingTask = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Görev Oluştur'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5, // Biraz daha geniş
        child: _isLoadingData
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Veriler yükleniyor...'),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Görev Başlığı',
                    icon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir başlık girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- YENİ: Firma Seçimi ---
                DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  hint: const Text('Firma Seçin'),
                  icon: const Icon(Icons.business),
                  isExpanded: true,
                  items: _companies.map((doc) {
                    final company = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(company['name'] ?? 'İsimsiz'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCompanyId = val),
                  validator: (value) {
                    if (value == null) return 'Lütfen bir firma seçin.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Çalışan Seçimi
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  hint: const Text('Çalışan Seçin'),
                  icon: const Icon(Icons.person_search),
                  isExpanded: true,
                  items: _employees.map((doc) {
                    final user = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(user['name'] ?? user['email'] ?? 'İsimsiz'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedEmployeeId = val),
                  validator: (value) {
                    if (value == null) return 'Lütfen bir çalışan seçin.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    icon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreatingTask ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isCreatingTask ? null : _createTask,
          child: _isCreatingTask
              ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Oluştur'),
        ),
      ],
    );
  }
}