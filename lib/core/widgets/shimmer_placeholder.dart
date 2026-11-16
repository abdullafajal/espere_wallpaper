import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Subtle loading placeholder tinted from the current colour scheme.
class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool circle;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 0,
  }) : circle = false;

  const ShimmerPlaceholder.circular({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = 0,
      circle = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerLow,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
