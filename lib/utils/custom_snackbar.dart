import 'package:flutter/material.dart';

enum NotificationType { success, error, info }

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required NotificationType type,
  }) {
    final cs = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;
    IconData iconData;
    String title;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        title = 'Başarılı';
        break;
      case NotificationType.error:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        iconData = Icons.error_rounded;
        title = 'Hata';
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade600;
        iconData = Icons.info_rounded;
        title = 'Bilgi';
        break;
    }

    // Gece modundaysak arka plan renklerini biraz daha koyu/uyumlu yapalım
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      if (type == NotificationType.success) {
        backgroundColor = Colors.green.shade900.withValues(alpha: 0.4);
      }
      if (type == NotificationType.error) {
        backgroundColor = Colors.red.shade900.withValues(alpha: 0.4);
      }
      if (type == NotificationType.info) {
        backgroundColor = Colors.blue.shade900.withValues(alpha: 0.4);
      }
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
