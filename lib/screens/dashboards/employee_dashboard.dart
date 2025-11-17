import 'package:flutter/material.dart';
// Ortak AppBar'ı import et
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// --- Çalışan Paneli ---
class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Çalışan Paneli'), // Ortak AppBar'ı kullan
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