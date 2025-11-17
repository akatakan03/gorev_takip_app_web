import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/common_app_bar.dart';

// Sayfaları import et (içeri aktar)
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/employee_list_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/all_tasks_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/reports_page.dart';
import 'package:gorev_takip_app_web/screens/dashboards/admin_pages/archived_tasks_page.dart';

// Diyalogları (diyalog pencereleri) import et (içeri aktar)
import 'package:gorev_takip_app_web/widgets/add_employee_dialog.dart';
import 'package:gorev_takip_app_web/widgets/add_task_dialog.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Hangi sekmenin seçili olduğunu tutar

  // Gösterilecek sayfaların listesi (Değişiklik yok)
  static const List<Widget> _adminPages = <Widget>[
    EmployeeListPage(),   // Index 0
    AllTasksPage(),       // Index 1
    ReportsPage(),        // Index 2
    ArchivedTasksPage(),  // Index 3
  ];

  // --- YENİ EKLENDİ: Navigasyon Hedefleri Listesi ---
  // Bu listeyi hem 'NavigationRail' (Yan Navigasyon Çubuğu) hem de
  // 'BottomNavigationBar' (Alt Navigasyon Çubuğu) için ortak kullanacağız.
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
  // -------------------------------------------------

  // FAB (Kayan Düğme) döndüren fonksiyon (Değişiklik yok)
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
              builder: (BuildContext context) {
                return const AddEmployeeDialog();
              },
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
              builder: (BuildContext context) {
                return const AddTaskDialog();
              },
            );
          },
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- YENİ EKLENDİ: LayoutBuilder (Yerleşim Oluşturucu) ---
    // 'Scaffold' (İskele) 'widget'ımızı (bileşen) bir 'LayoutBuilder' (Yerleşim Oluşturucu)
    // ile sarmalıyoruz. Bu bize ekranın mevcut genişliğini ('constraints' - (kısıtlamalar)) verir.
    return LayoutBuilder(
      builder: (context, constraints) {

        // Ekran genişliğine göre bir kırılma noktası (breakpoint - (İngilizce)) belirliyoruz.
        // 600 pikselden darsa, 'isMobile' (mobil) 'true' (doğru) olacak.
        final bool isMobile = constraints.maxWidth < 600;

        return Scaffold(
          appBar: const CommonAppBar(title: 'Admin Paneli'),

          // --- GÜNCELLENDİ: body (gövde) ---
          // 'body' (gövde) artık 'isMobile' (mobil) değişkenine göre değişecek
          body: isMobile
          // EĞER MOBİL İSE (DAR EKRAN):
          // 'Row' (Satır) kullanma.
          // 'NavigationRail' (Yan Navigasyon Çubuğu) gösterme.
          // Sayfayı doğrudan göster (tam genişlikte).
              ? _adminPages[_selectedIndex]

          // EĞER MOBİL DEĞİLSE (GENİŞ EKRAN):
          // Eski 'desktop' (masaüstü) 'layout'umuzu (yerleşim) göster.
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
                // Hedefleri yeni ortak listeden al
                destinations: _adminDestinations,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _adminPages[_selectedIndex],
              ),
            ],
          ),

          // --- YENİ EKLENDİ: bottomNavigationBar (Alt Navigasyon Çubuğu) ---
          // Eğer 'isMobile' (mobil) 'true' (doğru) ise, bir
          // 'BottomNavigationBar' (Alt Navigasyon Çubuğu) göster.
          // 'false' (yanlış) ise 'null' (boş) ata (gösterme).
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
            // 'currentIndex' (mevcut dizin) ve 'onTap' (dokunma)
            // 'NavigationRail' (Yan Navigasyon Çubuğu) ile aynı 'state'i (durum) kullanır
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            // Hedefleri, 'NavigationRailDestination' (Yan Navigasyon Çubuğu Hedefi)
            // listesinden 'BottomNavigationBarItem' (Alt Navigasyon Çubuğu Öğesi)
            // listesine dönüştür
            items: _adminDestinations.map((dest) {
              return BottomNavigationBarItem(
                icon: dest.icon,
                activeIcon: dest.selectedIcon,
                label: (dest.label as Text).data, // Metni al
              );
            }).toList(),

            // ÖNEMLİ: Mobil 'layout'umuzda (yerleşim) 3'ten fazla
            // ('Raporlar', 'Arşiv') öğe olduğu için, 'type' (tür)
            // 'fixed' (sabit) olmalıdır, yoksa kaybolurlar.
            type: BottomNavigationBarType.fixed,
            // Seçili ve seçili olmayan etiketlerin renklerini ayarla
            selectedItemColor: Colors.indigoAccent,
            unselectedItemColor: Colors.grey,
          )
              : null, // Mobil değilse 'bottomNavigationBar' (alt navigasyon çubuğu) gösterme

          // FAB (Kayan Düğme) (Değişiklik yok, 'Scaffold'a (İskele) bağlı kalır)
          floatingActionButton: _getFabForIndex(_selectedIndex),
        );
      },
    );
    // --- DEĞİŞİKLİK BURADA BİTİYOR ---
  }
}