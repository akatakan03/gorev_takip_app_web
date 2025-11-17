import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Yönlendireceğimiz ekranları import et
import 'package:gorev_takip_app_web/screens/dashboards/home_page_router.dart';
import 'package:gorev_takip_app_web/screens/auth/login_page.dart';

// AuthGate: Kullanıcının giriş yapıp yapmadığını dinleyen ana "kapı"
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth'daki "authStateChanges" stream'ini (akışını) dinliyoruz.
    // Bu bize "User?" (ya bir kullanıcı ya da null) döner.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Henüz veri gelmediyse (bekleniyor)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Yükleniyor animasyonu göster
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Veri geldiyse ve kullanıcı "null" DEĞİLSE (snapshot.hasData == true)
        // Yani kullanıcı giriş yapmışsa...
        if (snapshot.hasData) {
          // Onu Ana Ekrana (HomePageRouter) yönlendir
          // Burası artık rol kontrolü yapacak.
          return const HomePageRouter();
        }

        // 3. Veri geldiyse ama kullanıcı "null" İSE
        // Yani kullanıcı giriş yapmamışsa...
        // Onu Giriş Ekranına (LoginPage) yönlendir
        return const LoginPage();
      },
    );
  }
}