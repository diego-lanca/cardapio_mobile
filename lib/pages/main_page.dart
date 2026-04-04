import 'package:cardapio_mobile/pages/about_page.dart';
import 'package:cardapio_mobile/pages/cart_page.dart';
import 'package:cardapio_mobile/pages/menu_page.dart';
import 'package:cardapio_mobile/pages/profile_page.dart';
import 'package:cardapio_mobile/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MenuPage(),
    CartPage(),
    AboutPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final totalItems = context.select<CartProvider, int>(
      (provider) => provider.totalItems,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE53935),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: const Color(0xFFE53935),
                child: SafeArea(
                  bottom: false,
                  child: const _TopNavigationBar(),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF6F6F6),
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 16,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            height: 72,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0xFFE53935).withOpacity(0.12),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Cardápio',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: totalItems > 0,
                  label: Text('$totalItems'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: totalItems > 0,
                  label: Text('$totalItems'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Carrinho',
              ),
              const NavigationDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: 'Sobre',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNavigationBar extends StatelessWidget {
  const _TopNavigationBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border(bottom: BorderSide(color: Colors.red.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFFDDDCDC),
            ),
          ),
          const Expanded(
            child: Text(
              'Rotisseria do Mércio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDDDCDC),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Color(0xFFDDDCDC)),
          ),
        ],
      ),
    );
  }
}
