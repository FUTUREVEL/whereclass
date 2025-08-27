import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.light(
    primary: Color.fromARGB(255, 83, 132, 255),
    secondary: Color.fromARGB(255, 83, 132, 255),
    background: Colors.white,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.black,
    onSurface: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.black),
    titleLarge: TextStyle(color: Colors.black),
    titleMedium: TextStyle(color: Colors.black),
    titleSmall: TextStyle(color: Colors.black),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Color.fromARGB(255, 83, 132, 255)),
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 83, 132, 255)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 83, 132, 255)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 83, 132, 255), width: 2),
    ),
    labelStyle: TextStyle(color: Color.fromARGB(255, 83, 132, 255)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(const Color.fromARGB(255, 83, 132, 255)),
      foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
      textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(fontWeight: FontWeight.bold)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll<Color>(Color.fromARGB(255, 83, 132, 255)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStatePropertyAll<Color>(Color.fromARGB(255, 83, 132, 255)),
      side: MaterialStatePropertyAll<BorderSide>(BorderSide(color: Color.fromARGB(255, 83, 132, 255))),
    ),
  ),
  iconTheme: const IconThemeData(color: Color.fromARGB(255, 83, 132, 255)),
);
