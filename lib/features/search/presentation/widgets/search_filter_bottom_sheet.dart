import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/color_swatches.dart';
import '../../domain/search_filter.dart';

/// Bottom sheet with orientation, size and colour filters.
class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilter currentFilter;
  final ValueChanged<SearchFilter> onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required SearchFilter currentFilter,
    required ValueChanged<SearchFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SearchFilterBottomSheet(
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

String _label(String value) =>
    value == 'all' ? 'Any' : value[0].toUpperCase() + value.substring(1);

const Map<String, IconData> _orientationIcons = {
  'all': Icons.crop_free_rounded,
  'landscape': Icons.crop_landscape_rounded,
  'portrait': Icons.crop_portrait_rounded,
  'square': Icons.crop_square_rounded,
};

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late String? _color = widget.currentFilter.color;
  late String _orientation = widget.currentFilter.orientation;
  late String _size = widget.currentFilter.size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Filters', style: theme.textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _color = null;
                      _orientation = 'all';
                      _size = 'all';
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            sectionTitle('Orientation'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.orientations.map((o) {
                  return ChoiceChip(
                    label: Text(_label(o)),
                    avatar: Icon(_orientationIcons[o], size: 18),
                    showCheckmark: false,
                    selected: _orientation == o,
                    onSelected: (_) => setState(() => _orientation = o),
                  );
                }).toList(),
              ),
            ),
            sectionTitle('Size'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.imageSizes.map((s) {
                  return ChoiceChip(
                    label: Text(_label(s)),
                    selected: _size == s,
                    onSelected: (_) => setState(() => _size = s),
                  );
                }).toList(),
              ),
            ),
            sectionTitle('Color'),
            ColorSwatchRow(
              dotSize: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              selectedSlug: _color,
              onSelected: (slug) => setState(() => _color = slug),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(
                      widget.currentFilter.copyWith(
                        color: _color,
                        clearColor: _color == null,
                        orientation: _orientation,
                        size: _size,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Show results'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
