import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state/app/app_router.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/data/auth_repository_impl.dart';
import 'package:state/features/auth/domain/auth_repository.dart';
import 'package:state/features/following/bloc/following_cubit.dart';
import 'package:state/features/following/data/repository/following_repository_impl.dart';
import 'package:state/features/following/domain/following_repository.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/data/repository/home_repository_impl.dart';
import 'package:state/features/home/data/repository/advertisement_repository_impl.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/home/domain/advertisement_repository.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/data/repository/post_details_repository_impl.dart';
import 'package:state/features/postDetails/domain/post_details_repository.dart';
import 'package:state/features/splash/bloc/splash_cubit.dart';
import 'package:state/features/userProfile/bloc/user_profile_cubit.dart';
import 'package:state/features/userProfile/data/repository/user_profile_repository_impl.dart';
import 'package:state/features/userProfile/domain/user_profile_repository.dart';
import 'package:state/features/search/bloc/search_cubit.dart';
import 'package:state/features/search/data/repository/search_repository_impl.dart';
import 'package:state/features/search/domain/search_repository.dart';
import 'package:state/features/notifications/bloc/notification_cubit.dart';
import 'package:state/features/notifications/data/repository/notification_repository_impl.dart';
import 'package:state/features/notifications/domain/notification_repository.dart';
import 'package:state/core/services/notification_service.dart';
import 'package:state/core/services/fcm_token_service.dart';
import 'package:state/core/services/share_service.dart';
import 'package:state/core/services/deep_link_service.dart';

final sl = GetIt.instance;

Future<void> initInjections() async {
  // Services
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingletonAsync(() => SharedPreferences.getInstance());

  // Notification Service
  sl.registerLazySingleton(() => NotificationService());

  // FCM Token Service
  sl.registerLazySingleton(() => FCMTokenService());

  // Share Service
  sl.registerLazySingleton(() => ShareService());

  // Deep Link Service
  sl.registerLazySingleton(() => DeepLinkService());

  // Router
  sl.registerLazySingleton(() => AppRouter.router);

  // Navigation Service
  sl.registerLazySingleton<INavigationService>(() => NavigationService());

  // Splash
  sl.registerFactory(() => SplashCubit(sl<AuthRepository>()));

  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
    ),
  );
  sl.registerFactory(() => AuthCubit(sl<AuthRepository>(), sl<FirebaseAuth>()));

  // Home
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(firestore: sl()),
  );
  sl.registerLazySingleton<AdvertisementRepository>(
    () => AdvertisementRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(
    () => HomeCubit(
      sl<HomeRepository>(),
      sl<AdvertisementRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  // Post Creation
  sl.registerFactory(
    () => PostCreationCubit(
      sl<HomeRepository>(),
      sl<FirebaseAuth>(),
      sl<FirebaseStorage>(),
    ),
  );

  // Following
  sl.registerLazySingleton<FollowingRepository>(
    () => FollowingRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(
    () => FollowingCubit(
      sl<FollowingRepository>(),
      sl<HomeRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  // Post Details
  sl.registerLazySingleton<PostDetailsRepository>(
    () => PostDetailsRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(
    () => PostDetailsCubit(
      sl<PostDetailsRepository>(),
      sl<FirebaseAuth>(),
      sl<FirebaseStorage>(),
    ),
  );

  // User Profile
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(
    () => UserProfileCubit(
      sl<UserProfileRepository>(),
      sl<FirebaseStorage>(),
      sl<HomeRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  // Search
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(() => SearchCubit(sl<SearchRepository>()));

  // Notifications
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(firestore: sl()),
  );
  sl.registerFactory(
    () => NotificationCubit(sl<NotificationRepository>(), sl<FirebaseAuth>()),
  );
}
