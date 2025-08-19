import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostOptionsBottomSheet extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback onReport;

  const PostOptionsBottomSheet({
    required this.isFollowing,
    required this.onFollowToggle,
    required this.onReport,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Post Options',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // Options list
          _buildOptionItem(
            icon: isFollowing ? Icons.bookmark : Icons.bookmark_border,
            title: isFollowing ? 'Unfollow' : 'Follow',
            onTap: () {
              onFollowToggle();
              Navigator.pop(context);
            },
          ),
          _buildOptionItem(
            icon: Icons.flag_outlined,
            title: 'Report',
            onTap: () {
              onReport();
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
