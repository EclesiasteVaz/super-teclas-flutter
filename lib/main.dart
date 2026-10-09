import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_teclas/src/config/env.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load();

  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  }

  await SharedPreferences.getInstance();

  await WordBank.load(languageCode: 'pt');

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
    return MaterialApp(
      locale: _locale,
      title: 'Super Teclas',
      supportedLocales: const [Locale('en'), Locale('pt')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.primary,
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
      builder: (context, child) => LocaleProvider(
        locale: _locale,
        onLocaleChanged: _setLocale,
        child: child!,
      ),
      home: const HomePage(),
    );
  }
}
