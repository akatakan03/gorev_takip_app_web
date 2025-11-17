import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Bu widget (bileşen), "Görevi Düzenle" ikonuna (İngilizce: icon) basıldığında
// açılacak olan diyalogdur.
// 'StatefulWidget' (Durum Bilgili Bileşen) olmalıdır çünkü:
// 1. Çalışan listesini veritabanından çekerken bir yüklenme durumu ('loading') olacak.
// 2. Formdaki controller'ların (denetleyicilerin) mevcut veriyle doldurulması gerekecek.
// 3. Seçili çalışanın kim olduğunu ('selectedEmployeeId') bir 'state' (durum) içinde tutmamız gerekecek.
class EditTaskDialog extends StatefulWidget {
  // Diyalogun, hangi görevin güncelleneceğini bilmesi gerekir
  final String taskId;
  // Formu mevcut verilerle doldurmak için görevin şu anki verisi
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
  // Controller'ları (denetleyicileri) 'late' (sonradan) olarak tanımlıyoruz,
  // çünkü 'initState' (başlangıç durumu) içinde başlatacağız.
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  // Veritabanından çekilen çalışanları tutacak liste
  List<QueryDocumentSnapshot> _employees = [];
  bool _isLoadingEmployees = true; // Çalışanlar yüklenirken 'true' (doğru) olacak
  String? _selectedEmployeeId; // Açılır menüden seçilen çalışanın ID'si (kimliği)

  bool _isUpdatingTask = false; // "Güncelle" butonuna basıldığında 'true' (doğru) olacak

  @override
  void initState() {
    // Bu 'initState' (Başlangıç Durumu) fonksiyonu, widget (bileşen) ekrana çizilmeden
    // hemen önce çalışır.
    super.initState();

    // Controller'ları (Denetleyicileri), dışarıdan 'widget.currentTaskData' ile
    // gelen mevcut verilerle başlatıyoruz.
    _titleController = TextEditingController(text: widget.currentTaskData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.currentTaskData['description'] ?? '');

    // Mevcut atanmış çalışanın ID'sini (kimlik) 'state'e (durum) ata
    _selectedEmployeeId = widget.currentTaskData['assignedTo'];

    // Çalışanları veritabanından çekme işlemini başlat.
    _fetchEmployees();
  }

  // 'users' (kullanıcılar) koleksiyonundan 'role' (rol) alanı
  // 'employee' (çalışan) olan herkesi getiren fonksiyon.
  // (Bu, 'add_task_dialog.dart' (görev ekleme diyaloğu) içindekinin aynısı)
  Future<void> _fetchEmployees() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();

      setState(() {
        _employees = snapshot.docs;
        _isLoadingEmployees = false;
      });
    } catch (e) {
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

  // Görevi güncelleyen fonksiyon
  Future<void> _updateTask() async {
    // Formun geçerli olup olmadığını kontrol et
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdatingTask = true; // Yükleniyor animasyonunu göster
      });

      try {
        // --- GÜNCELLEME İŞLEMİ ---
        // 'tasks' (görevler) koleksiyonuna git, 'doc' (doküman) metoduyla
        // 'widget.taskId' (görev kimliği) ile eşleşen dokümanı bul
        // ve 'update' (güncelle) komutuyla veriyi değiştir.
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'assignedTo': _selectedEmployeeId, // Seçili çalışanın ID'si (kimliği)
          // 'status' (durum) veya 'createdBy' (yaratan) gibi diğer
          // alanları değiştirmiyoruz.
        });

        if (mounted) {
          Navigator.of(context).pop(); // Diyaloğu kapat
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Görev başarıyla güncellendi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hata olursa göster
        debugPrint("Görev güncellenirken hata: $e");
        if (mounted) {
          setState(() {
            _isUpdatingTask = false;
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
      title: const Text('Görevi Düzenle'),
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
                  controller: _titleController, // Mevcut başlıkla dolu gelir
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
                  controller: _descriptionController, // Mevcut açıklama ile dolu gelir
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    icon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Çalışan Seçme Açılır Menüsü
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId, // Mevcut atanan kişi seçili gelir
                  hint: const Text('Bir çalışan seçin'),
                  icon: const Icon(Icons.person_search),
                  isExpanded: true,
                  items: _employees.map((doc) {
                    final user = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(user['name'] ?? user['email'] ?? 'İsimsiz'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedEmployeeId = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Lütfen bir çalışan atayın.';
                    }
                    return null;
                  },
                ),
                // TODO: 'status' (durum) alanı da buradan
                // (örn: 'pending', 'completed') güncellenebilir.
              ],
            ),
          ),
        ),
      ),
      actions: [
        // İptal Butonu
        TextButton(
          onPressed: _isUpdatingTask ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        // Güncelle Butonu
        ElevatedButton(
          onPressed: _isUpdatingTask ? null : _updateTask,
          child: _isUpdatingTask
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Görevi Güncelle'),
        ),
      ],
    );
  }
}