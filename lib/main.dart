import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Home.dart';
import 'firebase_options.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((value) {
    print("Firebase initialized successfully");
  }).catchError((error) {
    print("Firebase initialization error: $error");
  });
  await _createWallpaperDirectory();
  final prefs = await SharedPreferences.getInstance();
  final darkModeOn = prefs.getBool('darkMode') ?? false;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(darkModeOn ? darkTheme : lightTheme),
      child: const MyApp(),
    ),
  );
}

Future<Directory> _createWallpaperDirectory() async {
  try {
    final baseDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDir.path}/Poster');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  } catch (e) {
    print('Error creating directory: $e');
    return await getTemporaryDirectory();
  }
}