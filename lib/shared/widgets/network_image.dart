import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover, this.radius = 12});
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (c, _) => Container(color: Theme.of(c).colorScheme.surfaceContainerHighest),
        errorWidget: (c, _, __) => Container(
          color: Theme.of(c).colorScheme.errorContainer,
          child: const Icon(Icons.broken_image_rounded),
        ),
      ),
    );
  }
}
