import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'post_creation_state.dart';

class PostCreationCubit extends Cubit<PostCreationState> {
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
    File? imageFile,
  }) async {
    emit(PostCreationLoading());
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not signed in');

      String? imageUrl;
      if (imageFile != null) {
        final ref = firebaseStorage
            .ref()
            .child('post_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
        try {
          final uploadTask = await ref.putFile(imageFile);
          imageUrl = await uploadTask.ref.getDownloadURL();
        } catch (e) {
          emit(PostCreationError('Image upload failed: $e'));
          return;
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
        imageUrl: imageUrl,
        upvotes: 0,
        commentsCount: 0,
        createdAt: DateTime.now(),
        followers: [],
        upvoters: [],
        reporters: [],
      );
      await homeRepository.createPost(post);
      emit(PostCreationSuccess());
    } catch (e) {
      emit(PostCreationError(e.toString()));
    }
  }
}
