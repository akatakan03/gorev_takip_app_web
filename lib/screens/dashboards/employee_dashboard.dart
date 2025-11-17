import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// --- YENİ IMPORTLAR ---
// Oluşturduğumuz yeni 'employee_pages' (çalışan sayfaları) dosyalarını import et
import 'package:gorev_takip_app_web/screens/dashboards/employee_pages/my_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/employee_pages/employee_profile_page.dart';
// ----------------------

// --- Çalışan Paneli ---
// Bu widget (bileşen) artık 'AdminDashboard' (Admin Paneli) gibi bir
// 'StatefulWidget' (Durum Bilgili Bileşen) ve 'NavigationRail' (Yan Navigasyon Çubuğu)
// içeren bir "ana çerçeve" (shell - kabuk) olacak.
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0; // Hangi sekmenin seçili olduğunu tutar

  // Çalışanın göreceği sayfaların listesi
  static const List<Widget> _employeePages = <Widget>[
    MyTasksPage(), // Index 0 (Az önce oluşturduğumuz görev listesi)
    EmployeeProfilePage(), // Index 1 (Az önce oluşturduğumuz boş profil sayfası)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Çalışan Paneli'), // Ortak AppBar'ı (Üst Çubuk) kullan
      body: Row(
        children: <Widget>[
          // Sol Navigasyon Menüsü (NavigationRail)
          NavigationRail(
            selectedIndex: _selectedIndex, // Seçili olan index'i (dizin) al
            onDestinationSelected: (int index) {
              // Yeni bir sekmeye tıklandığında 'state'i (durum) güncelle
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: false, // Sadece ikonlar görünsün (genişletilebilir)
            labelType: NavigationRailLabelType.all, // İkonların altında metinleri göster
            destinations: const <NavigationRailDestination>[
              // Sekme 0: Görevlerim
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Görevlerim'),
              ),
              // Sekme 1: Profilim
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profilim'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1), // Ayırıcı çizgi

          // Ana İçerik Alanı
          // Seçili olan index'e (dizin) göre '_employeePages' (çalışan sayfaları)
          // listesinden ilgili sayfayı gösterir.
          Expanded(
            child: _employeePages[_selectedIndex],
          ),
        ],
      ),
      // Çalışan panelinde bir 'FloatingActionButton'a (Kayan Eylem Düğmesi)
      // ihtiyacımız yok, çünkü eylemler kartların içinde.
      // floatingActionButton: null,
    );
  }
}