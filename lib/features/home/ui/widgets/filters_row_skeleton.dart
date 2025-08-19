import 'package:flutter/material.dart';
import 'package:state/core/widgets/shimmer.dart';

class FiltersRowSkeleton extends StatelessWidget {
  const FiltersRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Region dropdown skeleton
          Shimmer(
            child: Container(
              width: 120,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort dropdown skeleton
          Shimmer(
            child: Container(
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const Spacer(),
          // Create post button skeleton
          Shimmer(
            child: Container(
              width: 100,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
