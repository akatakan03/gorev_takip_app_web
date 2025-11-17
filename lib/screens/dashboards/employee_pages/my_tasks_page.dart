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
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // 'stream' (akış) (Aynen kaldı)
  Stream<QuerySnapshot> _getMyTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: 'archived')
        .snapshots();
  }

  // --- GÜNCELLENEN FONKSİYON: DURUM GÜNCELLEME ---
  Future<void> _updateTaskStatus(
      String taskId, String newStatus, String taskTitle) async {
    try {
      // Güncellenecek veriyi bir 'Map' (harita) olarak hazırla
      Map<String, Object> dataToUpdate = {
        'status': newStatus,
      };

      // Eğer çalışan görevi 'completed' (tamamlandı) olarak
      // işaretliyorsa...
      if (newStatus == 'completed') {
        // 'completedAt' (tamamlanma tarihi) zaman damgası ekle
        dataToUpdate['completedAt'] = FieldValue.serverTimestamp();
        // VE Adminin (Yönetici) yazdığı 'revision_note' (revizyon notu)
        // alanını sil (temizle).
        dataToUpdate['revision_note'] = FieldValue.delete();
      }

      // Hazırladığımız 'Map' (harita) ile dokümanı güncelle
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(dataToUpdate);

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

  // Durum ('status') renk ve metin fonksiyonları (Aynen kaldı)
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aktif Görevlerim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // 'StreamBuilder' (Akış Oluşturucu)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyTasksStream(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {

              // Yüklenme, Hata, Boş Liste durumları (Aynen kaldı)
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

                    // --- YENİ ALAN: REVİZYON NOTUNU AL ---
                    // 'revision_note' (revizyon notu) alanını veritabanından çek.
                    // Eğer 'null' (boş) değilse, 'revisionNote' (revizyon notu)
                    // değişkenine ata.
                    final String? revisionNote = taskData['revision_note'];
                    // ------------------------------------

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

                            // --- YENİ WIDGET (BİLEŞEN): REVİZYON NOTU ALANI ---
                            // Eğer 'status' (durum) 'needs_revision' (Revize Gerekli)
                            // ise ve 'revisionNote' (revizyon notu) 'null' (boş) değilse
                            if ((status == 'needs_revision' || status == 'in_progress') && revisionNote != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 12.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(color: Colors.redAccent)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Admin (Yönetici) Revizyon Notu:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      revisionNote, // Adminin (Yönetici) yazdığı not
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            // ------------------------------------

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

                            // 4. Satır: Eylem Butonları (Aynen kaldı)
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 'pending' (bekliyor) VEYA 'needs_revision' (revize gerekli) ise
                                if (status == 'pending' || status == 'needs_revision')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                    onPressed: () {
                                      _updateTaskStatus(
                                        taskId,
                                        'in_progress', // Yeni durum
                                        taskTitle,
                                      );
                                    },
                                    child: const Text('Çalışmaya Başla'),
                                  ),

                                // 'in_progress' (devam ediyor) ise
                                if (status == 'in_progress')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () {
                                      _updateTaskStatus(
                                        taskId,
                                        'completed', // Yeni durum
                                        taskTitle,
                                      );
                                    },
                                    child: const Text('Görevi Tamamla'),
                                  ),

                                // 'completed' (tamamlandı) ise
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