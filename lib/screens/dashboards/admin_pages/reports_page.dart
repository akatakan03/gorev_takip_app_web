import 'package:flutter/material.dart';

// Burası raporların olacağı yer (şimdilik boş)
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Raporlar Sayfası',
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
          Text('Yakında burada raporlar gösterilecek.'),
        ],
      ),
    );
  }
}