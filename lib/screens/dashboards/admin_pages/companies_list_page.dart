import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gorev_takip_app_web/widgets/edit_company_dialog.dart';

class CompaniesListPage extends StatelessWidget {
  const CompaniesListPage({super.key});

  // Firmaları getiren akış
  Stream<QuerySnapshot> _getCompaniesStream() {
    return FirebaseFirestore.instance
        .collection('companies')
        .orderBy('name') // İsime göre sırala
        .snapshots();
  }

  // Silme onayı diyaloğu
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context,
      String companyId,
      String companyName,
      ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Firmayı Sil'),
          content: Text('"$companyName" adlı firmayı silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Sil'),
              onPressed: () {
                _deleteCompany(companyId, companyName, context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Silme işlemi
  Future<void> _deleteCompany(
      String companyId,
      String companyName,
      BuildContext context,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('companies').doc(companyId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$companyName" başarıyla silindi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: Firma silinemedi. $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Düzenleme diyaloğunu göster
  Future<void> _showEditCompanyDialog(
      BuildContext context,
      String companyId,
      String currentName,
      ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditCompanyDialog(companyId: companyId, currentName: currentName);
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
            'Kayıtlı Firmalar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getCompaniesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Henüz kayıtlı bir firma yok.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final companies = snapshot.data!.docs;

              return ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final companyData = companies[index].data() as Map<String, dynamic>;
                  final companyId = companies[index].id;
                  final String companyName = companyData['name'] ?? 'İsimsiz Firma';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigoAccent,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(
                        companyName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: Colors.blueGrey,
                            tooltip: 'Firmayı Düzenle',
                            onPressed: () {
                              _showEditCompanyDialog(context, companyId, companyName);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent,
                            tooltip: 'Firmayı Sil',
                            onPressed: () {
                              _showDeleteConfirmationDialog(context, companyId, companyName);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}