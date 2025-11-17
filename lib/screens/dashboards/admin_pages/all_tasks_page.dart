// Gerekli 'import' (içeri aktarma) bildirimleri
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
import 'package:gorev_takip_app_web/widgets/edit_task_dialog.dart';

class AllTasksPage extends StatelessWidget {
  const AllTasksPage({super.key});

  // 'tasks' (görevler) koleksiyonunu dinleyen 'stream' (akış)
  Stream<QuerySnapshot> _getTasksStream() {
    // Adminin, 'archived' (arşivlendi) olanlar hariç tüm görevleri görmesini sağlıyoruz
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isNotEqualTo: 'archived')
        .snapshots();
    // NOT: Bu sorgu için de bir Firebase Index (Dizin) gerekebilir.
    // 'status' (durum) alanı için tek başına bir index (dizin) isteyebilir.
  }

  // Durum ('status') renkleri (Aynen kaldı)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'in_progress':
        return Colors.blueAccent;
      case 'completed':
        return Colors.green;
      case 'needs_revision':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // Durum ('status') metinleri (Aynen kaldı)
  String _getTurkishStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'in_progress':
        return 'Devam Ediyor';
      case 'completed':
        return 'Tamamlandı';
      case 'needs_revision':
        return 'Revize Gerekli';
      default:
        return 'Bilinmiyor';
    }
  }

  // --- YENİ FONKSİYON: GÖREV DURUMUNU GÜNCELLEME ---
  // Bu, çalışanın panelindekine benzer, ancak adminin
  // 'revize' veya 'arşiv' yapabilmesi için.
  Future<void> _updateTaskStatus(
      BuildContext context,
      String taskId,
      String newStatus,
      String taskTitle
      ) async {
    try {
      // Görevi bul ve 'status' (durum) alanını güncelle
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': newStatus,
      });

      // 'ScaffoldMessenger' (Cihaz Ekran Bildirimi) göstermek için
      // 'context' (bağlam) değişkeninin 'mounted' (eklenti) olup olmadığını
      // kontrol ediyoruz (iyi bir pratiktir).
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$taskTitle" görevi "$newStatus" olarak güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Görev durumu güncellenirken hata: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Görev durumu güncellenemedi. $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- YENİ FONKSİYON: ARŞİVLEME ONAY DİYALOĞU ---
  // "Arşivle" butonu, görevi gizleyeceği için bir onay ister.
  Future<void> _showArchiveConfirmationDialog(
      BuildContext context,
      String taskId,
      String taskTitle
      ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Görevi Onayla ve Arşivle'),
          content: Text(
            '"$taskTitle" başlıklı görevi "Arşivlendi" olarak işaretlemek istediğinizden emin misiniz?\n\nBu görev, tüm aktif listelerden kaldırılacaktır.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            // Onaylama Butonu
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Onayla ve Arşivle'),
              onPressed: () {
                // Görevin durumunu ('status') 'archived' (arşivlendi) olarak güncelle
                _updateTaskStatus(context, taskId, 'archived', taskTitle);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 'Edit' (Düzenle) ve 'Delete' (Sil) diyalogları (Aynen kaldı)
  Future<void> _showEditTaskDialog(
      BuildContext context, String taskId, Map<String, dynamic> taskData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return EditTaskDialog(
          taskId: taskId,
          currentTaskData: taskData,
        );
      },
    );
  }

  Future<void> _showDeleteTaskConfirmationDialog(
      BuildContext context, String taskId, String taskTitle) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Görevi Sil'),
          content: Text(
            '"$taskTitle" başlıklı görevi kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
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
                _deleteTask(taskId, taskTitle, context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(
      String taskId, String taskTitle, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$taskTitle" başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Görev silinirken hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Görev silinemedi. $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
            'Aktif Görevler (Admin Onayı)', // Başlığı güncelledik
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // 'StreamBuilder' (Akış Oluşturucu)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTasksStream(),
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
                    'Sisteme kayıtlı aktif görev bulunamadı.', // Metni güncelledik
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;

                // 'GridView' (Izgara Görünümü) (Aynen kaldı)
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskData =
                    tasks[index].data() as Map<String, dynamic>;
                    final taskId = tasks[index].id;
                    final String status = taskData['status'] ?? 'unknown';
                    final String taskTitle =
                        taskData['title'] ?? 'Başlıksız Görev';
                    final String taskDescription =
                    taskData['description']?.isEmpty ?? true
                        ? "Bu görev için açıklama girilmemiş."
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
                            // 1. Satır: Başlık ve Butonlar
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                Expanded(
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
                                // --- GÜNCELLENEN KISIM: KART EYLEM BUTONLARI ---
                                // Bu 'Row' (Satır), görevin durumuna ('status')
                                // göre farklı ikonlar (icon) gösterecek
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // EĞER DURUM 'completed' (TAMAMLANDI) İSE:
                                    // Admin (Yönetici) onay butonlarını göster
                                    if (status == 'completed') ...[
                                      // 'Revize İste' Butonu
                                      IconButton(
                                        icon: const Icon(Icons.replay), // 'Geri Gönder' ikonu
                                        color: Colors.redAccent,
                                        tooltip: 'Revize İste',
                                        iconSize: 20,
                                        onPressed: () {
                                          // Durumu ('status') 'needs_revision' (Revize Gerekli) yap
                                          _updateTaskStatus(
                                            context,
                                            taskId,
                                            'needs_revision',
                                            taskTitle,
                                          );
                                        },
                                      ),
                                      // 'Onayla ve Arşivle' Butonu
                                      IconButton(
                                        icon: const Icon(Icons.archive_outlined), // 'Arşiv' ikonu
                                        color: Colors.green,
                                        tooltip: 'Onayla ve Arşivle',
                                        iconSize: 20,
                                        onPressed: () {
                                          // Arşivleme onayı sor
                                          _showArchiveConfirmationDialog(
                                            context,
                                            taskId,
                                            taskTitle,
                                          );
                                        },
                                      ),
                                    ]
                                    // EĞER DURUM 'completed' (TAMAMLANDI) DEĞİLSE:
                                    // Standart 'Düzenle' ve 'Sil' butonlarını göster
                                    else ...[
                                      IconButton( // Düzenle Butonu
                                        icon:
                                        const Icon(Icons.edit_outlined),
                                        color: Colors.blueGrey,
                                        tooltip: 'Görevi Düzenle',
                                        iconSize: 20,
                                        onPressed: () {
                                          _showEditTaskDialog(
                                              context,
                                              taskId,
                                              taskData
                                          );
                                        },
                                      ),
                                      IconButton( // Sil Butonu
                                        icon:
                                        const Icon(Icons.delete_outline),
                                        color: Colors.redAccent,
                                        tooltip: 'Görevi Sil',
                                        iconSize: 20,
                                        onPressed: () {
                                          _showDeleteTaskConfirmationDialog(
                                              context,
                                              taskId,
                                              taskTitle
                                          );
                                        },
                                      ),
                                    ]
                                  ],
                                )
                                // --- GÜNCELLEME BİTTİ ---
                              ],
                            ),

                            // Açıklama
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  taskDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: taskData['description']
                                        ?.isEmpty ??
                                        true
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    fontStyle: taskData['description']
                                        ?.isEmpty ??
                                        true
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Alt Kısım: Atanan Kişi ve Durum
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