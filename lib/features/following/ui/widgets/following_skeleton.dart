import 'package:flutter/material.dart';
import 'package:state/features/home/ui/widgets/post_tile_skeleton.dart';

class FollowingSkeleton extends StatelessWidget {
  const FollowingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 3, // Show 3 skeleton items
      itemBuilder: (context, index) {
        return const PostTileSkeleton();
      },
    );
  }
}
