import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Bu widget, 'Düzenle' butonuna basıldığında açılacak diyalogdur.
// 'Create' (Oluşturma) diyalogundan farkı, dışarıdan mevcut veriyi almasıdır.
class EditEmployeeDialog extends StatefulWidget {
  final String employeeId; // Hangi çalışanın güncelleneceğini bilmek için ID'si
  final Map<String, dynamic> currentData; // Formu doldurmak için mevcut verileri

  const EditEmployeeDialog({
    super.key,
    required this.employeeId,
    required this.currentData,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  // Controller'ları (Denetleyicileri) 'late' (sonradan) olarak tanımlıyoruz
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isLoading = false;

  @override
  void initState() {
    // Bu 'initState' (Başlangıç Durumu) fonksiyonu, widget ekrana çizilmeden
    // hemen önce çalışır.
    super.initState();
    // Controller'ları (Denetleyicileri), dışarıdan 'widget.currentData' ile
    // gelen mevcut verilerle başlatıyoruz.
    _nameController = TextEditingController(text: widget.currentData['name'] ?? '');
    _emailController = TextEditingController(text: widget.currentData['email'] ?? '');
  }

  // Çalışanı güncelleyen fonksiyon
  Future<void> _updateEmployee() async {
    // Formdaki 'validator'ları (doğrulayıcıları) kontrol et
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Yükleniyor animasyonunu başlat
      });

      try {
        // --- GÜNCELLEME İŞLEMİ ---
        // 'users' koleksiyonunda, 'widget.employeeId' ile eşleşen dokümanı bul
        // ve 'update' (güncelle) metodu ile sadece 'name' (isim) alanını güncelle.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.employeeId)
            .update({
          'name': _nameController.text.trim(),
          // E-posta ve rolü şimdilik değiştirmiyoruz.
          // E-posta değişikliği Auth tarafında da yapılmalı, bu daha karmaşık bir işlem.
        });

        if (mounted) {
          Navigator.of(context).pop(); // Diyaloğu kapat
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nameController.text.trim()} başarıyla güncellendi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hata olursa göster
        debugPrint("Çalışan güncellenirken hata: $e");
        if (mounted) {
          setState(() {
            _isLoading = false;
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
    // Widget kapandığında controller'ları (denetleyicileri) temizle
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Çalışanı Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ad Soyad alanı
              TextFormField(
                controller: _nameController, // Mevcut isimle dolu gelir
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  icon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir isim girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // E-posta alanı (sadece okunur)
              TextFormField(
                controller: _emailController, // Mevcut e-posta ile dolu gelir
                decoration: const InputDecoration(
                  labelText: 'E-posta (Değiştirilemez)',
                  icon: Icon(Icons.email_outlined),
                ),
                readOnly: true, // Bu alanı değiştirilemez yap
                style: TextStyle(color: Colors.grey[500]),
              ),
              // Not: Şifre alanını buraya koymuyoruz. Şifre güncelleme
              // güvenlik nedeniyle ayrı bir "şifre sıfırlama" akışı olmalıdır.
            ],
          ),
        ),
      ),
      actions: [
        // İptal Butonu
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        // Güncelle Butonu
        ElevatedButton(
          onPressed: _isLoading ? null : _updateEmployee, // _updateEmployee fonksiyonunu çağır
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Güncelle'),
        ),
      ],
    );
  }
}