import 'package:flutter/material.dart';

// Hien so luong: 0 -> chu do "Het hang", nguoc lai "Con: n".
class StockText extends StatelessWidget {
  final int quantity;

  const StockText(this.quantity, {super.key});

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return const Text(
        'Hết hàng',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    return Text('Còn: $quantity');
  }
}
