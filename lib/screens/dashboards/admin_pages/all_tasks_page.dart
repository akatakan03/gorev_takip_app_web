import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
import 'package:gorev_takip_app_web/widgets/edit_task_dialog.dart';

class AllTasksPage extends StatelessWidget {
  const AllTasksPage({super.key});

  // --- Fonksiyonlarda (Silme, Düzenleme, Stream, Renkler) değişiklik yok ---
  // --- O yüzden kod tekrarı olmaması için buraya eklemiyorum ---
  // --- Sadece build metodunu güncelliyoruz ---

  Stream<QuerySnapshot> _getTasksStream() {
    return FirebaseFirestore.instance.collection('tasks').snapshots();
  }

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
        // Başlık (Aynen kaldı)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tüm Görevler',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // StreamBuilder (Aynen kaldı)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTasksStream(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Sisteme kayıtlı hiç görev bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;

                // GridView (Aynen kaldı)
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
                    final taskData = tasks[index].data() as Map<String, dynamic>;
                    final taskId = tasks[index].id;
                    final String status = taskData['status'] ?? 'unknown';
                    final String taskTitle = taskData['title'] ?? 'Başlıksız Görev';

                    // --- YENİ DEĞİŞKEN: AÇIKLAMAYI AL ---
                    // 'description' (açıklama) alanını veritabanından çek.
                    // Eğer 'null' (boş) gelirse, 'Bu görev için açıklama girilmemiş.' yaz.
                    final String taskDescription =
                    taskData['description']?.isEmpty ?? true
                        ? "Bu görev için açıklama girilmemiş."
                        : taskData['description'];
                    // ------------------------------------

                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: _getStatusColor(status),
                          width: 4.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 4,
                      // --- GÜNCELLENEN YER: KART İÇERİĞİ ---
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column( // Kartın ana sütunu
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Satır: Başlık ve Butonlar (Aynen kaldı)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton( // Düzenle Butonu
                                      icon: const Icon(Icons.edit_outlined),
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
                                      icon: const Icon(Icons.delete_outline),
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
                                  ],
                                )
                              ],
                            ),

                            // --- YENİ EKLENEN WIDGET (BİLEŞEN): AÇIKLAMA ---
                            const SizedBox(height: 8),
                            // 'Expanded' (Genişletilmiş) widget'ı (bileşen),
                            // bu metnin kartta kalan boş alanı doldurmasını sağlar.
                            Expanded(
                              // 'SingleChildScrollView' (Tekil Kaydırılabilir),
                              // açıklama uzunsa taşma yapmak yerine
                              // kaydırılabilir bir alan oluşturur.
                              child: SingleChildScrollView(
                                child: Text(
                                  taskDescription, // Açıklama değişkenini buraya koy
                                  style: TextStyle(
                                    fontSize: 14,
                                    // Eğer açıklama bizim varsayılan metnimizse
                                    // soluk ve italik yap.
                                    color: taskData['description']?.isEmpty ?? true
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                    fontStyle: taskData['description']?.isEmpty ?? true
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ),
                            // 'Spacer' (ara doldurucu) yerine 'Expanded' (Genişletilmiş)
                            // kullandığımız için buradaki boşluk yeterli olacaktır.
                            const SizedBox(height: 8),
                            // ---------------------------------

                            // 2. ve 3. Satırlar (En altta görünecek grup)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row( // Atanan kişi
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    GetUserName(
                                      userId: taskData['assignedTo'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container( // Durum etiketi
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4.0),
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
                      // -----------------------------------
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