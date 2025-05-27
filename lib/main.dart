import 'package:flutter/material.dart';
import 'package:notes_demo_project/screens/splash_screen.dart';
import 'package:notes_demo_project/services/notification_service.dart';
import 'package:notes_demo_project/services/sharedPref.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initNotification();

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData theme = appThemeLight;

  @override
  void initState() {
    super.initState();
    updateThemeFromSharedPref();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(changeTheme: setTheme),
    );
  }

  void setTheme(Brightness brightness) {
    setState(() {
      theme = brightness == Brightness.dark ? appThemeDark : appThemeLight;
    });
  }

  void updateThemeFromSharedPref() async {
    final themeText = await getThemeFromSharedPref();
    if (themeText == 'light') {
      setTheme(Brightness.light);
    } else {
      setTheme(Brightness.dark);
    }
  }
}
