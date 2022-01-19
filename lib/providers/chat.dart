

import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/providers/firebase.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/media.dart';
import 'package:chatv28/services/navigation.dart';

enum UploadImageStatus { idle, loading, loaded, empty, error }

class ChatProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;
  final CloudStorageService cloudStorageService;
  final MediaService mediaService;
  final NavigationService navigationService;

  Timer? debounce;

  List<dynamic> userIdIsNotRead = [];

  List<Readers> get whoReads => selectedMessages.last.readers.where((el) => el.isRead == true).toList();
  List<ChatMessage> selectedMessages = [];

  bool get isSelectedMessages => selectedMessages.isNotEmpty;

  List<ChatMessage>? _messages = [];
  List<ChatMessage>? get messages => [..._messages!];

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions.kDefault);

  String msg = "";
  String isTyping = "";
  String? isOnline;
  String token = "";
  String currentUserIsRead = "";
  bool isRead = false;

  ScrollController scrollController = ScrollController();
  TextEditingController messageTextEditingController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();
  StreamSubscription? readersStream;
  StreamSubscription? isScreenOnStream;
  StreamSubscription? isUserOnlineStream;
  StreamSubscription? isUserTypingStream;
  StreamSubscription? messageStream;

  ChatProvider({
    required this.sharedPreferences,
    required this.authenticationProvider, 
    required this.databaseService,
    required this.mediaService,
    required this.cloudStorageService,
    required this.navigationService
  });

  void clearSelectedMessages() {
    selectedMessages = [];
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void onSelectedMessages(ChatMessage message) {
    if(selectedMessages.contains(message)) {
      selectedMessages.remove(message);
    } else {
      selectedMessages.add(message);
    }
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void onSelectedMessagesRemove(ChatMessage message) {
    if(selectedMessages.contains(message)) {
      selectedMessages.remove(message);
    }
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void listenToMessages() {
    try { 
      messageStream = databaseService.streamMessagesForChat(chatId())!.listen((snapshot) {
        _messages = [];
        Future.delayed(Duration.zero, () => notifyListeners());
        List<ChatMessage> messages = snapshot.docs.map((m) {
          Map<String, dynamic> messageData = m.data() as Map<String, dynamic>;
          return ChatMessage.fromJSON(messageData);
        }).toList();
        _messages = messages;
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void onChangeMsg(BuildContext context, String val) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 100), () {
      toggleIsActivity(
        isActive: val.isNotEmpty ? true : false, 
        userId: userId(),
      );
    });
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  Future<void> sendTextMessage(
    BuildContext context,
  {
    required String title,
    required String subtitle,
    required String receiverName,
    required String receiverImage,
    required String receiverId,
    required List<ChatUser> members,
    required List<Token> tokens,
    required String groupName,
    required String groupImage,
    required bool isGroup
  }) async {
    String msgId = const Uuid().v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<dynamic> readers = [];
    List<dynamic> registrationIds = [];
    for (Token token in tokens) {
      if(token.userId != authenticationProvider.userId()) {
        registrationIds.add(token.token);
      }
    }
    if(isGroup) {
      for (ChatUser member in members) {
        if(member.uid != authenticationProvider.userId()) {
          if(member.uid == currentUserIsRead) {
            readers.add({
              "uid": member.uid,
              "name": member.name,
              "image": member.image,
              "is_read": true,
              "seen": DateTime.now(),
              "created_at": DateTime.now()
            });
          } else {
            readers.add({
              "uid": member.uid,
              "name": member.name,
              "image": member.image,
              "is_read": false,
              "seen": DateTime.now(),
              "created_at": DateTime.now()
            });
          }
        }
      }
    } else {
      readers = [
        {
          "uid": authenticationProvider.userId(),
          "name": authenticationProvider.userName(),
          "image": authenticationProvider.userImage(),
          "is_read": true,
          "seen": DateTime.now(),
          "created_at": DateTime.now()
        },
        {
          "uid": receiverId,
          "name": receiverName,
          "image": receiverImage,
          "is_read": isRead,
          "seen": DateTime.now(),
          "created_at": DateTime.now()
        }
      ];
    }
    ChatMessage messageToSend = ChatMessage(
      uid: msgId,
      content: prefs.getString("msg")!, 
      senderId: authenticationProvider.userId(),
      senderName: authenticationProvider.userName(),
      receiverId: receiverId, 
      isRead: isRead ? true : false,
      softDelete: false,
      readers: [],
      readerCountIds: [],
      type: MessageType.text, 
      sentTime: DateTime.now()
    );
    messageTextEditingController.text = "";
    try {
      databaseService.addMessageToChat(
        context,
        msgId: msgId,
        chatId: chatId(), 
        isGroup: isGroup,
        message: messageToSend,
        currentUserId: authenticationProvider.userId(),
        userIdNotRead: userIdIsNotRead,
        readers: readers,
      ).then((_) async {
        await databaseService.updateMicroTask(chatId());
      });
      if(scrollController.hasClients) {
        scrollController.animateTo(0, 
          duration: const Duration(
            milliseconds: 300
          ), 
          curve: Curves.easeInOut
        );
      }
    } catch(e) {
      debugPrint(e.toString());
    }      
    if(!isRead) {
      try {
        await context.read<FirebaseProvider>().sendNotification(
          chatId: chatId(),
          registrationIds: registrationIds,
          token: token, 
          title: title,
          subtitle: subtitle,
          body: messageToSend.content, 
          receiverId: receiverId,
          receiverName: receiverName,
          receiverImage: receiverImage,
          groupName: groupName,
          groupImage: groupImage,
          isGroup: isGroup,
          type: "text"
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

  Future sendImageMessage(
    BuildContext context,
  {
    required String title,
    required String subtitle,
    required String receiverId, 
    required String receiverName,
    required String receiverImage,
    required List<ChatUser> members,
    required List<Token> tokens,
    required String groupName,
    required String groupImage,
    required bool isGroup
  }) async {
    try {
      String msgId = const Uuid().v4();
      PlatformFile? file = await mediaService.pickImageFromLibrary();
      if(file != null) { 
        List<dynamic> readers = [];
        List<dynamic> registrationIds = [];
        for (Token token in tokens) {
          registrationIds.add(token.token);
        }
        if(isGroup) {
          for (ChatUser member in members) {
            if(member.uid != authenticationProvider.userId()) {
              if(member.uid == currentUserIsRead) {
                readers.add({
                  "uid": member.uid,
                  "name": member.name,
                  "image": member.image,
                  "is_read": true,
                  "seen": DateTime.now(),
                  "created_at": DateTime.now()
                });
              } else {
                readers.add({
                  "uid": member.uid,
                  "name": member.name,
                  "image": member.image,
                  "is_read": false,
                  "seen": DateTime.now(),
                  "created_at": DateTime.now()
                });
              }
            }
          }
        } else {
          readers = [
            {
              "uid": authenticationProvider.userId(),
              "name": authenticationProvider.userName(),
              "image": authenticationProvider.userImage(),
              "is_read": true,
              "seen": DateTime.now(),
              "created_at": DateTime.now()
            },
            {
              "uid": receiverId,
              "name": receiverName,
              "image": receiverImage,
              "is_read": isRead,
              "seen": DateTime.now(),
              "created_at": DateTime.now()
            }
          ];
        }
        _messages!.insert(0,
          ChatMessage(
            uid: msgId,
            content: "loading-img", 
            senderId: authenticationProvider.userId(),
            senderName: authenticationProvider.userName(),
            receiverId: receiverId, 
            isRead: isRead ? true : false,
            softDelete: false,
            readers: [],
            readerCountIds: [],
            type: MessageType.image, 
            sentTime: DateTime.now()
          )
        );
        String? downloadUrl = await cloudStorageService.saveChatImageToStorage(chatId(), authenticationProvider.userId(), file);
        if(scrollController.hasClients) {
          scrollController.animateTo(0, 
            duration: const Duration(
              milliseconds: 300
            ), 
            curve: Curves.easeInOut
          );
        }
        ChatMessage messageToSend = ChatMessage(
          uid: msgId,
          content: downloadUrl!, 
          senderId: authenticationProvider.userId(),
          senderName: authenticationProvider.userName(),
          receiverId: receiverId,
          isRead: isRead ? true : false,
          softDelete: false,
          readers: [],
          readerCountIds: [],
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        try {      
          databaseService.addMessageToChat(
            context,
            msgId: msgId,
            chatId: chatId(),  
            isGroup: isGroup,
            message: messageToSend,
            currentUserId: authenticationProvider.userId(),
            userIdNotRead: userIdIsNotRead,
            readers: readers,
          ).then((_) async {
            await databaseService.updateMicroTask(chatId());
          });
        } catch(e) {
          debugPrint(e.toString());
        } 
        if(!isRead) {
          try {
            await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
              chatId: chatId(),
              registrationIds: registrationIds,
              token: token, 
              title: title,
              subtitle: subtitle,
              body: messageToSend.content, 
              receiverId: receiverId,
              receiverName: receiverName,
              receiverImage: receiverImage,
              groupImage: groupImage,
              groupName: groupName,
              isGroup: isGroup,
              type: "image"
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

  void isScreenOn({required String receiverId}) async {
    try {
      isScreenOnStream = databaseService.isScreenOn(chatId: chatId())!.listen((snapshot) {
        if(snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if(data["on_screens"].where((el) => el["user_id"] == receiverId).isNotEmpty) {
            token = data["on_screens"].firstWhere((el) => el["user_id"] == receiverId)["token"];
            isRead = data["on_screens"].firstWhere((el) => el["user_id"] == receiverId)["on"];
          } 
          if(data["on_screens"].where((el) => el["on"] == false).isNotEmpty) {
            userIdIsNotRead = [];
            for (var item in data["on_screens"].where((el) => el["on"] == false).toList()) {
              userIdIsNotRead.add(item["user_id"]);
            }
          }
          if(data["on_screens"].where((el) => el["user_id"] != userId() && el["on"] == true).isNotEmpty) {
            currentUserIsRead = data["on_screens"].firstWhere((el) => el["user_id"] != userId() && el["on"] == true)["user_id"];
          } else {
            currentUserIsRead = "";
          }
        }
        Future.delayed(Duration.zero, () => notifyListeners()); 
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen() async {
    try {
      await databaseService.joinScreen(
        chatId: chatId(),
        userId: authenticationProvider.userId()
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen() async {
    try {
      await databaseService.leaveScreen(
        chatId: chatId(),
        userId: authenticationProvider.userId()
      );
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

  Future<void> seeMsg({required String receiverId, required bool isGroup}) async {
    try {
      databaseService.seeMsg(
        chatId: chatId(),
        isGroup: isGroup,
        receiverId: receiverId,
        userId: authenticationProvider.userId(),
        userName: authenticationProvider.userName(),
        userImage: authenticationProvider.userImage(),
      ).then((_) async {
        await databaseService.updateMicroTask(chatId());
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> toggleIsActivity({required bool isActive, required String userId}) async {
    try {
      await databaseService.updateChatIsActivity(userId, chatId(), isActive);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(BuildContext context, {required String receiverId}) async {
    try {
      await databaseService.deleteChat(chatId());
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteMsgBulk({required bool softDelete}) async {
    try {
      for (ChatMessage item in selectedMessages) {
        databaseService.deleteMsgBulk(
          chatId: chatId(), 
          msgId: item.uid,
          softDelete: softDelete
        ).then((_) async {
          await databaseService.updateMicroTask(chatId());
        });
      }
      selectedMessages = [];
      Future.delayed(Duration.zero, () => notifyListeners());
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void isUserOnline({required String receiverId}) {
    try {
      isUserOnlineStream = databaseService.getChatUserOnline(receiverId)!.listen((snapshot) {
        isOnline = "";
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        ChatUser chatUser = ChatUser.fromJson(data);
        chatUser.isUserOnline() 
        ? isOnline = "ONLINE" 
        : isOnline = "OFFLINE";
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void isUserTyping() async {
    try {
      isUserTypingStream = databaseService.isUserTyping(chatId())!.listen((snapshot) {
        isTyping = "";
        if(snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if(data.isNotEmpty) {
            List<dynamic> isActivities = data["is_activity"];
            int index = isActivities.indexWhere((el) => el["is_active"] == true);
            if(index != -1) {
              if(isActivities[index]["is_active"] == true && isActivities[index]["user_id"] != userId()) {
                isTyping = isActivities[index]["is_group"] == true
                ? "${isActivities[index]["name"]} sedang menulis pesan..."
                : "Mengetik...";
              } 
            } else {
              isTyping = "";
            }
          }
        }
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  String userId() => sharedPreferences.getString("userId") ?? "";
  String userName() => sharedPreferences.getString("userName") ?? "";
  String chatId() => sharedPreferences.getString("chatId") ?? "";
}