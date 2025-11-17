import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
// --- YENİ EKLENEN IMPORT ---
// Arşivdeki görevlere de tıklayıp
// detaylarını görebilmek için
import 'package:gorev_takip_app_web/widgets/task_detail_dialog.dart';
// -----------------------------

class ArchivedTasksPage extends StatelessWidget {
  const ArchivedTasksPage({super.key});

  // 'stream' (akış) (Değişiklik yok)
  Stream<QuerySnapshot> _getArchivedTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'archived')
        .snapshots();
  }

  // Renk ve Metin fonksiyonları (Değişiklik yok)
  Color _getStatusColor(String status) {
    if (status == 'archived') {
      return Colors.grey[700]!;
    }
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

  // --- Yardımı Fonksiyonlar (YENİ EKLENDİ) ---
  // (all_tasks_page.dart (tüm görevler sayfası)
  // dosyasından kopyalandı)
  int _calculateCrossAxisCount(double width) {
    if (width < 600) {
      return 1; // Mobil
    } else if (width < 1000) {
      return 2; // Tablet
    } else {
      return 3; // Desktop (Masaüstü)
    }
  }

  double _calculateChildAspectRatio(double width) {
    // --- DÜZELTME ---
    // 'all_tasks_page.dart' (tüm görevler sayfası) ile
    // tutarlı olması için mobil oranı 4.2'ye yükseltiyoruz.
    if (width < 600) {
      return 4.2; // 3.5'ten 4.2'ye yükseltildi
    }
    // ----------------
    else if (width < 1000) {
      return 2.5; // Tablet
    } else {
      return 2.2; // Desktop (Masaüstü)
    }
  }
  // ------------------------------------------

  // --- YENİ FONKSİYON: GÖREV DETAY DİYALOĞUNU GÖSTER ---
  Future<void> _showTaskDetailDialog(
      BuildContext context, String taskId, Map<String, dynamic> taskData) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return TaskDetailDialog(
          taskId: taskId,
          taskData: taskData,
        );
      },
    );
  }
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Arşivlenmiş Görevler',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getArchivedTasksStream(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Görevler yüklenemedi.\n\nHata: ${snapshot.error}',
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

                // --- GÜNCELLENDİ: LayoutBuilder (Yerleşim Oluşturucu) Eklendi ---
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final int crossAxisCount = _calculateCrossAxisCount(width);
                    final double childAspectRatio =
                    _calculateChildAspectRatio(width);

                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final taskData =
                        tasks[index].data() as Map<String, dynamic>;
                        final taskId = tasks[index].id;
                        final String status = taskData['status'] ?? 'unknown';
                        final String taskTitle =
                            taskData['title'] ?? 'Başlıksız Görev';

                        // --- KART (CARD) İÇERİĞİ GÜNCELLENDİ ---
                        return InkWell(
                          onTap: () {
                            _showTaskDetailDialog(context, taskId, taskData);
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: _getStatusColor(status),
                                width: 4.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // 1. Satır: Sadece Başlık
                                  Expanded(
                                    child: Text(
                                      taskTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Açıklama ('description') (açıklama) kaldırıldı
                                  const Spacer(),

                                  // Alt Kısım: Atanan Kişi ve Durum
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: GetUserName(
                                              userId:
                                              taskData['assignedTo'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status)
                                              .withOpacity(0.2),
                                          borderRadius:
                                          BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          _getTurkishStatus(status)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      // TODO: Buraya "Arşivden Çıkar"
                                      // butonu eklenebilir.
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        // --- KART (CARD) GÜNCELLEMESİ BİTTİ ---
                      },
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