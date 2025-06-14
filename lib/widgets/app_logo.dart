import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet,
          size: size * 0.6,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }
}
