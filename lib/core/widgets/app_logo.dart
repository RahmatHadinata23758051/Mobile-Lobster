import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modular App Logo Widget
/// Allows easy customization and replacement when client provides custom logo asset/image.
class AppLogo extends StatelessWidget {
  final double size;
  final String? assetPath;
  final bool showText;
  final double fontSize;

  const AppLogo({
    super.key,
    this.size = 56.0,
    this.assetPath, // Provide asset image path here when client logo is ready (e.g. 'assets/images/logo.png')
    this.showText = true,
    this.fontSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assetPath != null)
          Image.asset(
            assetPath!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          )
        else
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.water_drop,
                size: size * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'Lobsense Mobile',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sistem Monitoring & Kontrol Tambak Lobster',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
