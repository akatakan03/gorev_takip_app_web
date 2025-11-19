import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// Sayfaları import et
import 'package:gorev_takip_app_web/screens/dashboards/employee_pages/my_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/employee_pages/employee_profile_page.dart';
// --- YENİ IMPORT: Takvim Sayfası ---
// Admin klasöründe olduğu için oradan çekiyoruz.
// İdealde 'common' (ortak) klasöründe olması gerekirdi ama şimdilik sorun değil.
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/calendar_page.dart';
// -----------------------------------

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  // --- GÜNCELLENEN SAYFA LİSTESİ ---
  static const List<Widget> _employeePages = <Widget>[
    MyTasksPage(),         // Index 0
    // --- YENİ: Takvim Sayfası ---
    // Buraya 'isReadOnly: true' parametresiyle ekliyoruz!
    CalendarPage(isReadOnly: true), // Index 1
    // ----------------------------
    EmployeeProfilePage(), // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Çalışan Paneli'),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: false,
            labelType: NavigationRailLabelType.all,
            // --- GÜNCELLENEN MENÜ ---
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Görevlerim'),
              ),
              // --- YENİ SEKME ---
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Takvim'),
              ),
              // ------------------
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profilim'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          Expanded(
            child: _employeePages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}