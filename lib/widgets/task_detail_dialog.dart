import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/get_user_name.dart';
// --- YENİ IMPORT: Firma Adı Getirici ---
import 'package:gorev_takip_app_web/widgets/get_company_name.dart';
import 'package:intl/intl.dart';

class TaskDetailDialog extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final String taskId;

  const TaskDetailDialog({
    super.key,
    required this.taskData,
    required this.taskId,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orangeAccent;
      case 'in_progress': return Colors.blueAccent;
      case 'completed': return Colors.green;
      case 'needs_revision': return Colors.redAccent;
      case 'archived': return Colors.grey[700]!;
      default: return Colors.grey;
    }
  }

  String _getTurkishStatus(String status) {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'in_progress': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandı';
      case 'needs_revision': return 'Revize Gerekli';
      case 'archived': return 'Arşivlendi';
      default: return 'Bilinmiyor';
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final String title = taskData['title'] ?? 'Başlıksız Görev';
    final String status = taskData['status'] ?? 'unknown';
    final String description = taskData['description']?.isEmpty ?? true
        ? "Bu görev için açıklama girilmemiş."
        : taskData['description'];
    final String? revisionNote = taskData['revision_note'];
    final String assignedToId = taskData['assignedTo'] ?? '';
    final String createdById = taskData['createdBy'] ?? '';
    final String companyId = taskData['companyId'] ?? ''; // --- YENİ: Firma ID'si ---
    final Timestamp? createdAt = taskData['createdAt'];
    final Timestamp? completedAt = taskData['completedAt'];

    return AlertDialog(
      titlePadding: const EdgeInsets.all(20.0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      title: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), splashRadius: 20),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              // Durum Etiketi
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    _getTurkishStatus(status).toUpperCase(),
                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const Divider(height: 24),

              // Açıklama
              const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 15, color: Colors.grey[300], fontStyle: taskData['description']?.isEmpty ?? true ? FontStyle.italic : FontStyle.normal),
              ),

              // Revizyon Notu
              if (revisionNote != null && revisionNote.isNotEmpty) ...[
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.redAccent)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text("Admin (Yönetici) Revizyon Notu:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(revisionNote, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24),

              // Detaylar
              const Text('Detaylar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              // --- YENİ: Firma Bilgisi ---
              _buildDetailItem(
                Icons.business,
                "Firma",
                GetCompanyName(companyId: companyId),
              ),
              // ---------------------------

              _buildDetailItem(
                Icons.person_outline,
                "Atanan Kişi",
                GetUserName(userId: assignedToId),
              ),
              _buildDetailItem(
                Icons.admin_panel_settings_outlined,
                "Atayan Kişi (Admin)",
                GetUserName(userId: createdById),
              ),
              _buildDetailItem(
                Icons.calendar_today_outlined,
                "Oluşturulma Tarihi",
                Text(_formatTimestamp(createdAt)),
              ),
              if (completedAt != null)
                _buildDetailItem(
                  Icons.check_circle_outline,
                  "Tamamlanma Tarihi",
                  Text(_formatTimestamp(completedAt)),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(child: const Text('Kapat'), onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  child: valueWidget,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}