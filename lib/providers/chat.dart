

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void listenToMessages({required String chatId}) {
    try { 
      messageStream = databaseService.streamMessagesForChat(chatId).listen((snapshot) {
        List<ChatMessage> lcm = snapshot.docs.map((m) {
          Map<String, dynamic> messageData = m.data() as Map<String, dynamic>;
          return ChatMessage.fromJSON(messageData);
        }).toList();
        messages = lcm;
        notifyListeners();
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

  void listenToKeyboardType({required String chatId}) {
    messageTextEditingController.addListener(() {
      if(messageTextEditingController.text.isNotEmpty) {
        toggleIsActivity(isActive: true, chatId: chatId);
      } else {
        toggleIsActivity(isActive: false, chatId: chatId);
      }
    });
  }

  void sendTextMessage({required String chatId}) {
    if(messages != null) {
      ChatMessage messageToSend = ChatMessage(
        content: messageTextEditingController.text, 
        senderID: authenticationProvider.auth.currentUser!.uid, 
        isRead: false,
        type: MessageType.text, 
        sentTime: DateTime.now()
      );
      databaseService.addMessageToChat(chatId, messageToSend);
      messageTextEditingController.text = "";
      notifyListeners();
    }
  }

  void sendImageMessage({required String chatId}) async {
    try {
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        toggleIsActivity(isActive: true, chatId: chatId);
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatId, authenticationProvider.auth.currentUser!.uid, file);
        toggleIsActivity(isActive: false, chatId: chatId);
        ChatMessage messageToSend = ChatMessage(
          content: downloadUrl!, 
          senderID: authenticationProvider.auth.currentUser!.uid, 
          isRead: false,
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

  void toggleIsActivity({required bool isActive, required String chatId}) {
    databaseService.updateChatData(chatId, {
      "is_activity": isActive
    });
  }

  void deleteChat(BuildContext context, {required String chatId}) {
    goBack(context);
    databaseService.deleteChat(chatId);
  }
  
  void goBack(BuildContext context) {
    NavigationService.goBack(context);
  }
}