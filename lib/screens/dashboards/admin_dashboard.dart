import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// Sayfalar
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/employee_list_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/all_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/reports_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/archived_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/companies_list_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/calendar_page.dart';

// Diyaloglar
import 'package:gorev_takip_app_web/widgets/add_employee_dialog.dart';
import 'package:gorev_takip_app_web/widgets/add_task_dialog.dart';
import 'package:gorev_takip_app_web/widgets/add_company_dialog.dart';
// --- YENİ IMPORT ---
import 'package:gorev_takip_app_web/widgets/add_schedule_dialog.dart';
// -------------------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _adminPages = <Widget>[
    EmployeeListPage(),     // Index 0
    AllTasksPage(),         // Index 1
    CalendarPage(),         // Index 2
    CompaniesListPage(),    // Index 3
    ReportsPage(),          // Index 4
    ArchivedTasksPage(),    // Index 5
  ];

  static const List<NavigationRailDestination> _adminDestinations = [
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
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: Text('Takvim'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.business_outlined),
      selectedIcon: Icon(Icons.business),
      label: Text('Firmalar'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Raporlar'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.archive_outlined),
      selectedIcon: Icon(Icons.archive),
      label: Text('Arşiv'),
    ),
  ];

  Widget? _getFabForIndex(int index) {
    switch (index) {
      case 0: // Çalışanlar
        return FloatingActionButton.extended(
          icon: const Icon(Icons.person_add),
          label: const Text('Yeni Çalışan Ekle'),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => const AddEmployeeDialog(),
            );
          },
        );

      case 1: // Görevler
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add_task),
          label: const Text('Yeni Görev Ekle'),
          backgroundColor: Colors.blueAccent,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => const AddTaskDialog(),
            );
          },
        );

      case 2: // --- GÜNCELLENDİ: Takvim ---
        return FloatingActionButton.extended(
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Çekim Planla'),
          backgroundColor: Colors.orangeAccent,
          onPressed: () {
            // Yeni oluşturduğumuz diyalogu aç
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => const AddScheduleDialog(),
            );
          },
        );

      case 3: // Firmalar
        return FloatingActionButton.extended(
          icon: const Icon(Icons.add_business),
          label: const Text('Yeni Firma Ekle'),
          backgroundColor: Colors.indigoAccent,
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => const AddCompanyDialog(),
            );
          },
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          appBar: const CommonAppBar(title: 'Admin Paneli'),

          body: isMobile
              ? _adminPages[_selectedIndex]
              : Row(
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
                destinations: _adminDestinations,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _adminPages[_selectedIndex],
              ),
            ],
          ),

          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: _adminDestinations.map((dest) {
              return BottomNavigationBarItem(
                icon: dest.icon,
                activeIcon: dest.selectedIcon,
                label: (dest.label as Text).data,
              );
            }).toList(),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.indigoAccent,
            unselectedItemColor: Colors.grey,
          )
              : null,

          floatingActionButton: _getFabForIndex(_selectedIndex),
        );
      },
    );
  }
}