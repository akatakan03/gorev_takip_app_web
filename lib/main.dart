import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Artık AuthGate'i buradan import ediyoruz
import 'package:gorev_takip_app_web/screens/auth/auth_gate.dart';

// --- Firebase Yapılandırması (Sizin sağladığınız bilgilerle) ---
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
  // Flutter binding'lerini başlat
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase'i sağlanan opsiyonlarla başlat
  await Firebase.initializeApp(
    options: firebaseOptions,
  );
  // Uygulamayı çalıştır
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Görev Takip Uygulaması',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark, // Koyu tema
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Debug etiketini kaldır
      // Ana ekran olarak AuthGate'i (kimlik kapısını) belirle
      home: const AuthGate(),
    );
  }
}