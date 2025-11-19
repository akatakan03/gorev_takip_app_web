import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gorev_takip_app_web/screens/auth/auth_gate.dart';
// --- ÖNEMLİ: intl paketinin yerelleştirme verilerini yüklemek için gerekli import ---
import 'package:intl/date_symbol_data_local.dart';
// --------------------------------------------------

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDn5c3nzB5pB-H-iDDL6ZhG1aDQHRXAVQc",
  authDomain: "gorev-takip-76c3a.firebaseapp.com",
  projectId: "gorev-takip-76c3a",
  storageBucket: "gorev-takip-76c3a.firebasestorage.app",
  messagingSenderId: "561539134953",
  appId: "1:561539134953:web:8bcfde24bafb9895bd0778",
  measurementId: "G-6ZKC0RZ9XF",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  // --- DÜZELTME BURADA ---
  // Türkçe tarih formatı (tr_TR) için gerekli verileri başlatıyoruz.
  // Bu satır olmadan DateFormat('...', 'tr_TR') hata verir.
  // 'null' parametresini geçmek, varsayılan olarak gerekli verileri yükler.
  await initializeDateFormatting('tr_TR', null);
  // -----------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Görev Takip',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}