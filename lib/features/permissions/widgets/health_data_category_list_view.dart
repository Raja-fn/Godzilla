import 'package:flutter/material.dart';
import 'package:health_connector/health_connector.dart';

/// [HealthDataTypeCategory].
///
class HealthDataCategoryListView<T> extends StatelessWidget {
  const HealthDataCategoryListView({
    required this.groupedItems,
    required this.itemBuilder,
    super.key,
    this.itemSorter,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  });

  /// The items to display, grouped by category.
  final Map<HealthDataTypeCategory, List<T>> groupedItems;

  /// Builder for individual list items.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Optional comparator to sort items within each category.
  final int Function(T a, T b)? itemSorter;

  /// Scroll physics for the list.
  final ScrollPhysics? physics;

  /// Whether the list should shrink wrap its content.
  final bool shrinkWrap;

  /// Padding for the list.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (groupedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No data types found',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Sort categories by display name
    final sortedCategories = groupedItems.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    return ListView.builder(
      padding: padding ?? EdgeInsets.zero,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final items = groupedItems[category]!;

        // Sort items if a sorter is provided
        if (itemSorter != null) {
          items.sort(itemSorter);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryHeader(context, category),
            const SizedBox(height: 8),
            ...items.map((item) => itemBuilder(context, item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context,
    HealthDataTypeCategory category,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            category.toString().split('.').last,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
