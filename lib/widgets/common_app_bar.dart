import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- Çıkış Yapma Butonunu içeren Ortak AppBar ---
// Sınıf adını public yapmak için başındaki _'ı kaldırdık (CommonAppBar)
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({super.key, this.title = 'Görev Takip'});

  final String title;

  // Çıkış yapma fonksiyonu
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate değişikliği algılayıp LoginPage'e yönlendirecek.
    } catch (e) {
      debugPrint('Çıkış yaparken hata: $e');
      // Hata olursa kullanıcıya bir SnackBar göster
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
          onPressed: () => _signOut(context), // Fonksiyonu çağır
        ),
      ],
    );
  }

  // AppBar'ın standart yüksekliğini belirlemek için (kToolbarHeight)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}