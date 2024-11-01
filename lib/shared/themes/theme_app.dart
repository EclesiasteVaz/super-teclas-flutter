import 'package:flutter/material.dart';

ThemeData themeApp = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color.fromARGB(255, 7, 143, 255)),
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
);
