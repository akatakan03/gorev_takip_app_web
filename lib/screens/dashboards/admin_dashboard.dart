import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// Yeni oluşturduğumuz sayfaları import ediyoruz
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/employee_list_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/all_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/reports_page.dart';

// --- YENİ EKLENEN IMPORT ---
// Yeni çalışan ekleme diyalogumuzu import ediyoruz.
import 'package:gorev_takip_app_web/widgets/add_employee_dialog.dart';
// -----------------------------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _adminPages = <Widget>[
    EmployeeListPage(),   // Index 0
    AllTasksPage(),       // Index 1
    ReportsPage(),        // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Paneli'),
      body: Row(
        children: <Widget>[
          // Sol Navigasyon Menüsü (NavigationRail)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: false,
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('Çalışanlar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Görevler'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Raporlar'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Ana İçerik Alanı
          Expanded(
            child: _adminPages[_selectedIndex],
          ),
        ],
      ),

      // Floating Action Button (Yeni Çalışan Ekle)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Çalışan Ekle'),
        // --- GÜNCELLENEN KISIM BURASI ---
        onPressed: () {
          // Ekranda 'AddEmployeeDialog' widget'ımızı gösteren
          // bir diyalog açıyoruz.
          showDialog(
            context: context,
            // Diyalogun dışına tıklayarak kapatılmasını engelle (isteğe bağlı)
            barrierDismissible: false,
            builder: (BuildContext context) {
              // Yeni oluşturduğumuz widget'ı çağırıyoruz.
              return const AddEmployeeDialog();
            },
          );
        },
        // -----------------------------
      )
          : null, // Diğer sayfalarda FAB görünmesin.
    );
  }
}