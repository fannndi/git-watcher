import 'package:flutter/material.dart';

class SliverDateHeader extends StatelessWidget {
  const SliverDateHeader({super.key, required this.label});

  final String label;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      color: colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class SliverDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  SliverDateHeaderDelegate(this.label);

  final String label;

  @override
  double get minExtent => SliverDateHeader.height;

  @override
  double get maxExtent => SliverDateHeader.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SliverDateHeader(label: label);
  }

  @override
  bool shouldRebuild(covariant SliverDateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label;
  }
}
