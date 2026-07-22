import 'package:flutter/material.dart';
import 'package:muntum/constants/colors.dart';

class CurrentLocationPinIcon extends StatelessWidget {
  const CurrentLocationPinIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2F80ED),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.22),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
