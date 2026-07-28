import 'package:flutter/material.dart';

class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.image,
    required this.radius,
    required this.backgroundColor,
    required this.iconColor,
  });

  static const _imageBaseUrl =
      'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_user/';

  final String image;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;

  String get _imageUrl => image.startsWith('http')
      ? image
      : '$_imageBaseUrl${Uri.encodeComponent(image)}';

  Widget _fallback() {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Icon(
          Icons.person,
          size: radius,
          color: iconColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: image.trim().isEmpty
            ? _fallback()
            : Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );
  }
}
