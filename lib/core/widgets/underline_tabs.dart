import 'package:flutter/material.dart';

/// Horizontal text tabs with an animated underline (Pinterest style).
class UnderlineTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (var i = 0; i < labels.length; i++)
        _UnderlineTab(
          label: labels[i],
          selected: i == selected,
          onTap: () => onSelect(i),
        ),
    ];
    return SizedBox(
      height: 52,
      child: scrollable
          ? ListView(
              scrollDirection: Axis.horizontal,
              padding: padding,
              children: tabs,
            )
          : Padding(
              padding: padding,
              child: Row(children: tabs),
            ),
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnderlineTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: theme.textTheme.titleMedium!.copyWith(
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.onSurface : cs.onSurfaceVariant,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 3,
                width: selected ? 28 : 0,
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
