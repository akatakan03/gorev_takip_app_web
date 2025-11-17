import 'package:flutter/material.dart';

// Firebase'i başlatmak için çekirdek (core) paketi
import 'package:firebase_core/firebase_core.dart';

// --- ÖNEMLİ BİLGİLENDİRME ---
// Bu 'firebaseOptions' değişkenini, Adım 3'te Firebase konsolundan
// aldığınız 'firebaseConfig' bilgileriyle DOLDURMANIZ GEREKİYOR.
// FlutterFire, web projelerinde bu yapılandırmayı manuel olarak ister.
// ---

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDn5c3nzB5pB-H-iDDL6ZhG1aDQHRXAVQc",
  authDomain: "gorev-takip-76c3a.firebaseapp.com",
  projectId: "gorev-takip-76c3a",
  storageBucket: "gorev-takip-76c3a.firebasestorage.app",
  messagingSenderId: "561539134953",
  appId: "1:561539134953:web:8bcfde24bafb9895bd0778",
  measurementId: "G-6ZKC0RZ9XF", // Bu bazen olmayabilir, o zaman bu satırı silebilirsiniz.
);

void main() async {
  // Flutter uygulamasının başlatılabilmesi için "binding"lerin hazır olduğundan emin ol.
  // Bu, özellikle main içinde 'await' kullanıyorsak gereklidir.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i web için özel ayarlarımızla başlatıyoruz.
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
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Takip (Web)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.indigoAccent),
            const SizedBox(height: 20),
            const Text(
              'Flutter & Firebase Web Kurulumu Başarılı!',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Firebase Proje ID: ${firebaseOptions.projectId}', // Sadece test amaçlı
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}