import 'package:cardapio_mobile/pages/register_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cardápio App',
      initialRoute: '/register',
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => const RegisterPage(),
        // '/login': (context) => const LoginPage(),
        // '/home': (context) => const HomePage(),
      },
    );
  }
}
