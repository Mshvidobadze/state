import 'package:state/features/home/data/models/post_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<PostModel> posts;
  HomeLoaded(this.posts);
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
