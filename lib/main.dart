import 'package:flutter/material.dart';
import 'pages/scan_book_page.dart';
import 'pages/storage_page.dart';
import 'services/voice_command_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _voiceCommandService = VoiceCommandService();

  @override
  void initState() {
    super.initState();
    // Initialize the service but don't start listening
    _voiceCommandService.initialize();
    // Set up navigation to storage page for "lihat hasil" command
    _setupVoiceCommands();
  }

  void _setupVoiceCommands() {
    _voiceCommandService.onViewResults = () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StoragePage()),
        );
      }
    };
  }

  @override
  void dispose() {
    _voiceCommandService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mudah Membaca',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: 1.2,
          fontSizeDelta: 2.0,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Mudah Membaca',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                semanticsLabel: 'Judul Aplikasi Mudah Membaca',
              ),
            ),
            const Text(
              'Aplikasi pembaca buku untuk tuna netra',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              semanticsLabel: 'Deskripsi aplikasi pembaca buku untuk tuna netra',
            ),
            const SizedBox(height: 50),
            // Tombol MULAI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('Navigating to ScanBookPage');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanBookPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'MULAI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Tombol PENYIMPANAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoragePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'PENYIMPANAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
