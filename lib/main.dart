import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Firestore'u tekrar import ediyoruz, çünkü role okuyacağız.
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Firebase Yapılandırması (Aynen kalıyor) ---
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDn5c3nzB5pB-H-iDDL6ZhG1aDQHRXAVQc",
  authDomain: "gorev-takip-76c3a.firebaseapp.com",
  projectId: "gorev-takip-76c3a",
  storageBucket: "gorev-takip-76c3a.firebasestorage.app",
  messagingSenderId: "561539134953",
  appId: "1:561539134953:web:8bcfde24bafb9895bd0778",
  measurementId: "G-6ZKC0RZ9XF", // Bu bazen olmayabilir, o zaman bu satırı silebilirsiniz.
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: firebaseOptions,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Görev Takip Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

// --- AuthGate (Kimlik Kapısı) - (Aynen kalıyor) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // Kullanıcı giriş yapmışsa, onu HomePage Yönlendiricisine gönder
          return const HomePage();
        }
        // Kullanıcı giriş yapmamışsa, LoginPage'e gönder
        return const LoginPage();
      },
    );
  }
}

// --- HomePage (Rol Yönlendirici) - (Artık bir Yönlendirici) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Kullanıcının rolünü Firestore'dan çeken fonksiyon
  Future<String?> _getUserRole() async {
    // 1. Mevcut giriş yapan kullanıcıyı al (null olamaz, çünkü AuthGate'den geçti)
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // Ekstra güvenlik kontrolü

    try {
      // 2. 'users' koleksiyonundan kullanıcının UID'sine ait dokümanı al
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 3. Doküman varsa ve 'data'sı null değilse...
      if (doc.exists && doc.data() != null) {
        // 'data'yı bir Map olarak al
        final data = doc.data() as Map<String, dynamic>;

        // 4. 'role' alanını oku ve string olarak döndür
        if (data.containsKey('role')) {
          return data['role'] as String;
        }
      }
      // Doküman veya 'role' alanı bulunamazsa...
      return null;

    } catch (e) {
      // Bir hata oluşursa konsola yazdır
      debugPrint("Rol alınırken hata: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // HomePage artık bir "FutureBuilder" (Gelecek İnşa Edici)
    // _getUserRole() fonksiyonu bir kez çalışır ve bir "gelecek" sonucu bekler.
    return FutureBuilder<String?>(
      future: _getUserRole(), // Çalıştırılacak fonksiyon
      builder: (context, snapshot) {

        // 1. Veri Bekleniyor (Yükleniyor)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Hata Oluştu
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Bir hata oluştu: ${snapshot.error}')),
          );
        }

        // 3. Veri Geldi (Başarılı)
        if (snapshot.hasData) {
          final String? role = snapshot.data; // Gelen rol ('admin', 'employee' veya null)

          // 4. Role göre yönlendirme yap
          if (role == 'admin') {
            return const AdminDashboard(); // Admin ise Admin Panelini göster
          } else if (role == 'employee') {
            return const EmployeeDashboard(); // Çalışan ise Çalışan Panelini göster
          }
        }

        // 5. Veri gelmediyse (rol=null veya beklenmedik bir durum)
        return const Scaffold(
          body: Center(
            child: Text('Rolünüz belirlenemedi veya yetkiniz yok.'),
          ),
          // Kullanıcı bu ekranda kalırsa çıkış yapabilmeli
          appBar: _CommonAppBar(), // (Aşağıda tanımladık)
        );
      },
    );
  }
}

// --- Çıkış Yapma Butonunu içeren Ortak AppBar ---
// Bu AppBar'ı hem Admin hem Çalışan paneline ekleyeceğiz.
class _CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CommonAppBar({this.title = 'Görev Takip'});

  final String title;

  // Çıkış yapma fonksiyonu
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate değişikliği algılayıp LoginPage'e yönlendirecek.
    } catch (e) {
      debugPrint('Çıkış yaparken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Çıkış Yap',
          onPressed: () => _signOut(context),
        ),
      ],
    );
  }

  // AppBar'ın standart yüksekliğini belirlemek için
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


// --- Admin Paneli (Şimdilik boş) ---
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _CommonAppBar(title: 'Admin Paneli'), // Ortak AppBar'ı kullan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.indigoAccent),
            const SizedBox(height: 16),
            const Text(
              'Hoşgeldiniz, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Çalışanları yönetebilir ve görev atayabilirsiniz.'),
            // TODO: Buraya çalışan listesi, görev atama butonu vb. gelecek.
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Yeni çalışan ekleme veya görev oluşturma ekranı
        },
        tooltip: 'Yeni Görev / Çalışan Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Çalışan Paneli (Şimdilik boş) ---
class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _CommonAppBar(title: 'Çalışan Paneli'), // Ortak AppBar'ı kullan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Hoşgeldiniz, Çalışan!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Size atanan görevleri burada görebilirsiniz.'),
            // TODO: Buraya sadece bu çalışana atanan görevlerin listesi gelecek.
          ],
        ),
      ),
    );
  }
}

// --- LoginPage (Giriş Ekranı) - (Aynen kalıyor) ---
// (Bir önceki adımdaki LoginPage kodunun tamamı buraya gelecek)
// (Kodu kısa tutmak için buraya eklemiyorum, sizdekini değiştirmenize gerek yok)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Giriş hatası: ${e.code}');
      _errorMessage = _getErrorMessage(e.code);
    } catch (e) {
      debugPrint('Bilinmeyen hata: $e');
      _errorMessage = 'Bilinmeyen bir hata oluştu.';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _signIn,
                    child: const Text(
                      'GİRİŞ YAP',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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