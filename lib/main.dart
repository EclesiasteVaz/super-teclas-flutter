import 'package:flutter/material.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';

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
      scrollBehavior: const ScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color.fromARGB(255, 3, 73, 131)),
        useMaterial3: true,
        elevatedButtonTheme: const ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStatePropertyAll(
              Size(120, 40),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
