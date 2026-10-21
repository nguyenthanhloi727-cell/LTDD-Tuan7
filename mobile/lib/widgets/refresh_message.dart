import 'package:flutter/material.dart';

// Thong bao (loi / danh sach rong) dat trong ListView cuon duoc,
// de RefreshIndicator ben ngoai van keo xuong tai lai duoc.
class RefreshMessage extends StatelessWidget {
  final String text;

  const RefreshMessage(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(text, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
