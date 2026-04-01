import 'package:cardapio_mobile/pages/register_page.dart';
import 'package:cardapio_mobile/providers/auth_provider.dart';
import 'package:cardapio_mobile/services/local_storage_service.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(storageService: LocalStorageService()),
        ),
      ],
      child: MaterialApp(
        title: 'Cardápio App',
        initialRoute: '/register',
        debugShowCheckedModeBanner: false,
        routes: {
          '/register': (context) => const RegisterPage(),
          // '/login': (context) => const LoginPage(),
          // '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
