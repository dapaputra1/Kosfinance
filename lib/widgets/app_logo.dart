import 'package:flutter/material.dart';
import 'package:kos_finance_app/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF33706A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.52,
            color: Colors.white,
          ),
          Positioned(
            right: size * 0.22,
            top: size * 0.24,
            child: Container(
              width: size * 0.20,
              height: size * 0.20,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryDark, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
