

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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

  bool isRead = false;

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
        Future.delayed(Duration.zero, () => notifyListeners());
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          if(scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
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

  void sendTextMessage({required String chatUid}) {
    if(messages != null) {
      ChatMessage messageToSend = ChatMessage(
        content: messageTextEditingController.text, 
        senderID: authenticationProvider.auth.currentUser!.uid, 
        isRead: isRead ? true : false,
        type: MessageType.text, 
        sentTime: DateTime.now()
      );
      databaseService.addMessageToChat(chatUid, messageToSend);
      messageTextEditingController.text = "";
      Future.delayed(Duration.zero, () => notifyListeners());
    }
  }

  void sendImageMessage({required String chatId}) async {
    try {
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        toggleIsActivity(isActive: true, chatUid: chatId);
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatId, authenticationProvider.auth.currentUser!.uid, file);
        toggleIsActivity(isActive: false, chatUid: chatId);
        ChatMessage messageToSend = ChatMessage(
          content: downloadUrl!, 
          senderID: authenticationProvider.auth.currentUser!.uid, 
          isRead: isRead ? true : false,
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        databaseService.addMessageToChat(chatId, messageToSend);
      }
    } catch (e) {
      debugPrint("Error sending image message.");
      debugPrint(e.toString());
    }
  }

  Future<void> isScreenOn({required String chatUid, required String userUid}) async {
    bool? _isRead = await databaseService.isScreenOn(chatUid: chatUid, userUid: userUid);
    isRead = _isRead!;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void joinScreen({required String chatUid}) {
    databaseService.joinScreen(chatUid, authenticationProvider.auth.currentUser!.uid);
  }

  void leaveScreen({required String chatUid}) {
    databaseService.leaveScreen(chatUid, authenticationProvider.auth.currentUser!.uid);
  }

  void toggleIsActivity({required bool isActive, required String chatUid}) {
    databaseService.updateChatData(chatUid, {
      "is_activity": isActive
    });
  }

  void deleteChat(BuildContext context, {required String chatUid}) {
    goBack(context);
    databaseService.deleteChat(chatUid);
  }
  
  void goBack(BuildContext context) {
    NavigationService.goBack(context);
  }
}