import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';

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
    // Mevcut kullanıcı kimliğini (ID) al
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // Sadece bu çalışana atanan görevleri getiren 'stream' (akış)
  Stream<QuerySnapshot> _getMyTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
    // 'assignedTo' (atanan kişi) alanı 'currentUserId' (mevcut kullanıcı kimliği) olan
        .where('assignedTo', isEqualTo: currentUserId)
    // VE 'status' (durum) alanı 'archived' (arşivlendi) olmayan
        .where('status', isNotEqualTo: 'archived')
        .snapshots();
    // NOT: Bu birleşik sorgu (compound query) için Firebase'in
    // bir 'index' (dizin) oluşturulmasını istemesi muhtemeldir.
    // Hata alırsanız, konsoldaki linke tıklayarak 'index'i (dizin) oluşturun.
  }

  // Görevin durumunu ('status') güncelleyen fonksiyon
  // Bu fonksiyon zaten esnek olduğu için (yeni durumu 'newStatus'
  // parametresiyle alır) değişikliğe gerek yok.
  Future<void> _updateTaskStatus(
      String taskId, String newStatus, String taskTitle) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        if (newStatus == 'completed')
          'completedAt': FieldValue.serverTimestamp()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$taskTitle" görevi "$newStatus" olarak güncellendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
        return 'Bekliyor'; // (Başlamadı)
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık (Aynen kaldı)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aktif Görevlerim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // Görevleri listeleyen 'StreamBuilder' (Akış Oluşturucu)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyTasksStream(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

              // Yüklenme, Hata ve Boş Liste durumları (Aynen kaldı)
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
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
                    'Size atanmış aktif bir görev bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Veri geldiyse Listeyi oluştur
              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;
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

                    // Görev Kartı (Card)
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
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                                // --- GÜNCELLENEN EYLEM BÖLÜMÜ ---
                                // Sizin akışınıza (flow) göre güncellendi.

                                // Eğer durum 'pending' (bekliyor) VEYA
                                // 'needs_revision' (revize gerekli) ise:
                                if (status == 'pending' || status == 'needs_revision')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent, // "Başla" butonu mavi
                                    ),
                                    onPressed: () {
                                      // Durumu 'in_progress' (devam ediyor) yap
                                      _updateTaskStatus(
                                        taskId,
                                        'in_progress', // Yeni durum
                                        taskTitle,
                                      );
                                    },
                                    child: const Text('Çalışmaya Başla'),
                                  ),

                                // Eğer durum 'in_progress' (devam ediyor) ise:
                                if (status == 'in_progress')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green, // "Tamamla" butonu yeşil
                                    ),
                                    onPressed: () {
                                      // Durumu 'completed' (tamamlandı) yap
                                      _updateTaskStatus(
                                        taskId,
                                        'completed', // Yeni durum
                                        taskTitle,
                                      );
                                    },
                                    child: const Text('Görevi Tamamla'),
                                  ),

                                // Eğer durum 'completed' (tamamlandı) ise:
                                if (status == 'completed')
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      'Admin Onayı Bekleniyor...',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                // ---------------------------------
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