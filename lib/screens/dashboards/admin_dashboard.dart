import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// Sayfaları import et (içeri aktar)
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/employee_list_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/all_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/reports_page.dart';

// Diyalogları (diyalog pencereleri) import et (içeri aktar)
import 'package:gorev_takip_app_web/widgets/add_employee_dialog.dart';
// --- YENİ EKLENEN IMPORT ---
import 'package:gorev_takip_app_web/widgets/add_task_dialog.dart';
// -----------------------------


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Hangi sekmenin seçili olduğunu tutar

  // Gösterilecek sayfaların listesi
  static const List<Widget> _adminPages = <Widget>[
    EmployeeListPage(),   // Index 0
    AllTasksPage(),       // Index 1
    ReportsPage(),        // Index 2
  ];

  // Seçili Index'e (dizine) göre FAB (Kayan Düğme) döndüren fonksiyon
  Widget? _getFabForIndex(int index) {
    switch (index) {
    // 0. Sekme: Çalışanlar
      case 0:
        return FloatingActionButton.extended(
          icon: const Icon(Icons.person_add),
          label: const Text('Yeni Çalışan Ekle'),
          onPressed: () {
            // 'add_employee_dialog.dart'ı (çalışan ekleme diyaloğu) aç
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const AddEmployeeDialog();
              },
            );
          },
        );

    // 1. Sekme: Görevler
      case 1:
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add_task),
          label: const Text('Yeni Görev Ekle'),
          backgroundColor: Colors.blueAccent, // Rengi farklı olsun
          // --- GÜNCELLENEN KISIM ---
          onPressed: () {
            // Yeni 'add_task_dialog.dart'ı (görev ekleme diyaloğu) aç
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                // Yeni 'AddTaskDialog' widget'ımızı (bileşen) çağır
                return const AddTaskDialog();
              },
            );
          },
        );
    // -----------------------------

    // Diğer sekmelerde (örn: Raporlar) FAB (Kayan Düğme) gösterme
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Paneli'),
      body: Row(
        children: <Widget>[
          // Sol Navigasyon Menüsü (NavigationRail) (Aynen kaldı)
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

          // Ana İçerik Alanı (Aynen kaldı)
          Expanded(
            child: _adminPages[_selectedIndex],
          ),
        ],
      ),

      // FAB'ı (Kayan Düğme) yeni fonksiyonumuzdan çağırıyoruz (Aynen kaldı)
      floatingActionButton: _getFabForIndex(_selectedIndex),
    );
  }
}