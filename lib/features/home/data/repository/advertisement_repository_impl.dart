import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/domain/advertisement_repository.dart';

class AdvertisementRepositoryImpl implements AdvertisementRepository {
  final FirebaseFirestore firestore;

  AdvertisementRepositoryImpl({required this.firestore});

  @override
  Future<List<PostModel>> fetchAdvertisements() async {
    try {
      final snapshot =
          await firestore
              .collection('advertisements')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();
    } catch (e) {
      // Silently fail and return empty list - don't break the app if ads fail to load
      // This ensures the main feed still works even if advertisement service is down
      return [];
    }
  }
}
