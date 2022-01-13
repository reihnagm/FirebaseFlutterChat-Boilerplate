import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatv28/providers/firebase.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/providers/chats.dart';
import 'package:chatv28/providers/user.dart';
import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/media.dart';
import 'package:chatv28/services/navigation.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerLazySingleton(() => NavigationService());
  getIt.registerLazySingleton(() => MediaService());
  getIt.registerLazySingleton(() => CloudStorageService());
  getIt.registerLazySingleton(() => DatabaseService());

  getIt.registerFactory(() => AuthenticationProvider(
    cloudStorageService: getIt(),
    sharedPreferences: getIt(),
    databaseService: getIt(),
  ));
  getIt.registerFactory(() => UserProvider(
    authenticationProvider: getIt(),
    databaseService: getIt(),
    navigationService: getIt(),
    cloudStorageService: getIt()
  ));
  getIt.registerFactory(() => ChatsProvider(
    authenticationProvider: getIt(), 
    sharedPreferences: getIt(),
    databaseService: getIt()
  ));
  getIt.registerFactory(() => ChatProvider(
    sharedPreferences: getIt(),
    authenticationProvider: getIt(),
    cloudStorageService: getIt(),
    databaseService: getIt(),
    mediaService: getIt(),
    navigationService: getIt(),
  ));
  getIt.registerFactory(() => FirebaseProvider(
    authenticationProvider: getIt(),
    sharedPreferences: getIt()
  ));
  
   // External
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
}