import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Parcel" wordmark with the "cel" in orange, optionally with the van icon.
class ParcelLogo extends StatelessWidget {
  const ParcelLogo({super.key, this.size = 18, this.showIcon = true});

  final double size;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(Icons.local_shipping_rounded,
              color: AppColors.orange, size: size * 1.25),
          SizedBox(width: size * 0.35),
        ],
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.ink,
            ),
            children: const [
              TextSpan(text: 'Par'),
              TextSpan(text: 'cel', style: TextStyle(color: AppColors.orange)),
            ],
          ),
        ),
      ],
    );
  }
}
