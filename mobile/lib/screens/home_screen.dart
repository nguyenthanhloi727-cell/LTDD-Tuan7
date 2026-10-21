import 'package:flutter/material.dart';

// Tab Trang chu cua trang User (UP12 tam ban don gian, UP14 lam day du).
// onOpenMarketplace: MainScreen truyen vao de chuyen sang tab Marketplace.
class HomeScreen extends StatelessWidget {
  final void Function({String? query, int? categoryId}) onOpenMarketplace;

  const HomeScreen({super.key, required this.onOpenMarketplace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Chào mừng đến Smart Auth',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => onOpenMarketplace(),
                icon: const Icon(Icons.storefront),
                label: const Text('Xem Marketplace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
