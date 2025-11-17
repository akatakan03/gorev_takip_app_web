import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
// Bu sayfada düzenleme veya silme olmayacak,
// o yüzden diyalogları 'import' (içeri aktarma) etmemize gerek yok.

class ArchivedTasksPage extends StatelessWidget {
  const ArchivedTasksPage({super.key});

  // 'tasks' (görevler) koleksiyonunu dinleyen 'stream' (akış)
  Stream<QuerySnapshot> _getArchivedTasksStream() {
    // Bu 'stream' (akış), 'status' (durum) alanı 'archived' (arşivlendi)
    // olan görevleri çeker.
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'archived')
        .snapshots();
    // NOT: Bu sorgu için de Firebase'in yeni bir 'tek alanlı'
    // (single-field) 'index' (dizin) oluşturmanızı istemesi muhtemeldir.
    // Hata alırsanız, konsoldaki linke tıklayarak 'index'i (dizin) oluşturun.
  }

  // --- Durum ('status') renkleri ve metinleri ---
  // (all_tasks_page.dart (tüm görevler sayfası) içindekilerin aynısı,
  // ama 'archived' (arşivlendi) için bir renk ekleyebiliriz)
  Color _getStatusColor(String status) {
    if (status == 'archived') {
      return Colors.grey[700]!; // Arşivlenmiş görevler için gri renk
    }
    // Diğer durumlar (her ihtimale karşı)
    switch (status) {
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTurkishStatus(String status) {
    if (status == 'archived') {
      return 'Arşivlendi';
    }
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }
  // --- Fonksiyonlar burada bitiyor ---

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Arşivlenmiş Görevler',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // 'StreamBuilder' (Akış Oluşturucu)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getArchivedTasksStream(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // Olası 'index' (dizin) hatası
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Görevler yüklenemedi. (Firebase Index (Dizin) hatası olabilir, konsolu kontrol edin)\n\nHata: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Arşivlenmiş herhangi bir görev bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;

                // 'GridView' (Izgara Görünümü)
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.7, // Oran 'all_tasks_page' (tüm görevler sayfası) ile aynı
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskData =
                    tasks[index].data() as Map<String, dynamic>;
                    final String status = taskData['status'] ?? 'unknown';
                    final String taskTitle =
                        taskData['title'] ?? 'Başlıksız Görev';
                    final String taskDescription =
                    taskData['description']?.isEmpty ?? true
                        ? "Açıklama yok."
                        : taskData['description'];

                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: _getStatusColor(status),
                          width: 4.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Satır: Sadece Başlık
                            // (Arşivde Düzenle/Sil butonu yok)
                            Expanded(
                              flex: 2, // Başlığa biraz daha fazla yer ver
                              child: Text(
                                taskTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // 2. Satır: Açıklama
                            Expanded(
                              flex: 3, // Açıklamaya daha fazla yer ver
                              child: SingleChildScrollView(
                                child: Text(
                                  taskDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                    fontStyle:
                                    taskData['description']?.isEmpty ??
                                        true
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 3. Satır: Atanan Kişi ve Durum
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    GetUserName(
                                      userId: taskData['assignedTo'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    _getTurkishStatus(status).toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // TODO: İstenirse buraya bir "Arşivden Çıkar"
                            // (Unarchive) butonu eklenebilir.
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