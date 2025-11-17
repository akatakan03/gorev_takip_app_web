import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
import 'package:gorev_takip_app_web/widgets/edit_task_dialog.dart';
import 'package:gorev_takip_app_web/widgets/request_revision_dialog.dart';

class AllTasksPage extends StatelessWidget {
  const AllTasksPage({super.key});

  // 'stream' (akış)
  Stream<QuerySnapshot> _getTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isNotEqualTo: 'archived')
        .snapshots();
  }

  // Renk ve Metin fonksiyonları
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

  // Revizyon diyaloğunu göster
  Future<void> _showRequestRevisionDialog(
      BuildContext context,
      String taskId,
      String taskTitle
      ) async {
    final String? revisionNote = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return RequestRevisionDialog(taskTitle: taskTitle);
      },
    );

    if (revisionNote != null && context.mounted) {
      _updateTaskWithRevision(context, taskId, taskTitle, revisionNote);
    }
  }

  // Görevi revizyon notu ile güncelle
  Future<void> _updateTaskWithRevision(
      BuildContext context,
      String taskId,
      String taskTitle,
      String revisionNote
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': 'needs_revision',
        'revision_note': revisionNote,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$taskTitle" görevi revizyon için geri gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Görev revizyonu güncellenirken hata: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Revizyon gönderilemedi. $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Arşivleme onayı
  Future<void> _showArchiveConfirmationDialog(
      BuildContext context,
      String taskId,
      String taskTitle
      ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Görevi Onayla ve Arşivle'),
          content: Text(
            '"$taskTitle" başlıklı görevi "Arşivlendi" olarak işaretlemek istediğinizden emin misiniz?\n\nBu görev, tüm aktif listelerden kaldırılacaktır.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Onayla ve Arşivle'),
              onPressed: () {
                _updateTaskStatus_Archive(context, taskId, 'archived', taskTitle);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Arşivleme için durum ('status') güncelleme
  Future<void> _updateTaskStatus_Archive(
      BuildContext context,
      String taskId,
      String newStatus,
      String taskTitle
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'status': newStatus});

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

  // --- HATA DÜZELTMESİ BURADA ---
  // Düzenleme diyaloğunu göster
  Future<void> _showEditTaskDialog(
      BuildContext context, String taskId, Map<String, dynamic> taskData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return EditTaskDialog(
          taskId: taskId,
          // Hata buradaydı: 'currentData:' yerine 'currentTaskData:' olmalı
          currentTaskData: taskData,
        );
      },
    );
  }
  // --- DÜZELTME BİTTİ ---

  // Silme onayı
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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

  // Görevi sil
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aktif Görevler (Admin Onayı)',
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
                    'Sisteme kayıtlı aktif görev bulunamadı.',
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
                                    if (status == 'completed') ...[
                                      IconButton(
                                        icon: const Icon(Icons.replay),
                                        color: Colors.redAccent,
                                        tooltip: 'Revize İste',
                                        iconSize: 20,
                                        onPressed: () {
                                          _showRequestRevisionDialog(
                                            context,
                                            taskId,
                                            taskTitle,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.archive_outlined),
                                        color: Colors.green,
                                        tooltip: 'Onayla ve Arşivle',
                                        iconSize: 20,
                                        onPressed: () {
                                          _showArchiveConfirmationDialog(
                                            context,
                                            taskId,
                                            taskTitle,
                                          );
                                        },
                                      ),
                                    ]
                                    else ...[
                                      IconButton(
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
                                      IconButton(
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