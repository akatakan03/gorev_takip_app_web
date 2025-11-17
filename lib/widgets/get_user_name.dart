import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Bu widget (bileşen), bir 'userId' (kullanıcı kimliği) alır ve
// veritabanından o kullanıcının adını çeker.
class GetUserName extends StatelessWidget {
  final String userId;
  final TextStyle? style; // Opsiyonel stil parametresi

  const GetUserName({super.key, required this.userId, this.style});

  @override
  Widget build(BuildContext context) {
    // --- GÜNCELLEME: BOŞ ID KONTROLÜ ---
    // Eğer 'userId' (kullanıcı kimliği) 'null' (boş) veya 'empty' (içi boş)
    // gelirse, veritabanına hiç gitme, doğrudan "Atanmamış" yaz.
    if (userId.isEmpty) {
      return Text(
        "Atanmamış",
        style: style?.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ) ??
            const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
      );
    }
    // ------------------------------------

    // 'userId' (kullanıcı kimliği) geçerliyse, 'users' (kullanıcılar)
    // koleksiyonundan dokümanı çek.
    Future<DocumentSnapshot> userDoc =
    FirebaseFirestore.instance.collection('users').doc(userId).get();

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc, // Dinlenecek 'future' (gelecek)
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {

        // 1. Hata varsa
        if (snapshot.hasError) {
          return Text(
            "Hata",
            style: style?.copyWith(color: Colors.redAccent) ??
                const TextStyle(color: Colors.redAccent),
          );
        }

        // 2. Veri geldiyse ve doküman mevcutsa
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
          snapshot.data!.data() as Map<String, dynamic>;

          return Text(
            data['name'] ?? 'İsimsiz', // 'name' (isim) alanı yoksa 'İsimsiz' yaz
            style: style,
          );
        }

        // 3. Veri bekleniyorsa (yükleniyorsa)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // 4. Diğer tüm durumlarda (örn: kullanıcı silinmişse)
        return Text(
          "Bilinmeyen Kullanıcı",
          style: style?.copyWith(fontStyle: FontStyle.italic) ??
              const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        );
      },
    );
  }
}