import 'package:flutter/material.dart';
// Ortak AppBar'ı import et
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// --- Admin Paneli ---
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Paneli'), // Ortak AppBar'ı kullan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 80, color: Colors.indigoAccent),
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