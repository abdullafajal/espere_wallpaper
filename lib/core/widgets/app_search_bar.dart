import 'package:flutter/material.dart';

/// Pill-shaped search field in the style of a gallery app's search bar:
/// tonal fill, no outline, leading search/back icon, trailing clear and
/// filter actions.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool readOnly;
  final bool hasActiveFilters;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search wallpapers',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.onFilterTap,
    this.onBack,
    this.trailing,
    this.readOnly = false,
    this.hasActiveFilters = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
              onPressed: onBack,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
          if (controller != null && onClear != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear',
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    ),
            ),
          if (onFilterTap != null)
            IconButton(
              tooltip: 'Filters',
              onPressed: onFilterTap,
              icon: Badge(
                isLabelVisible: hasActiveFilters,
                backgroundColor: cs.secondary,
                smallSize: 8,
                child: Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilters ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ?trailing,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
