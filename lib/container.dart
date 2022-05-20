import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/providers/firebase.dart';
import 'package:chat/providers/authentication.dart';
import 'package:chat/providers/chat.dart';
import 'package:chat/providers/chats.dart';
import 'package:chat/providers/user.dart';

import 'package:chat/services/cloud_storage.dart';
import 'package:chat/services/database.dart';
import 'package:chat/services/media.dart';
import 'package:chat/services/navigation.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerLazySingleton(() => NavigationService());
  getIt.registerLazySingleton(() => MediaService());
  getIt.registerLazySingleton(() => CloudStorageService(
    ds: getIt()
  ));
  getIt.registerLazySingleton(() => DatabaseService());

  getIt.registerFactory(() => AuthenticationProvider(
    css: getIt(),
    sp: getIt(),
    ds: getIt(),
    ns: getIt()
  ));
  getIt.registerFactory(() => UserProvider(
    ap: getIt(),
    ds: getIt(),
    ns: getIt(),
    css: getIt()
  ));
  getIt.registerFactory(() => ChatsProvider(
    ap: getIt(), 
    sp: getIt(),
    ds: getIt()
  ));
  getIt.registerFactory(() => ChatProvider(
    sp: getIt(),
    ap: getIt(),
    css: getIt(),
    ds: getIt(),
    ms: getIt(),
    ns: getIt(),
  ));
  getIt.registerFactory(() => FirebaseProvider(
    ap: getIt(),
    sp: getIt()
  ));
  
   // External
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
}