import 'package:flutter/material.dart';

final Color primaryColor = const Color.fromARGB(255, 58, 149, 255);
final Color reallyLightGrey = Colors.grey.withAlpha(25);

final ThemeData appThemeLight = ThemeData(
    colorScheme: ColorScheme.light(
        primary: primaryColor,
    ),
    useMaterial3: true,
);

final ThemeData appThemeDark = ThemeData(
    colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: primaryColor,
    ),
    switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(primaryColor),
        trackColor: MaterialStateProperty.all(primaryColor.withOpacity(0.5)),
    ),
    checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
    ),
    radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(primaryColor),
    ),
    useMaterial3: true,
);
