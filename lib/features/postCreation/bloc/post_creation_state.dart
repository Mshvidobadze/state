abstract class PostCreationState {}

class PostCreationInitial extends PostCreationState {}

class PostCreationLoading extends PostCreationState {}

class PostCreationSuccess extends PostCreationState {}

class PostCreationError extends PostCreationState {
  final String message;
  PostCreationError(this.message);
}
