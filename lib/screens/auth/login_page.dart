import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- LoginPage (Giriş Ekranı) ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Eposta ve şifre için Controller (Text alanlarındaki yazıyı yönetir)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Yükleniyor durumunu yönetmek için (butona basılınca animasyon)
  bool _isLoading = false;
  // Hata mesajını göstermek için
  String? _errorMessage;

  // --- YENİ EKLENEN STATE ---
  // "Oturumu açık tut" checkbox'ının (onay kutusunun) durumunu
  // tutmak için bir boolean (doğru/yanlış) değişken.
  bool _rememberMe = false;
  // -------------------------

  // Şifrenin görünür olup olmadığını kontrol etmek için yeni state
  bool _isPasswordVisible = false;

  // Giriş yapma fonksiyonu
  Future<void> _signIn() async {
    // Butonun "yükleniyor" durumuna geçmesini sağla
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Eski hata mesajını temizle
    });

    try {
      // --- YENİ GÜNCELLEME: OTURUM SÜREKLİLİĞİ (PERSISTENCE) ---
      // Giriş yapma (signInWithEmailAndPassword) işleminden ÖNCE
      // oturumun kalıcılık türünü ayarlamamız gerekiyor.
      await FirebaseAuth.instance.setPersistence(
        // Eğer _rememberMe (beni hatırla) 'true' (doğru) ise,
        // kalıcılık türünü Persistence.LOCAL (Yerel) olarak ayarla.
        // Değilse, Persistence.SESSION (Oturum) olarak ayarla.
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
      // ----------------------------------------------------

      // Firebase Auth'u kullanarak Eposta ve Şifre ile giriş yapmayı dene
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), // Baştaki/sondaki boşlukları sil
        password: _passwordController.text.trim(),
      );
      // Not: Giriş başarılı olursa, StreamBuilder (AuthGate) bunu
      // otomatik olarak algılayacak ve bizi HomePage'e yönlendirecek.

    } on FirebaseAuthException catch (e) {
      // Eğer Firebase'den bir hata dönerse (örn: "user-not-found")
      debugPrint('Giriş hatası: ${e.code}');
      // Kullanıcıya uygun bir mesaj göster
      _errorMessage = _getErrorMessage(e.code);
    } catch (e) {
      // Diğer beklenmedik hatalar için
      debugPrint('Bilinmeyen hata: $e');
      _errorMessage = 'Bilinmeyen bir hata oluştu.';
    }

    // Hata oluştuysa veya işlem bittiyse "yükleniyor" durumunu kapat
    if (mounted) {
      // (Eğer sayfa hala ekrandaysa)
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Firebase hata kodlarını Türkçe'ye çeviren yardımcı fonksiyon
  // (Bu fonksiyonda değişiklik yok)
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta için kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre girdiniz.';
      case 'invalid-email':
        return 'Geçersiz e-posta formatı.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-disabled':
        return 'Bu kullanıcının hesabı devre dışı bırakılmış.';
      default:
        return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
    }
  }

  // --- YENİ EKLENECEK FONKSİYON ---
  Future<void> _resetPassword() async {
    // 0. E-posta alanının dolu olup olmadığını kontrol et
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage =
        'Şifrenizi sıfırlamak için lütfen e-posta alanını doldurun.';
      });
      return; // E-posta boşsa işlemi durdur
    }

    // 1. Kullanıcıdan onay iste (Senin istediğin diyalog)
    final bool? didRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Dışarı tıklamayı engelle
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Şifre Sıfırlama'),
          content: Text(
            '"$email" adresine bir şifre sıfırlama e-postası gönderilsin mi?',
          ),
          actions: <Widget>[
            // İptal butonu
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                // Diyaloğu kapatır ve 'false' (yanlış) değeri döndürür
                Navigator.of(dialogContext).pop(false);
              },
            ),
            // Gönder butonu
            TextButton(
              child: const Text('Gönder'),
              onPressed: () {
                // Diyaloğu kapatır ve 'true' (doğru) değeri döndürür
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    // 2. Eğer kullanıcı "Gönder" demezse (veya iptal ederse) işlemi durdur
    if (didRequest != true) {
      return;
    }

    // 3. E-postayı gönderme işlemini başlat
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase'in e-posta gönderme fonksiyonunu çağır
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // İşlem başarılıysa...
      if (mounted) {
        setState(() {
          _isLoading = false; // Yüklenmeyi durdur
        });
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sıfırlama e-postası gönderildi. Lütfen gelen kutunuzu (ve spam) kontrol edin.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Hata oluşursa
      _errorMessage = _getErrorMessage(e.code);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Diğer hatalar
      _errorMessage = 'Bilinmeyen bir hata oluştu.';
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
// --- YENİ FONKSİYONUN SONU ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Center(
        // Ekran küçüldüğünde (örn: mobil web) taşmayı önlemek için
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            // Kutuya maksimum genişlik ver (web'de çok yayılmasın)
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // E-posta alanı (Değişiklik yok)
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Şifre alanı (Değişiklik yok)
                // Şifre alanı (Görünürlük ikonu eklendi)
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration( // const ifadesini kaldırıyoruz
                    labelText: 'Şifre',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    // Sona eklenecek ikon (suffixIcon)
                    suffixIcon: IconButton(
                      // İkonun ne olacağını _isPasswordVisible durumuna göre belirle
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off // Eğer görünürse, "gizle" ikonu
                            : Icons.visibility,   // Eğer gizliyse, "göster" ikonu
                      ),
                      // İkona tıklandığında...
                      onPressed: () {
                        // Durumu güncellemek ve arayüzü yeniden çizmek için setState kullan
                        setState(() {
                          // Mevcut durumun tersini ata (true ise false, false ise true yap)
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  // obscureText (yazıyı gizleme) durumunu state'imize bağla
                  obscureText: !_isPasswordVisible,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                  enabled: !_isLoading,
                ),

                // --- YENİ EKLENEN WIDGET: CHECKBOX ---
                // Şifre alanı ile hata mesajı arasına ekledik.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Oturumu açık tut Checkbox'ı (Onay Kutusu)
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'Oturumu açık tut',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          value: _rememberMe,
                          onChanged: _isLoading ? null : (bool? value) { // Bu satırı GÜNCELLE (Adım 3'e bak)
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.indigoAccent,
                        ),
                      ),

                      // --- YENİ EKLENECEK BUTON ---
                      TextButton(
                        // Yükleniyorsa butonu pasif yap
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text(
                          'Şifremi unuttum?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigoAccent,
                          ),
                        ),
                      ),
                      // ---------------------------
                    ],
                  ),
                ),
                // ------------------------------------

                // Hata mesajını göstermek için
                // (Görünürlüğü _errorMessage'a bağlı)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Üst boşluğu azalttık
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Giriş Butonu (Değişiklik yok)
                _isLoading
                    ? const CircularProgressIndicator() // Yükleniyorsa animasyon
                    : SizedBox(
                  // Yüklenmiyorsa buton
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _signIn, // Giriş fonksiyonunu çağır
                    child: const Text(
                      'GİRİŞ YAP',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}