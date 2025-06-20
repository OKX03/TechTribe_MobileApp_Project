import 'package:flutter/material.dart';
import 'package:memorime_v1/screens/friends/friends_main_page.dart';
import 'package:memorime_v1/screens/memory/memory_main_page.dart';
import 'package:memorime_v1/screens/timeline/timeline_main_page.dart';
import 'screens/auth/login.dart';
import 'screens/auth/register.dart';
import 'screens/auth/forgot_password.dart';
import 'screens/home/home.dart';
import 'screens/admin/admin_home.dart';
import 'screens/capsule/create_time_capsule.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void showSuccessMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void showErrorMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memorime',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),

      localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // You can add more locales if needed
      ],

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/admin_home': (context) => const AdminHomePage(),
        '/create_capsule': (context) => const CreateTimeCapsulePage(),
        '/friends': (context) => const FriendsMainPage(),
        '/timeline': (context) => const TimelineMainPage(),
        '/memory': (context) => const MemoryMainPage(),
        
      },
    );
  }
}
