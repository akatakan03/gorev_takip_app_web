import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// --- YENİ EKLENEN IMPORT ---
// Yeni "Çalışan Düzenle" diyalogumuzu import ediyoruz.
import 'package:gorev_takip_app_web/widgets/edit_employee_dialog.dart';
// -----------------------------

class EmployeeListPage extends StatelessWidget {
  const EmployeeListPage({super.key});

  // Stream (Akış) fonksiyonu (Aynen kaldı)
  Stream<QuerySnapshot> _getEmployeesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .snapshots();
  }

  // --- YENİ FONKSİYON: DÜZENLEME DİYALOĞU ---
  // Bu fonksiyon, "Düzenle" butonuna basıldığında
  // 'edit_employee_dialog.dart' widget'ımızı (bileşenimizi) gösterir.
  Future<void> _showEditEmployeeDialog(
      BuildContext context,
      String employeeId,
      Map<String, dynamic> employeeData,
      ) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklamayı engelle
      builder: (BuildContext dialogContext) {
        // Yeni diyaloğumuzu çağırıyoruz ve ona ID'yi + mevcut veriyi yolluyoruz
        return EditEmployeeDialog(
          employeeId: employeeId,
          currentData: employeeData, // Mevcut veriyi diyaloğa yolla
        );
      },
    );
  }
  // ------------------------------------------

  // Silme Onay Diyaloğu (Aynen kaldı)
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context,
      String employeeId,
      String employeeName
      ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Çalışanı Sil'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('"$employeeName" adlı çalışanı silmek istediğinizden emin misiniz?'),
                const SizedBox(height: 10),
                const Text(
                  'NOT: Bu işlem, çalışanın sadece veritabanı kaydını siler.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Sil'),
              onPressed: () {
                // Silme fonksiyonunu çağır
                _deleteEmployee(employeeId, employeeName, context);
                Navigator.of(dialogContext).pop(); // Diyaloğu kapat
              },
            ),
          ],
        );
      },
    );
  }

  // Silme Fonksiyonu (Aynen kaldı)
  Future<void> _deleteEmployee(
      String employeeId,
      String employeeName,
      BuildContext context
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employeeId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$employeeName" başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Çalışan silinirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Çalışan silinemedi. $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık (Aynen kaldı)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Sistemdeki Çalışanlar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        // StreamBuilder (Aynen kaldı)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getEmployeesStream(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

              // Yükleniyor... (Aynen kaldı)
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Hata... (Aynen kaldı)
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              // Boş liste... (Aynen kaldı)
              if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Sisteme kayıtlı hiç çalışan bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Veri geldi... (Aynen kaldı)
              if (snapshot.hasData) {
                final employees = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    // --- GÜNCELLEME ---
                    // Sadece 'displayName' ve 'displayEmail' almak yerine,
                    // dokümanın tüm verisini bir 'Map' (harita) olarak alıyoruz.
                    // Çünkü bu Map'i 'Edit' (Düzenle) diyaloguna yollamamız gerek.
                    final employeeData = employees[index].data() as Map<String, dynamic>;
                    final employeeId = employees[index].id;

                    // Veriyi Map'ten okuyoruz
                    final String displayName = employeeData['name'] ?? employeeData['email'] ?? 'İsimsiz';
                    final String displayEmail = employeeData['email'] ?? 'E-posta yok';
                    // ------------------

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: ListTile(
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(displayEmail),
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        // --- GÜNCELLENEN KISIM: 'trailing' (sondaki) butonlar ---
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // GÖREV ATA BUTONU (Aynen kaldı)
                            IconButton(
                              icon: const Icon(Icons.assignment_ind),
                              color: Colors.blueAccent,
                              tooltip: 'Görev Ata',
                              onPressed: () {
                                // TODO: Görev atama
                              },
                            ),

                            // --- GÜNCELLENEN BUTON: DÜZENLE ---
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: Colors.blueGrey, // Rengi biraz daha belirgin yapalım
                              tooltip: 'Çalışanı Düzenle',
                              onPressed: () {
                                // Yeni "Düzenle" diyalogumuzu çağırıyoruz
                                _showEditEmployeeDialog(
                                    context,
                                    employeeId,
                                    employeeData // Çalışanın tüm verisini diyaloğa gönder
                                );
                              },
                            ),
                            // ---------------------------------

                            // SİL BUTONU (Aynen kaldı)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.redAccent,
                              tooltip: 'Çalışanı Sil',
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context,
                                    employeeId,
                                    displayName
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return const Center(child: Text('Bir şeyler ters gitti.'));
            },
          ),
        ),
      ],
    );
  }
}