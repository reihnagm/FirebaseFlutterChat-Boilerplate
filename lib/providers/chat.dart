

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:chatv28/models/chat_user.dart';
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

  String? isOnline;

  List<ChatMessage>? messages;

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions.kDefault);

  bool isRead = false;
  String token = "";

  late ScrollController scrollController;
  late TextEditingController messageTextEditingController;
  late KeyboardVisibilityController keyboardVisibilityController; 
  StreamSubscription? isUserOnlineStream;
  StreamSubscription? messageStream;
  StreamSubscription? keyboardTypeStream; 
  StreamSubscription? keyboardVisibilityStream; 

  @override
  void dispose() {
    isUserOnlineStream!.cancel();
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
                milliseconds: 500
              ), 
              curve: Curves.easeInOut
            );
          }
        });
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
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
    required String senderName,
    required String receiverId,
    required String subtitle,
    required bool isGroup
  }) async {
    if(messages != null) {
      ChatMessage messageToSend = ChatMessage(
        content: messageTextEditingController.text, 
        senderName: senderName,
        senderId: isGroup ? authenticationProvider.userUid() : receiverId, 
        isRead: isRead ? true : false,
        type: MessageType.text, 
        sentTime: DateTime.now()
      );
      await databaseService.addMessageToChat(
        chatUid: chatUid, 
        readerId: isGroup ? authenticationProvider.userUid() : receiverId, 
        isGroup: isGroup,
        message: messageToSend
      );
      if(!isRead) {
        Future.delayed(Duration.zero, () async {
          await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
            token: token, 
            title: senderName,
            subtitle: subtitle,
            body: messageToSend.content, 
            chatUid: chatUid,
            senderId: authenticationProvider.userUid(),
            receiverId: receiverId,
            isGroup: isGroup,
          );
        });
      }
      await loadSoundSent();
      messageTextEditingController.text = "";
      Future.delayed(Duration.zero, () => notifyListeners());
    }
  }

  Future sendImageMessage(
    BuildContext context,
  {
    required String chatUid, 
    required String senderName,
    required String receiverId, 
    required String subtitle,
    required bool isGroup
  }) async {
    try {
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        // toggleIsActivity(isActive: true, chatUid: chatUid);
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatUid, authenticationProvider.userUid(), file);
        // toggleIsActivity(isActive: false, chatUid: chatUid);
        ChatMessage messageToSend = ChatMessage(
          content: downloadUrl!, 
          senderName: authenticationProvider.userName(),
          senderId: authenticationProvider.userUid(),
          isRead: isRead ? true : false,
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        await databaseService.addMessageToChat(
          chatUid: chatUid, 
          readerId: isGroup ? authenticationProvider.userUid() : receiverId, 
          isGroup: isGroup,
          message: messageToSend
        );
        if(!isRead) {
          Future.delayed(Duration.zero, () async {
            await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
              token: token, 
              title: senderName,
              subtitle: subtitle,
              body: messageToSend.content, 
              chatUid: chatUid,
              senderId: authenticationProvider.userUid(),
              receiverId: receiverId,
              isGroup: isGroup,
            );
          });
        }
        await loadSoundSent();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> isScreenOn({required String chatUid, required String userUid}) async {
    try {
      List<dynamic>? onScreens = await databaseService.isScreenOn(chatUid: chatUid);
      if(onScreens.where((el) => el["userUid"] == userUid).isNotEmpty) {
        isRead = onScreens.firstWhere((el) => el["userUid"] == userUid)["on"]; 
      }
      if(onScreens.where((el) => el["userUid"] != userUid).isNotEmpty) {
        token = onScreens.firstWhere((el) => el["userUid"] != userUid)["token"];
      } 
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

  Future<void> seeMsg({required String chatUid, required String senderId, required String receiverId, required bool isGroup}) async {
    try {
      await databaseService.seeMsg(
        chatUid: chatUid,
        isGroup: isGroup,
        senderId: senderId,
        receiverId: receiverId,
        userUid: authenticationProvider.userUid(),
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
        userUid: authenticationProvider.userUid()
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen({required String chatUid}) async {
    try {
      await databaseService.leaveScreen(
        chatUid: chatUid,
        userUid: authenticationProvider.userUid()
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

  Future<void> deleteChat(BuildContext context, {required String chatUid, required String receiverId}) async {
    goBack(context, chatUid: chatUid, receiverId: receiverId);
    try {
      await databaseService.deleteChat(chatUid);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void isUserOnline({required String receiverId}) async {
    try {
      isUserOnlineStream = databaseService.getChatUserOnline(receiverId)!.listen((snapshot) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        ChatUser chatUser = ChatUser.fromJson(data);
        chatUser.isUserOnline() ? isOnline = "ONLINE" : isOnline = "OFFLINE";
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }
  
  void goBack(BuildContext context, {required String chatUid, required String receiverId}) {
    NavigationService.goBack(context);
    Provider.of<ChatProvider>(context, listen: false).isScreenOn(
      chatUid: chatUid, 
      userUid: receiverId
    );
    Provider.of<ChatProvider>(context, listen: false).leaveScreen(
      chatUid: chatUid,
    );
  }
}