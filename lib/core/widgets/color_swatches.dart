import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Round colour swatch with an optional check mark.
class ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool selected;

  const ColorDot({
    super.key,
    required this.color,
    this.size = 56,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      padding: EdgeInsets.all(selected ? 3 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: selected
            ? Icon(Icons.check_rounded, color: onColor, size: size * 0.4)
            : null,
      ),
    );
  }
}

/// Horizontally scrolling row of labelled colour circles.
class ColorSwatchRow extends StatelessWidget {
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;
  final double dotSize;
  final EdgeInsetsGeometry padding;

  const ColorSwatchRow({
    super.key,
    required this.onSelected,
    this.selectedSlug,
    this.dotSize = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.searchColors;

    return SizedBox(
      height: dotSize + 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: colors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = colors[index];
          final selected = selectedSlug == item.slug;
          return Semantics(
            button: true,
            selected: selected,
            label: '${item.name} color',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(selected ? null : item.slug),
              child: SizedBox(
                width: dotSize + 4,
                child: Column(
                  children: [
                    ColorDot(
                      color: item.color,
                      size: dotSize,
                      selected: selected,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
