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

  // Giriş yapma fonksiyonu
  Future<void> _signIn() async {
    // Butonun "yükleniyor" durumuna geçmesini sağla
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Eski hata mesajını temizle
    });

    try {
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
                // E-posta alanı
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),

                // Şifre alanı
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true, // Şifreyi gizle
                  autofillHints: const [AutofillHints.password],
                  // Enter'a basınca giriş yapsın
                  onSubmitted: (_) => _signIn(),
                ),

                // Hata mesajını göstermek için
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Giriş Butonu
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