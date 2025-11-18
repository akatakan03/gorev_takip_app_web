import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Bu widget (bileşen), bir 'companyId' (firma kimliği) alır ve
// veritabanından o firmanın adını çeker.
class GetCompanyName extends StatelessWidget {
  final String companyId;
  final TextStyle? style;

  const GetCompanyName({super.key, required this.companyId, this.style});

  @override
  Widget build(BuildContext context) {
    if (companyId.isEmpty) {
      return Text(
        "Firma Belirtilmemiş",
        style: style?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey) ??
            const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    Future<DocumentSnapshot> companyDoc =
    FirebaseFirestore.instance.collection('companies').doc(companyId).get();

    return FutureBuilder<DocumentSnapshot>(
      future: companyDoc,
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Hata", style: style?.copyWith(color: Colors.redAccent));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          return Text(
            data['name'] ?? 'İsimsiz Firma',
            style: style,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return Text(
          "Bilinmeyen Firma",
          style: style?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey),
        );
      },
    );
  }
}