import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar reutilizable (RF03). Muestra la foto del usuario si existe; si no,
/// la inicial de su nombre como respaldo.
///
/// La foto se guarda en `AppUser.photoUrl` como un data URI base64
/// (`data:image/jpeg;base64,...`) para no depender de un backend de archivos;
/// también admite URLs remotas normales.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Construye el [ImageProvider] adecuado para un `photoUrl`, o `null` si no hay.
  static ImageProvider? providerFor(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    const marker = 'base64,';
    if (photoUrl.startsWith('data:')) {
      final i = photoUrl.indexOf(marker);
      if (i >= 0) {
        try {
          return MemoryImage(base64Decode(photoUrl.substring(i + marker.length)));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final img = providerFor(photoUrl);
    final inicial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primaryLight,
      backgroundImage: img,
      child: img == null
          ? Text(
              inicial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: foregroundColor ?? AppColors.primary,
              ),
            )
          : null,
    );
  }
}
