import 'package:flutter/material.dart';
import 'package:super_teclas/pages/home_page.dart';
import 'package:super_teclas/shared/themes/theme_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Teclas',
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: themeApp,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
