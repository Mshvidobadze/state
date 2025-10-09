import 'package:share_plus/share_plus.dart';
import 'package:state/features/home/data/models/post_model.dart';

class ShareService {
  static const String _webBaseUrl = 'https://stateapp.net';

  Future<void> sharePost(PostModel post) async {
    try {
      final shareUrl = '$_webBaseUrl/post/${post.id}';

      await Share.share(shareUrl, subject: 'Check out this post on State');
    } catch (e) {
      print('Error sharing post: $e');
    }
  }
}
