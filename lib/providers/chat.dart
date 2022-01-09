

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';

import 'package:chatv28/models/chat.dart';
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

  List<dynamic> seeReads = [];

  String? isOnline;

  List<ChatMessage>? messages;

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions.kDefault);

  bool isRead = false;
  String token = "";

  late ScrollController? scrollController;
  late TextEditingController? messageTextEditingController;
  StreamSubscription? isScreenOnStream;
  StreamSubscription? isUserOnlineStream;
  StreamSubscription? messageStream;
  StreamSubscription? keyboardTypeStream;

  KeyboardVisibilityController keyboardVisibilityController = KeyboardVisibilityController(); 

  @override
  void dispose() {
    isUserOnlineStream!.cancel();
    isScreenOnStream!.cancel();
    messageStream!.cancel();
    keyboardTypeStream!.cancel();
    messageTextEditingController!.dispose();
    scrollController!.dispose();
    super.dispose();
  }

  ChatProvider({
    required this.authenticationProvider, 
    required this.databaseService,
    required this.mediaService,
    required this.cloudStorageService,
    required this.navigationService
  }) {
    scrollController = ScrollController();
    messageTextEditingController = TextEditingController();
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
          if(scrollController!.hasClients) {
            scrollController!.animateTo(
              scrollController!.position.maxScrollExtent, 
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

  void listenToKeyboardChanges({required String chatUid}) {
    keyboardTypeStream = keyboardVisibilityController.onChange.listen((event) async {
       await toggleIsActivity(
        isActive: event, 
        chatUid: chatUid
      );
    });
  }

  void listenToKeyboardType({required String chatUid}) {
    // messageTextEditingController!.addListener(() {
    //   if(messageTextEditingController!.text.trim().isNotEmpty) {
    //     toggleIsActivity(isActive: true, chatUid: chatUid);
    //   }
    //   if(messageTextEditingController!.text.trim().isEmpty) {
    //     toggleIsActivity(isActive: false, chatUid: chatUid);
    //   }
      
    // });
  }

  Future<void> sendTextMessage(
    BuildContext context,
  {
    required String chatUid, 
    required String title,
    required String subtitle,
    required String receiverName,
    required String receiverImage,
    required String receiverId,
    required List<ChatUser> members,
    required List<Token> tokens,
    required bool isGroup
  }) async {
    if(messages != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<dynamic> readers = [];
      List<String> uids = [];
      List<String> registrationIds = [];
      for (Token item in tokens) {
        if(item.userUid != authenticationProvider.userUid()) {
          registrationIds.add(item.token);
        }
      }
      if(isGroup) {
        for (ChatUser member in members) {
          if(member.uid != authenticationProvider.userUid()) {
            readers.add({
              "uid": member.uid,
              "name": member.name,
              "image": member.image,
              "is_read": false,
              "seen": DateTime.now()
            });
            uids.add(member.uid!);
          }
        }
      } else {
        readers = [
          {
            "uid": authenticationProvider.userUid(),
            "name": authenticationProvider.userName(),
            "image": authenticationProvider.userImage(),
            "is_read": true,
            "seen": DateTime.now()
          },
          {
            "uid": receiverId,
            "name": receiverName,
            "image": receiverImage,
            "is_read": isRead,
            "seen": DateTime.now()
          }
        ];
      }
      ChatMessage messageToSend = ChatMessage(
        content: prefs.getString("msg")!, 
        senderId: authenticationProvider.userUid(),
        senderName: authenticationProvider.userName(),
        receiverId: receiverId, 
        isRead: isRead ? true : false,
        readers: [],
        readerCountIds: [],
        type: MessageType.text, 
        sentTime: DateTime.now()
      );
      messageTextEditingController!.text = "";
      try {
        await databaseService.addMessageToChat(
          context,
          chatId: chatUid, 
          isGroup: isGroup,
          message: messageToSend,
          uids: uids,
          readers: readers
        );
      } catch(e) {
        debugPrint(e.toString());
      }      
      if(!isRead) {
        try {
          await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
            chatUid: chatUid,
            tokens: tokens,
            registrationIds: registrationIds,
            token: token, 
            title: title,
            subtitle: subtitle,
            body: messageToSend.content, 
            receiverId: receiverId,
            receiverName: receiverName,
            receiverImage: receiverImage,
            isGroup: isGroup,
          );
        } catch(e) {
          debugPrint(e.toString());
        }
      }
      try {
        await loadSoundSent();
      } catch(e) {
        debugPrint(e.toString());
      }
      Future.delayed(Duration.zero, () => notifyListeners());
    }
  }

  Future sendImageMessage(
    BuildContext context,
  {
    required String chatUid, 
    required String title,
    required String subtitle,
    required String receiverId, 
    required String receiverName,
    required String receiverImage,
    required List<ChatUser> members,
    required List<Token> tokens,
    required bool isGroup
  }) async {
    try {
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        List<dynamic> readers = [];
        List<String> uids = [];
        List<String> registrationIds = [];
        for (Token item in tokens) {
          if(item.userUid != authenticationProvider.userUid()) {
            registrationIds.add(item.token);
          }
        }
        if(isGroup) {
          for (ChatUser member in members) {
            if(member.uid != authenticationProvider.userUid()) {
              readers.add({
                "uid": member.uid,
                "name": member.name,
                "image": member.image,
                "is_read": false,
                "seen": DateTime.now()
              });
              uids.add(member.uid!);
            }
          }
        } else {
          readers = [
            {
              "uid": authenticationProvider.userUid(),
              "name": authenticationProvider.userName(),
              "image": authenticationProvider.userImage(),
              "is_read": true,
              "seen": DateTime.now()
            },
            {
              "uid": receiverId,
              "name": receiverName,
              "image": receiverImage,
              "is_read": isRead,
              "seen": DateTime.now()
            }
          ];
        }
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatUid, authenticationProvider.userUid(), file);
        ChatMessage messageToSend = ChatMessage(
          content: downloadUrl!, 
          senderId: authenticationProvider.userUid(),
          senderName: authenticationProvider.userName(),
          receiverId: receiverId,
          isRead: isRead ? true : false,
          readers: [],
          readerCountIds: [],
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        try {
          await databaseService.addMessageToChat(
            context,
            chatId: chatUid,  
            isGroup: isGroup,
            message: messageToSend,
            uids: uids,
            readers: readers
          );
        } catch(e) {
          debugPrint(e.toString());
        }
        if(!isRead) {
          debugPrint(receiverName);
          try {
            await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
              chatUid: chatUid,
              tokens: tokens,
              registrationIds: registrationIds,
              token: token, 
              title: title,
              subtitle: subtitle,
              body: messageToSend.content, 
              receiverId: receiverId,
              receiverName: receiverName,
              receiverImage: receiverImage,
              isGroup: isGroup,
            );
          } catch(e) {
            debugPrint(e.toString());
          } 
        }
        try {
          await loadSoundSent();
        } catch(e) {
          debugPrint(e.toString());
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void isScreenOn({required String chatUid, required String userUid}) async {
    try {
      isScreenOnStream = databaseService.isScreenOn(chatUid: chatUid)!.listen((snapshot) {
        for (QueryDocumentSnapshot<Object?> item in snapshot.docs) {
          Map<String, dynamic> data = item.data() as Map<String, dynamic>;
          List<dynamic> onScreens = data["on_screens"];
          if(onScreens.where((el) => el["userUid"] == userUid).isNotEmpty) {
            token = onScreens.firstWhere((el) => el["userUid"] == userUid)["token"];
          }
          if(onScreens.where((el) => el["userUid"] == userUid).isNotEmpty) {
            isRead = onScreens.firstWhere((el) => el["userUid"] == userUid)["on"];
          } 
        }
        Future.delayed(Duration.zero, () => notifyListeners()); 
      });
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

  Future<void> seeMsg({required String chatUid, required String receiverId, required bool isGroup}) async {
    try {
      await databaseService.seeMsg(
        chatId: chatUid,
        isGroup: isGroup,
        receiverId: receiverId,
        userImage: authenticationProvider.userImage(),
        userName: authenticationProvider.userName(),
        userUid: authenticationProvider.userUid(),
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen({required String chatUid}) async {
    try {
      await databaseService.joinScreen(
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
    goBack(
      context, 
      chatUid: chatUid, 
      receiverId: receiverId
    );
    try {
      await databaseService.deleteChat(chatUid);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void isUserOnline({required String receiverId}) {
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
  }
}