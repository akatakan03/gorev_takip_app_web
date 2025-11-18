import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditTaskDialog extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> currentTaskData;

  const EditTaskDialog({
    super.key,
    required this.taskId,
    required this.currentTaskData,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  List<QueryDocumentSnapshot> _employees = [];
  List<QueryDocumentSnapshot> _companies = []; // --- YENİ ---

  bool _isLoadingData = true;
  String? _selectedEmployeeId;
  String? _selectedCompanyId; // --- YENİ ---
  bool _isUpdatingTask = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTaskData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.currentTaskData['description'] ?? '');
    _selectedEmployeeId = widget.currentTaskData['assignedTo'];
    _selectedCompanyId = widget.currentTaskData['companyId']; // --- YENİ: Mevcut firmayı al ---

    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'employee').get(),
        FirebaseFirestore.instance.collection('companies').orderBy('name').get(),
      ]);

      if (mounted) {
        setState(() {
          _employees = results[0].docs;
          _companies = results[1].docs;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Veri hatası: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdatingTask = true);

      try {
        await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'assignedTo': _selectedEmployeeId,
          'companyId': _selectedCompanyId, // --- YENİ: Firmayı güncelle ---
        });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görev güncellendi.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        debugPrint("Güncelleme hatası: $e");
        if (mounted) {
          setState(() => _isUpdatingTask = false);
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
      title: const Text('Görevi Düzenle'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Görev Başlığı',
                    icon: Icon(Icons.title),
                  ),
                  validator: (val) => val!.trim().isEmpty ? 'Başlık girin.' : null,
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
                  validator: (val) => val == null ? 'Firma seçin.' : null,
                ),
                const SizedBox(height: 16),

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
                  validator: (val) => val == null ? 'Çalışan seçin.' : null,
                ),
                const SizedBox(height: 16),

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
          onPressed: _isUpdatingTask ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isUpdatingTask ? null : _updateTask,
          child: _isUpdatingTask
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Güncelle'),
        ),
      ],
    );
  }
}