import 'package:flutter/material.dart';

import '../../core/constants.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
  });

  /// 0-5, where 0 means "not rated".
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 5);
    final filledColor = FoodHubConstants.brandSecondary;
    final emptyColor = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            tooltip: onChanged == null ? null : 'Rate $i',
            onPressed: onChanged == null ? null : () => onChanged!(i),
            icon: Icon(
              i <= clamped ? Icons.star_rounded : Icons.star_border_rounded,
              color: i <= clamped ? filledColor : emptyColor,
            ),
          ),
      ],
    );
  }
}
