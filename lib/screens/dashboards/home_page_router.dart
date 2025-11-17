import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Yönlenecek dashboard'ları ve ortak widget'ı import et
import 'package:gorev_takip_app_web/screens/dashboards/admin_dashboard.dart';
import 'package:gorev_takip_app_web/screens/dashboards/employee_dashboard.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// --- HomePageRouter (Rol Yönlendirici) ---
// Eski HomePage'in yeni adı ve yeri
class HomePageRouter extends StatelessWidget {
  const HomePageRouter({super.key});

  // Kullanıcının rolünü Firestore'dan çeken fonksiyon
  Future<String?> _getUserRole() async {
    // 1. Mevcut giriş yapan kullanıcıyı al
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
        final data = doc.data() as Map<String, dynamic>;

        // 4. 'role' alanını oku ve string olarak döndür
        if (data.containsKey('role')) {
          return data['role'] as String;
        }
      }
      // Doküman veya 'role' alanı bulunamazsa...
      debugPrint("Kullanıcı dokümanı veya 'role' alanı bulunamadı.");
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
        // Bu durum, genellikle Firestore'da kullanıcı için 'role' atanmadığında olur.
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Rolünüz belirlenemedi veya yetkiniz yok. Lütfen sistem yöneticinizle iletişime geçin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          // Kullanıcı bu ekranda kalırsa çıkış yapabilmeli
          appBar: CommonAppBar(title: "Yetki Sorunu"),
        );
      },
    );
  }
}