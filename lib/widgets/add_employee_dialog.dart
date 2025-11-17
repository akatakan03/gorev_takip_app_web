import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Bu widget, bir diyalog içinde gösterilecek formun kendisidir.
// StatefulWidget kullandık çünkü formun durumunu (yükleniyor mu, hata var mı)
// ve girilen metinleri yönetmemiz gerekiyor.
class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({super.key});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  // Formun durumunu takip etmek için bir "GlobalKey".
  // Bu, 'validate' (doğrula) işlemini tetiklememizi sağlar.
  final _formKey = GlobalKey<FormState>();

  // Metin alanlarındaki (TextField) yazıları okumak için Controller'lar.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // "Ekle" butonuna basıldığında bir yükleniyor animasyonu göstermek için.
  bool _isLoading = false;

  // Yeni çalışanı ekleyen ana fonksiyon
  Future<void> _addEmployee() async {
    // Önce formdaki 'validator' (doğrulayıcı) fonksiyonlarını çalıştır.
    // Eğer hepsi geçerliyse (örn: email boş değilse) 'true' döner.
    if (_formKey.currentState!.validate()) {
      // Yükleniyor durumunu başlat ve ekranı güncelle.
      setState(() {
        _isLoading = true;
      });

      try {
        // --- 1. AŞAMA: FIREBASE AUTHENTICATION ---
        // Girilen e-posta ve şifre ile yeni bir kullanıcı oluştur.
        // Bu işlem başarısız olursa (örn: email zaten kayıtlı) bir hata fırlatır.
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Kullanıcı başarıyla oluşturulduysa, 'userCredential' içinden
        // yeni kullanıcının 'uid' (benzersiz kimlik) bilgisini al.
        String newUserId = userCredential.user!.uid;

        // --- 2. AŞAMA: CLOUD FIRESTORE ---
        // 'users' koleksiyonuna git ve doküman ID'si olarak bu yeni 'uid'yi kullan.
        // 'set' metodu ile dokümanın içeriğini belirle.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUserId)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'employee', // En önemli kısım: rolünü 'employee' olarak ayarla.
          'createdAt': FieldValue.serverTimestamp(), // Oluşturulma tarihini ekle
        });

        // İşlem başarılıysa...
        if (mounted) {
          // Önce bu diyalog kutusunu kapat.
          Navigator.of(context).pop();
          // Ardından ekranda bir başarı mesajı (SnackBar) göster.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nameController.text.trim()} başarıyla eklendi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Eğer Firebase Auth bir hata fırlatırsa (örn: 'email-already-in-use')
        debugPrint("Firebase Auth Hatası: ${e.message}");
        if (mounted) {
          // Yükleniyor durumunu durdur.
          setState(() {
            _isLoading = false;
          });
          // Hata mesajını ekranda (SnackBar) göster.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        // Diğer beklenmedik hatalar için (örn: Firestore hatası)
        debugPrint("Genel Hata: $e");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bilinmeyen bir hata oluştu: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Widget ekrandan kaldırıldığında controller'ları temizle (hafıza sızıntısını önler)
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Diyalog kutusunun kendisini oluştur
    return AlertDialog(
      title: const Text('Yeni Çalışan Ekle'),
      // İçerik olarak, kaydırılabilir bir Form widget'ı kullan
      content: SingleChildScrollView(
        child: Form(
          key: _formKey, // Formu anahtarımızla ilişkilendir
          child: Column(
            mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
            children: [
              // Ad Soyad alanı
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  icon: Icon(Icons.person_outline),
                ),
                // Doğrulayıcı: Alanın boş olmamasını kontrol et
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir isim girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // E-posta alanı
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  icon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                // Doğrulayıcı: Alanın boş ve geçerli bir e-posta olmasını kontrol et
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir e-posta girin.';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Geçersiz e-posta formatı.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Şifre alanı
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Geçici Şifre',
                  icon: Icon(Icons.lock_outline),
                ),
                obscureText: true, // Şifreyi gizle
                // Doğrulayıcı: Firebase'in varsayılanı olan min 6 karakteri kontrol et
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir şifre girin.';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      // Diyalog kutusunun altındaki butonlar
      actions: [
        // İptal Butonu
        TextButton(
          // _isLoading (yükleniyor) durumunda butonları pasif yap (disable)
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        // Ekle Butonu
        ElevatedButton(
          onPressed: _isLoading ? null : _addEmployee, // _addEmployee fonksiyonunu çağır
          child: _isLoading
              ? const SizedBox( // Yükleniyorsa küçük bir animasyon göster
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Ekle'), // Yüklenmiyorsa 'Ekle' yaz
        ),
      ],
    );
  }
}