

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:chatv28/providers/firebase.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/media.dart';
import 'package:chatv28/services/navigation.dart';

class ChatProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;
  final CloudStorageService cloudStorageService;
  final MediaService mediaService;
  final NavigationService navigationService;

  List<ChatMessage>? messages;

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions.kDefault);

  bool isRead = false;
  String token = "";

  late ScrollController scrollController;
  late TextEditingController messageTextEditingController;
  late KeyboardVisibilityController keyboardVisibilityController; 
  StreamSubscription? messageStream;
  StreamSubscription? keyboardTypeStream; 
  StreamSubscription? keyboardVisibilityStream; 

  @override
  void dispose() {
    messageStream!.cancel();
    keyboardTypeStream!.cancel();
    keyboardVisibilityStream!.cancel();
    scrollController.dispose();
    messageTextEditingController.dispose();
    super.dispose();
  }

  ChatProvider({
    required this.authenticationProvider, 
    required this.databaseService,
    required this.mediaService,
    required this.cloudStorageService,
    required this.navigationService
  }) {
    authenticationProvider.initAuthStateChanges();
    keyboardVisibilityController = KeyboardVisibilityController();
    scrollController = ScrollController();
    messageTextEditingController = TextEditingController();
    // OPTION 1 listenToKeyboardChanges(); 
  }

  void listenToMessages({required String chatUid}) {
    try { 
      messageStream = databaseService.streamMessagesForChat(chatUid).listen((snapshot) {
        List<ChatMessage> cm = snapshot.docs.map((m) {
          Map<String, dynamic> messageData = m.data() as Map<String, dynamic>;
          return ChatMessage.fromJSON(messageData);
        }).toList();
        messages = cm;
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          if(scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent, 
              duration: const Duration(
                milliseconds: 300
              ), 
              curve: Curves.easeInOut
            );
          }
        });
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
      debugPrint("Error gettings messages");
      debugPrint(e.toString());
    }
  }

  void listenToKeyboardChanges() {
    keyboardVisibilityStream = keyboardVisibilityController.onChange.listen((event) {
      // OPTION 1
    });
  }

  void listenToKeyboardType({required String chatUid}) {
    // messageTextEditingController.addListener(() {
    //   if(messageTextEditingController.text.isNotEmpty) {
    //     toggleIsActivity(isActive: true, chatId: chatId);
    //   } else {
    //     toggleIsActivity(isActive: false, chatId: chatId);
    //   }
    // });
  }

  Future<void> sendTextMessage(
    BuildContext context,
  {
    required String chatUid, 
    required String receiverId
  }) async {
    if(messages != null) {
      ChatMessage messageToSend = ChatMessage(
        content: messageTextEditingController.text, 
        senderID: authenticationProvider.auth.currentUser!.uid, 
        isRead: isRead ? true : false,
        type: MessageType.text, 
        sentTime: DateTime.now()
      );
      await databaseService.addMessageToChat(chatUid, receiverId, messageToSend);
      if(!isRead) {
        Future.delayed(const Duration(seconds: 1), () async {
          await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
            token: token, 
            title: authenticationProvider.chatUser!.name!,
            body: messageToSend.content, 
            chatUid: chatUid,
            senderId: authenticationProvider.chatUser!.uid!,
            receiverId: receiverId
          );
        });
      }
      Future.delayed(Duration.zero, () async {
        await loadSoundSent();
      });
      messageTextEditingController.text = "";
      Future.delayed(Duration.zero, () => notifyListeners());
    }
  }

  Future sendImageMessage({required String chatUid, required String receiverId}) async {
    try {
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        toggleIsActivity(isActive: true, chatUid: chatUid);
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatUid, authenticationProvider.auth.currentUser!.uid, file);
        toggleIsActivity(isActive: false, chatUid: chatUid);
        ChatMessage messageToSend = ChatMessage(
          content: downloadUrl!, 
          senderID:  authenticationProvider.auth.currentUser!.uid, 
          isRead: isRead ? true : false,
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        databaseService.addMessageToChat(chatUid, receiverId, messageToSend);
      }
    } catch (e) {
      debugPrint("Error sending image message.");
      debugPrint(e.toString());
    }
  }

  Future<void> isScreenOn({required String chatUid, required String userUid}) async {
    try {
      List<dynamic>? onScreens = await databaseService.isScreenOn(chatUid: chatUid);
      isRead = onScreens!.firstWhere((el) => el["userUid"] == userUid)["on"];
      token = onScreens.firstWhere((el) => el["userUid"] != userUid)["token"];
      Future.delayed(Duration.zero, () => notifyListeners()); 
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<int?> loadSoundSent() async {
    try {
      ByteData asset = await rootBundle.load("assets/sounds/sent.mp3");
      return await pool.play(await pool.load(asset));
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> seeMsg({required String chatUid, required String senderId}) async {
    try {
      await databaseService.seeMsg(
        chatUid: chatUid,
        senderId: senderId,
        userUid: authenticationProvider.auth.currentUser!.uid,
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen({required String token, required String chatUid}) async {
    try {
      await databaseService.joinScreen(
        token: token,
        chatUid: chatUid,
        userUid: authenticationProvider.auth.currentUser!.uid
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen({required String chatUid}) async {
    try {
      await databaseService.leaveScreen(
        chatUid: chatUid,
        userUid: authenticationProvider.auth.currentUser!.uid
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> toggleIsActivity({required bool isActive, required String chatUid}) async {
    try {
      await databaseService.updateChatData(chatUid, {
        "is_activity": isActive
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(BuildContext context, {required String chatUid}) async {
    goBack(context);
    try {
      await databaseService.deleteChat(chatUid);
    } catch(e) {
      debugPrint(e.toString());
    }
  }
  
  void goBack(BuildContext context) {
    NavigationService.goBack(context);
  }
}