import 'package:flutter/material.dart';

// Burası çalışanın profilinin (örn: şifre değiştirme) olacağı yer (şimdilik boş)
class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_circle_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profil Sayfası',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text('Yakında burada profil ayarları gösterilecek.'),
        ],
      ),
    );
  }
}