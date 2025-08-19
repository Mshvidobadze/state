import 'package:flutter/material.dart';
import 'package:state/core/widgets/shimmer.dart';

class PostTileSkeleton extends StatelessWidget {
  const PostTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Avatar skeleton
                    Shimmer(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Author info skeleton
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer(
                          child: Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Shimmer(
                          child: Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Follow button skeleton
                Shimmer(
                  child: Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Shimmer(
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Shimmer(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Image skeleton (optional, shown 50% of the time)
          if (_shouldShowImage())
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Shimmer(
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.white,
                ),
              ),
            ),
          // Actions skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildActionSkeleton(),
                const SizedBox(width: 24),
                _buildActionSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSkeleton() {
    return Row(
      children: [
        Shimmer(
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Shimmer(
          child: Container(
            width: 40,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowImage() {
    // Randomly show image skeleton 50% of the time
    return DateTime.now().millisecondsSinceEpoch % 2 == 0;
  }
}
