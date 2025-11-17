import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
import 'package:gorev_takip_app_web/widgets/task_detail_dialog.dart';

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

  // Fonksiyonlar (Değişiklik yok)
  Stream<QuerySnapshot> _getMyTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: 'archived')
        .snapshots();
  }

  Future<void> _updateTaskStatus(
      String taskId, String newStatus, String taskTitle) async {
    try {
      Map<String, Object> dataToUpdate = {
        'status': newStatus,
      };

      if (newStatus == 'completed') {
        dataToUpdate['completedAt'] = FieldValue.serverTimestamp();
        dataToUpdate['revision_note'] = FieldValue.delete();
      }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aktif Görevlerim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyTasksStream(),
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
                    'Size atanmış aktif bir görev bulunamadı.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

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
                    final String? revisionNote = taskData['revision_note'];
                    final String createdById = taskData['createdBy'] ?? '';

                    // --- KART (CARD) İÇERİĞİ GÜNCELLENDİ ---
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
                      child: InkWell(
                        onTap: () {
                          _showTaskDetailDialog(context, taskId, taskData);
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Satır: Başlık ve Durum
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

                              // Revizyon Notu (Aynen kaldı)
                              if ((status == 'needs_revision' || status == 'in_progress') &&
                                  revisionNote != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 12.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(color: Colors.redAccent)),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            status == 'in_progress'
                                                ? Icons.info_outline
                                                : Icons.warning_amber_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
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
                                      Text(revisionNote,
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),

                              const Divider(height: 24),

                              // --- GÜNCELLENDİ: 3. Satır: Atayan ve Butonlar ---
                              // 'Row' (Satır) yapısını mobil
                              // taşmayı (`overflow`) (taşma) önleyecek
                              // şekilde 'Flexible' (Esnek)
                              // 'widget'lar (bileşen) ile güncelledik
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Görevi Atayan (Esnek)
                                  Flexible(
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.admin_panel_settings_outlined,
                                            size: 16,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Atayan: ",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        // 'GetUserName' (Kullanıcı Adı Getir)
                                        // 'widget'ı (bileşen) artık 'Expanded' (Genişletilmiş)
                                        // içinde, böylece taşarsa kısaltılır.
                                        Expanded(
                                          child: GetUserName(
                                            userId: createdById,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Eylem Butonları
                                  // (Bu 'Row' (Satır) 'widget'ı (bileşen)
                                  // zaten kendi boyutunu bilir,
                                  // 'Flexible' (Esnek) yapmaya gerek yok)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'pending' ||
                                          status == 'needs_revision')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                          ),
                                          onPressed: () {
                                            _updateTaskStatus(
                                              taskId,
                                              'in_progress',
                                              taskTitle,
                                            );
                                          },
                                          child:
                                          const Text('Çalışmaya Başla'),
                                        ),
                                      if (status == 'in_progress')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          onPressed: () {
                                            _updateTaskStatus(
                                              taskId,
                                              'completed',
                                              taskTitle,
                                            );
                                          },
                                          child: const Text('Görevi Tamamla'),
                                        ),
                                      if (status == 'completed')
                                        const Padding(
                                          padding:
                                          EdgeInsets.only(right: 8.0),
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
                              )
                              // --- GÜNCELLEME BİTTİ ---
                            ],
                          ),
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