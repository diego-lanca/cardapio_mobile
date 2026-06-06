import 'package:cardapio_mobile/pages/admin_page.dart';
import 'package:cardapio_mobile/pages/login_page.dart';
import 'package:cardapio_mobile/pages/main_page.dart';
import 'package:cardapio_mobile/pages/forgot_password_page.dart';
import 'package:cardapio_mobile/pages/register_page.dart';
import 'package:cardapio_mobile/providers/auth_provider.dart';
import 'package:cardapio_mobile/providers/cart_provider.dart';
import 'package:cardapio_mobile/providers/menu_provider.dart';
import 'package:cardapio_mobile/providers/order_provider.dart';
import 'package:cardapio_mobile/services/api_service.dart';
import 'package:cardapio_mobile/services/local_storage_service.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final storageService = LocalStorageService();
  final apiService = ApiService(storageService);

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) =>
          MainApp(storageService: storageService, apiService: apiService),
    ),
  );
}

class MainApp extends StatelessWidget {
  final LocalStorageService storageService;
  final ApiService apiService;

  const MainApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            storageService: storageService,
            apiService: apiService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider(apiService)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'Cardápio App',
        initialRoute: '/login',
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/admin': (context) => const AdminPage(),
          '/main': (context) => const MainPage(),
        },
      ),
    );
  }
}
