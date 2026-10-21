import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';

// Trang User: khung chua 3 tab (Trang chu / Marketplace / Tai khoan).
// IndexedStack giu nguyen trang thai tung tab -> doi tab khong tai lai.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _marketplaceTab = 1;

  int _currentTab = 0;
  // GlobalKey de goi applyFilter cua tab Marketplace tu tab Trang chu.
  final _marketplaceKey = GlobalKey<MarketplaceScreenState>();

  // Chuyen sang tab Marketplace kem bo loc (UP14 dung khi bam danh muc / tim kiem).
  void openMarketplace({String? query, int? categoryId}) {
    setState(() => _currentTab = _marketplaceTab);
    _marketplaceKey.currentState
        ?.applyFilter(query: query, categoryId: categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeScreen(onOpenMarketplace: openMarketplace),
          MarketplaceScreen(key: _marketplaceKey),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(
              icon: Icon(Icons.storefront), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
