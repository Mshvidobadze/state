import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'post_creation_state.dart';

class PostCreationCubit extends Cubit<PostCreationState> {
  static const int maxImagesPerPost = 5;

  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;

  PostCreationCubit(
    this.homeRepository,
    this.firebaseAuth,
    this.firebaseStorage,
  ) : super(PostCreationInitial());

  Future<void> createPost({
    required String region,
    required String content,
    List<File> imageFiles = const [],
  }) async {
    emit(PostCreationLoading());
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not signed in');

      final limitedImageFiles = imageFiles.take(maxImagesPerPost).toList();
      final uploadedImageUrls = <String>[];
      if (limitedImageFiles.isNotEmpty) {
        for (var i = 0; i < limitedImageFiles.length; i++) {
          final imageFile = limitedImageFiles[i];
          final ref = firebaseStorage
              .ref()
              .child('post_images')
              .child(
                '${DateTime.now().millisecondsSinceEpoch}_${user.uid}_$i.jpg',
              );
          try {
            final uploadTask = await ref.putFile(imageFile);
            final imageUrl = await uploadTask.ref.getDownloadURL();
            uploadedImageUrls.add(imageUrl);
          } catch (e) {
            emit(PostCreationError('Image upload failed: $e'));
            return;
          }
        }
      }

      final post = PostModel(
        id: '',
        authorId: user.uid,
        authorName: user.displayName ?? '',
        authorPhotoUrl: user.photoURL,
        region: region,
        title: '',
        content: content,
        imageUrl: uploadedImageUrls.isNotEmpty ? uploadedImageUrls.first : null,
        imageUrls: uploadedImageUrls,
        upvotes: 0,
        downvotes: 0,
        commentsCount: 0,
        createdAt: DateTime.now(),
        followers: [],
        upvoters: [],
        downvoters: [],
        reporters: [],
      );
      await homeRepository.createPost(post);
      emit(PostCreationSuccess());
    } catch (e) {
      emit(PostCreationError(e.toString()));
    }
  }
}
