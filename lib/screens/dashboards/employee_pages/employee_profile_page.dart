import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Bu 'widget' (bileşen) artık 'StatefulWidget' (Durum Bilgili Bileşen)
// çünkü form verilerini, yüklenme durumlarını ve mevcut
// kullanıcı bilgilerini 'state' (durum) içinde tutmamız gerekiyor.
class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  // Formların durumunu kontrol etmek için 'GlobalKey' (Global Anahtar)
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Form alanlarındaki metinleri yönetmek için
  // 'TextEditingController' (Metin Düzenleme Denetleyicisi)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // Yüklenme durumlarını yönetmek için
  bool _isInfoLoading = true; // Sayfa ilk açıldığında bilgileri yüklemek için 'true' (doğru)
  bool _isPasswordLoading = false; // Şifre değiştirme butonu için

  // Şu anki Firebase kullanıcısını al
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // Bu 'initState' (Başlangıç Durumu) fonksiyonu,
    // 'widget' (bileşen) ekrana çizilmeden önce çalışır
    super.initState();
    // Kullanıcının mevcut bilgilerini Firestore'dan yükle
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    // Sayfa kapandığında 'controller'ları (denetleyici)
    // temizle (hafıza sızıntısını önler)
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- 1. FONKSİYON: Mevcut Kullanıcı Bilgilerini Yükle ---
  Future<void> _loadCurrentUserData() async {
    // Eğer bir sebepten kullanıcı 'null' (boş) ise işlemi durdur
    if (_currentUser == null) {
      setState(() {
        _isInfoLoading = false;
      });
      return;
    }

    try {
      // 'users' (kullanıcılar) koleksiyonundan mevcut kullanıcının
      // 'uid'si (kimlik) ile eşleşen dokümanı 'get' (al) komutuyla çek
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        // Gelen veriyi bir 'Map' (harita) olarak al
        final data = userDoc.data() as Map<String, dynamic>;
        // '_nameController' (ad denetleyicisi) içindeki metni,
        // veritabanından gelen 'name' (ad) alanı ile doldur
        _nameController.text = data['name'] ?? '';
      }
    } catch (e) {
      debugPrint("Kullanıcı bilgisi yüklenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil bilgileri yüklenemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    // Yükleme işlemi bittiğinde (başarılı veya başarısız),
    // yükleniyor animasyonunu durdur
    if (mounted) {
      setState(() {
        _isInfoLoading = false;
      });
    }
  }

  // --- 2. FONKSİYON: İsim Bilgisini Güncelle ---
  Future<void> _updateProfileInfo() async {
    // Formun 'validator' (doğrulayıcı) kontrollerinden
    // geçip geçmediğine bak
    if (_infoFormKey.currentState!.validate()) {
      setState(() {
        _isInfoLoading = true; // "Kaydet" butonu için yüklenmeyi başlat
      });

      try {
        // 'users' (kullanıcılar) koleksiyonundaki dokümanı
        // 'update' (güncelle) komutuyla güncelle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({
          'name': _nameController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bilgiler başarıyla güncellendi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Profil güncellenirken hata: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: Bilgiler güncellenemedi. $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isInfoLoading = false; // Yüklenmeyi durdur
        });
      }
    }
  }

  // --- 3. FONKSİYON: Şifreyi Değiştir ---
  Future<void> _changePassword() async {
    // Formun 'validator' (doğrulayıcı) kontrollerinden geçip geçmediğine bak
    if (_passwordFormKey.currentState!.validate()) {
      // Yeni şifre ve tekrarının eşleşip eşleşmediğini kontrol et
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yeni şifreler eşleşmiyor.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Eşleşmiyorsa işlemi durdur
      }

      setState(() {
        _isPasswordLoading = true; // "Değiştir" butonu için yüklenmeyi başlat
      });

      try {
        // --- YENİDEN KİMLİK DOĞRULAMA (RE-AUTHENTICATION) ---
        // Güvenlik açısından kritik bir işlem (şifre değiştirme)
        // yapmadan önce, Firebase kullanıcının *gerçekten* o
        // kişi olduğunu doğrulamak için mevcut şifresini
        // tekrar girmesini ister.

        // 1. Kullanıcının e-postasını ve girdiği mevcut şifreyi al
        final String email = _currentUser!.email!;
        final String currentPassword = _currentPasswordController.text;

        // 2. Bir 'credential' (kimlik bilgisi) nesnesi oluştur
        final AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );

        // 3. Kullanıcıdan bu 'credential' (kimlik bilgisi) ile
        // yeniden kimlik doğrulamasını iste
        await _currentUser!.reauthenticateWithCredential(credential);

        // 4. Yeniden kimlik doğrulama BAŞARILI olursa,
        // (yani mevcut şifre doğruysa)
        // 'updatePassword' (şifreyi güncelle) komutunu çalıştır
        await _currentUser!.updatePassword(_newPasswordController.text);

        if (mounted) {
          setState(() {
            _isPasswordLoading = false; // Yüklenmeyi durdur
          });
          // Form alanlarını temizle
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şifreniz başarıyla değiştirildi.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Hata oluşursa (örn: mevcut şifre yanlışsa)
        debugPrint("Şifre değiştirme hatası: ${e.code}");
        if (mounted) {
          setState(() {
            _isPasswordLoading = false; // Yüklenmeyi durdur
          });
          String errorMessage = 'Bir hata oluştu.';
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            errorMessage = 'Girdiğiniz mevcut şifre hatalı.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        // Diğer hatalar
        debugPrint("Bilinmeyen şifre hatası: $e");
        if (mounted) {
          setState(() {
            _isPasswordLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sayfanın tamamını kaydırılabilir yap
    return SingleChildScrollView(
      // Sayfaya kenarlardan boşluk ver
      padding: const EdgeInsets.all(24.0),
      // İçeriği ortalamak ve web'de çok genişlemesini
      // engellemek için 'Align' (Hizala) ve 'ConstrainedBox' (Sınırlı Kutu)
      // kullanalım
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Maksimum genişlik 600px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BÖLÜM 1: KİŞİSEL BİLGİLER ---
              const Text(
                'Kişisel Bilgiler',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _infoFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // E-posta alanı (Değiştirilemez)
                        TextFormField(
                          // E-postayı 'currentUser' (mevcut kullanıcı)
                          // nesnesinden alıp göster
                          initialValue: _currentUser?.email ?? 'E-posta bulunamadı',
                          decoration: const InputDecoration(
                            labelText: 'E-posta (Değiştirilemez)',
                            icon: Icon(Icons.email_outlined),
                          ),
                          readOnly: true, // Sadece okunur
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // Ad Soyad alanı
                        TextFormField(
                          controller: _nameController, // 'name' (ad) ile dolu gelir
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            icon: Icon(Icons.person_outline),
                          ),
                          enabled: !_isInfoLoading, // Yüklenirken pasif yap
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Lütfen adınızı girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Kaydet Butonu
                        ElevatedButton(
                          onPressed: _isInfoLoading ? null : _updateProfileInfo,
                          child: _isInfoLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Bilgileri Kaydet'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 40),

              // --- BÖLÜM 2: ŞİFRE DEĞİŞTİRME ---
              const Text(
                'Şifre Değiştir',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Mevcut Şifre alanı
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Mevcut Şifre',
                            icon: Icon(Icons.lock_clock_outlined),
                          ),
                          obscureText: true, // Metni gizle
                          enabled: !_isPasswordLoading, // Yüklenirken pasif yap
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mevcut şifrenizi girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Yeni Şifre alanı
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Yeni Şifre',
                            icon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          enabled: !_isPasswordLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen yeni bir şifre girin.';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Yeni Şifre (Tekrar) alanı
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Yeni Şifre (Tekrar)',
                            icon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          enabled: !_isPasswordLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen yeni şifreyi tekrar girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Değiştir Butonu
                        ElevatedButton(
                          onPressed: _isPasswordLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                          ),
                          child: _isPasswordLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Şifreyi Değiştir'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}