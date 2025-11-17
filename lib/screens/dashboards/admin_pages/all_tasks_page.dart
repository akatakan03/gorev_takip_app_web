import 'package:flutter/material.dart';

// Burası admin'in tüm görevleri göreceği yer (şimdilik boş)
class AllTasksPage extends StatelessWidget {
  const AllTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Tüm Görevler Sayfası',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text('Yakında burada tüm görevler listelenecek.'),
        ],
      ),
    );
  }
}