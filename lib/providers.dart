import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:chatv28/providers/firebase.dart';
import 'package:chatv28/providers/user.dart';
import 'package:chatv28/providers/chats.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/providers/authentication.dart';

import 'container.dart' as c;

List<SingleChildWidget> providers = [
  ...independentServices,
];

List<SingleChildWidget> independentServices = [
  ChangeNotifierProvider(create: (_) => c.getIt<AuthenticationProvider>()),
  ChangeNotifierProvider(create: (_) => c.getIt<ChatProvider>()),
  ChangeNotifierProvider(create: (_) => c.getIt<ChatsProvider>()),
  ChangeNotifierProvider(create: (_) => c.getIt<UserProvider>()),
  ChangeNotifierProvider(create: (_) => c.getIt<FirebaseProvider>()),
  Provider.value(value: const <String, dynamic>{})
];