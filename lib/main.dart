import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unshelf_buyer/home_view.dart';
import 'package:unshelf_buyer/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: "1:733152787617:android:3c3e7b87d0cb7c59f544e0",
      messagingSenderId: "733152787617",
      projectId: "unshelf-d4567",
      storageBucket: "unshelf-d4567.appspot.com",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unshelf',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF386641)),
        useMaterial3: true,
        textTheme:
            GoogleFonts.jostTextTheme(Theme.of(context).textTheme).apply(bodyColor: const Color.fromARGB(255, 56, 102, 65)),
      ),
      home: FirebaseAuth.instance.currentUser != null ? HomeView() : LoginView(),
    );
  }
}
