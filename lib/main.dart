import 'package:flutter/material.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';

class LocaleProvider extends InheritedWidget {
  const LocaleProvider({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  static LocaleProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProvider>()!;
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) {
    return locale != oldWidget.locale;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = _detectLocale();

  static Locale _detectLocale() {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (platformLocale.languageCode == 'pt') return const Locale('pt');
    return const Locale('en');
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      onLocaleChanged: _setLocale,
      child: MaterialApp(
        locale: _locale,
        title: 'Super Teclas',
        supportedLocales: const [Locale('en'), Locale('pt')],
        debugShowCheckedModeBanner: false,
        scrollBehavior: const ScrollBehavior(),
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color.fromARGB(255, 3, 73, 131),
          ),
          useMaterial3: true,
          elevatedButtonTheme: const ElevatedButtonThemeData(
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(180, 48)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
