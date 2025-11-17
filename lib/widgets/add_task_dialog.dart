import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Bu widget, "Yeni Görev Ekle" butonuna basıldığında açılacak diyalogdur.
// StatefulWidget (Durum Bilgili Bileşen) olmalı çünkü:
// 1. Çalışan listesini veritabanından çekerken bir yüklenme durumu ('loading') olacak.
// 2. Seçilen çalışanın kim olduğunu ('selectedEmployeeId') bir 'state' (durum) içinde tutmamız gerekecek.
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Veritabanından çekilen çalışanları tutacak liste.
  // QueryDocumentSnapshot, her bir çalışanın verisini (data) ve ID'sini (kimlik) tutar.
  List<QueryDocumentSnapshot> _employees = [];
  bool _isLoadingEmployees = true; // Çalışanlar yüklenirken 'true' (doğru) olacak
  String? _selectedEmployeeId; // Açılır menüden seçilen çalışanın ID'si (kimliği)

  bool _isCreatingTask = false; // "Oluştur" butonuna basıldığında 'true' (doğru) olacak

  @override
  void initState() {
    // Bu 'initState' (Başlangıç Durumu) fonksiyonu, widget (bileşen) ekrana çizilmeden
    // hemen önce çalışır.
    super.initState();
    // Çalışanları veritabanından çekme işlemini başlat.
    _fetchEmployees();
  }

  // 'users' (kullanıcılar) koleksiyonundan 'role' (rol) alanı
  // 'employee' (çalışan) olan herkesi getiren fonksiyon.
  Future<void> _fetchEmployees() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();

      // Gelen çalışanları '_employees' listesine ata
      // ve yüklenmenin bittiğini belirtmek için state'i (durumu) güncelle
      setState(() {
        _employees = snapshot.docs;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      // Bir hata olursa, yüklenmeyi durdur ve hatayı göster
      debugPrint("Çalışanlar getirilirken hata: $e");
      setState(() {
        _isLoadingEmployees = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çalışan listesi getirilemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Yeni görevi 'tasks' (görevler) koleksiyonuna kaydeden fonksiyon
  Future<void> _createTask() async {
    // Formun geçerli olup olmadığını kontrol et (başlık boş mu, çalışan seçildi mi vb.)
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreatingTask = true; // Yükleniyor animasyonunu göster
      });

      try {
        // Şu anki admin kullanıcısının kimliğini (UID) al
        final String? adminId = FirebaseAuth.instance.currentUser?.uid;
        if (adminId == null) {
          throw Exception('Görevi oluşturan adminin kimliği bulunamadı.');
        }

        // 'tasks' (görevler) koleksiyonuna yeni bir doküman 'add' (ekle)
        await FirebaseFirestore.instance.collection('tasks').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'assignedTo': _selectedEmployeeId, // Açılır menüden seçilen çalışanın ID'si (kimliği)
          'createdBy': adminId, // Görevi oluşturan adminin ID'si (kimliği)
          'status': 'pending', // Görevin varsayılan durumu 'bekliyor'
          'createdAt': FieldValue.serverTimestamp(), // Oluşturulma zamanı
        });

        if (mounted) {
          Navigator.of(context).pop(); // Diyaloğu kapat
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni görev başarıyla oluşturuldu.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hata olursa göster
        debugPrint("Görev oluşturulurken hata: $e");
        if (mounted) {
          setState(() {
            _isCreatingTask = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.redAccent,
            ),
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
      // İçeriğin genişliğini belirlemek için bir 'Container' (Kapsayıcı) kullanalım
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4, // Ekran genişliğinin %40'ı
        child: _isLoadingEmployees
            ? const Center( // Çalışanlar yükleniyorsa
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Çalışanlar yükleniyor...'),
            ],
          ),
        )
            : SingleChildScrollView( // Yüklendiyse formu göster
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Görev Başlığı alanı
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Görev Başlığı',
                    icon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir görev başlığı girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Görev Açıklaması alanı
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    icon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3, // 3 satırlık bir alan
                ),
                const SizedBox(height: 16),

                // Çalışan Seçme Açılır Menüsü
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId, // O an seçili olan ID (kimlik)
                  hint: const Text('Bir çalışan seçin'), // Boşken görünecek yazı
                  icon: const Icon(Icons.person_search),
                  isExpanded: true, // Menünün tüm genişliği kaplamasını sağla
                  // '_employees' (çalışanlar) listesindeki her bir
                  // 'doc' (doküman) için bir 'DropdownMenuItem' (açılır menü öğesi) oluştur
                  items: _employees.map((doc) {
                    final user = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id, // Öğenin değeri çalışanın ID'si (kimliği)
                      child: Text(user['name'] ?? user['email'] ?? 'İsimsiz'), // Görünecek yazı
                    );
                  }).toList(),
                  // Bir öğe seçildiğinde...
                  onChanged: (String? newValue) {
                    // '_selectedEmployeeId' state'ini (durumunu) güncelle
                    setState(() {
                      _selectedEmployeeId = newValue;
                    });
                  },
                  // Doğrulayıcı: Bir çalışanın seçilmiş olmasını zorunlu kıl
                  validator: (value) {
                    if (value == null) {
                      return 'Lütfen bir çalışan atayın.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // İptal Butonu
        TextButton(
          onPressed: _isCreatingTask ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        // Görev Oluştur Butonu
        ElevatedButton(
          onPressed: _isCreatingTask ? null : _createTask,
          child: _isCreatingTask
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Görevi Oluştur'),
        ),
      ],
    );
  }
}