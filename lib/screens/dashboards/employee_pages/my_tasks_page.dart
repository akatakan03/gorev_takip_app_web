import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';

// Bu, eski 'EmployeeDashboard' (Çalışan Paneli) widget'ımızın (bileşen)
// 'Scaffold' (İskele) ve 'AppBar' (Üst Çubuk) kısmı çıkarılmış,
// sadece içeriğe odaklanmış halidir.
class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // Sadece bu çalışana atanan görevleri getiren 'stream' (akış)
  Stream<QuerySnapshot> _getMyTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUserId)
        .snapshots();
  }

  // --- YENİ FONKSİYON: GÖREVİ TAMAMLA ---
  // "Görevi Tamamla" butonuna basıldığında, görevin durumunu ('status') günceller.
  Future<void> _updateTaskStatus(
      String taskId, String newStatus, String taskTitle) async {
    try {
      // 'tasks' (görevler) koleksiyonuna git, 'doc' (doküman) metoduyla
      // 'taskId' (görev kimliği) ile eşleşen dokümanı bul
      // ve 'update' (güncelle) komutuyla 'status' (durum) alanını değiştir.
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        // TODO: Buraya bir 'completedAt' (tamamlanma tarihi) zaman damgası eklenebilir.
      });

      if (mounted) {
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$taskTitle" görevi "$newStatus" olarak güncellendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hata olursa göster
      debugPrint("Görev durumu güncellenirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: Görev durumu güncellenemedi. $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
  // --- Fonksiyonlar burada bitiyor ---

  @override
  Widget build(BuildContext context) {
    // Bu 'widget' (bileşen) artık bir 'Scaffold' (İskele) döndürmüyor,
    // doğrudan içeriği döndürüyor.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Bana Atanan Görevler',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // Görevleri listeleyen 'StreamBuilder' (Akış Oluşturucu)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyTasksStream(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Size atanmış herhangi bir görev bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;

                // 'ListView' (Liste Görünümü) (Aynen kaldı)
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
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
                        ? "Açıklama yok."
                        : taskData['description'];
                    final String createdById = taskData['createdBy'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: _getStatusColor(status),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Satır: Başlık ve Durum (Aynen kaldı)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    taskTitle,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 5.0),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status)
                                        .withOpacity(0.2),
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
                            const SizedBox(height: 12),

                            // 2. Satır: Açıklama (Aynen kaldı)
                            Text(
                              taskDescription,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[400],
                                fontStyle:
                                taskData['description']?.isEmpty ?? true
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),

                            // 3. Satır: Görevi Atayan (Aynen kaldı)
                            Row(
                              children: [
                                const Icon(Icons.admin_panel_settings_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text(
                                  "Atayan: ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                GetUserName(
                                  userId: createdById,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),

                            // 4. Satır: Eylem Butonları
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // --- GÜNCELLENEN BUTON ---
                                // Eğer görev zaten 'completed' (tamamlandı) değilse
                                // 'Görevi Tamamla' butonunu göster
                                if (status != 'completed')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      // Görevin durumunu ('status') 'completed' (tamamlandı)
                                      // olarak güncelleyen fonksiyonu çağır
                                      _updateTaskStatus(
                                        taskId,
                                        'completed', // Yeni durum
                                        taskTitle,
                                      );
                                    },
                                    child: const Text('Görevi Tamamla'),
                                  )
                                // TODO: Admin'in 'Revize Gerekli'
                                // (needs_revision) durumuna alması
                                // ihtimaline karşı buraya 'Devam Et'
                                // (in_progress) butonu da eklenebilir.
                              ],
                            )
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