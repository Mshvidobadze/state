import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:state/features/home/data/models/post_model.dart';

class ShareService {
  static const String _webBaseUrl = 'https://stateapp.net';

  Future<void> sharePost(BuildContext context, PostModel post) async {
    try {
      final shareUrl = '$_webBaseUrl/post/${post.id}';

      // On iPad, share sheet requires a non-zero source rect within a valid view.
      final renderObject = context.findRenderObject();
      Rect? origin;
      if (renderObject is RenderBox) {
        final box = renderObject;
        final offset = box.localToGlobal(Offset.zero);
        if (box.size.width > 0 && box.size.height > 0) {
          origin = offset & box.size;
        }
      }

      await Share.share(
        shareUrl,
        subject: 'Check out this post on State',
        sharePositionOrigin: origin ?? const Rect.fromLTWH(100, 100, 200, 200),
      );
    } catch (e) {
      print('Error sharing post: $e');
    }
  }
}
