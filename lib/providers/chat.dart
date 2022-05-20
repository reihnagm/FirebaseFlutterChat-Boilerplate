import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:chat/providers/chats.dart';
import 'package:chat/providers/firebase.dart';

import 'package:chat/models/chat.dart';
import 'package:chat/models/chat_user.dart';
import 'package:chat/models/chat_message.dart';

import 'package:chat/providers/authentication.dart';

import 'package:chat/services/debounce.dart';
import 'package:chat/services/cloud_storage.dart';
import 'package:chat/services/database.dart';
import 'package:chat/services/media.dart';
import 'package:chat/services/navigation.dart';

enum MessageStatus { idle, loading, loaded, empty, error }
enum FetchMessageStatus { idle, loading, loaded, empty, error }

class ChatProvider extends ChangeNotifier {

  final SharedPreferences sp;
  final AuthenticationProvider ap;
  final DatabaseService ds;
  final CloudStorageService css;
  final MediaService ms;
  final NavigationService ns;

  final Debounce debounce = Debounce(const Duration(milliseconds: 100));
 
  List userIdNotRead = [];

  MessageStatus _messageStatus = MessageStatus.idle;
  MessageStatus get messageStatus => _messageStatus;

  FetchMessageStatus _fetchMessageStatus = FetchMessageStatus.idle;
  FetchMessageStatus get fetchMessageStatus => _fetchMessageStatus;

  void clearMsgLimit() {
    limit = 0;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateMessageStatus(MessageStatus messageStatus) { 
    _messageStatus = messageStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateFetchMessageStatus(FetchMessageStatus fetchMessageStatus) {
    _fetchMessageStatus = fetchMessageStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

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
  int limit = 0;
  bool isRead = false;

  late ScrollController scrollController;
  late TextEditingController messageTextEditingController;
  
  FocusNode messageFocusNode = FocusNode();
  StreamSubscription? isScreenOnStream;
  StreamSubscription? isUserOnlineStream;
  StreamSubscription? isUserTypingStream;
  StreamSubscription? messageStream;

  @override
  void dispose() {
    messageStream?.cancel();
    isUserTypingStream?.cancel();
    isScreenOnStream?.cancel();
    isUserOnlineStream?.cancel();
    super.dispose();
  }

  ChatProvider({
    required this.sp,
    required this.ap, 
    required this.ds,
    required this.ms,
    required this.css,
    required this.ns
  }) {
    scrollController = ScrollController();
    messageTextEditingController = TextEditingController();
  }

  void addStreamMsg(String val) {
    Future.delayed(Duration.zero, () => notifyListeners());
  }

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
      messageStream = ds.streamMessagesForChat(chatId: chatId(), limit: 30).listen((snapshot) {
        _messages = [];
        List<ChatMessage> messages = snapshot.docs.map((m) {
          Map<String, dynamic> messageData = m.data();
          return ChatMessage.fromJSON(messageData);
        }).toList();
        _messages!.addAll(messages);
        setStateMessageStatus(MessageStatus.loaded);
      });
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  void fetchMessages(int limitParam) {
    limit += limitParam;
    Future.delayed(Duration.zero, () => notifyListeners());
    try { 
      setStateFetchMessageStatus(FetchMessageStatus.loading);
      messageStream = ds.streamMessagesForChat(chatId: chatId(), limit: limit).listen((snapshot) {
        List<ChatMessage> messages = snapshot.docs.map((m) {
          Map<String, dynamic> messageData = m.data();
          return ChatMessage.fromJSON(messageData);
        }).toList();
        _messages = messages; 
        setStateFetchMessageStatus(FetchMessageStatus.loaded);
        setStateMessageStatus(MessageStatus.loaded);
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void onChangeMsg(BuildContext context, String val) {
    debounce(() {
      toggleIsActivity(
        isActive: val.isNotEmpty ? true : false,
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
    required String groupName,
    required String groupImage,
    required bool isGroup
  }) async {
    
    await context.read<ChatsProvider>().getTokensByChat();
    
    List<ChatUser> members = context.read<ChatsProvider>().members;
    String msgId = const Uuid().v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List readers = [];
    List registrationIds = [];
    for (Token token in context.read<ChatsProvider>().tokens) {
      if(token.userId != ap.userId()) {
        registrationIds.add(token.token.toString().trim());
      }
    }
    if(isGroup) {
      for (ChatUser member in members) {
        if(member.uid != ap.userId()) {
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
          "uid": ap.userId(),
          "name": ap.userName(),
          "image": ap.userImage(),
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
      senderId: ap.userId(),
      senderName: ap.userName(),
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
      ds.addMessageToChat(
        context,
        msgId: msgId,
        chatId: chatId(), 
        isGroup: isGroup,
        message: messageToSend,
        currentUserId: ap.userId(),
        userIdNotRead: userIdNotRead,
        readers: readers,
      );
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
          tokens: context.read<ChatsProvider>().tokens,
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
    required String groupName,
    required String groupImage,
    required bool isGroup
  }) async {
    try {
      List<ChatUser> members = context.read<ChatsProvider>().members;
      List<Token> tokens = context.read<ChatsProvider>().tokens;
      String msgId = const Uuid().v4();
      PlatformFile? file = await ms.pickImageFromLibrary();
      if(file != null) { 
        List readers = [];
        List registrationIds = [];
        for (Token token in tokens) {
          registrationIds.add(token.token);
        }
        if(isGroup) {
          for (ChatUser member in members) {
            if(member.uid != ap.userId()) {
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
              "uid": ap.userId(),
              "name": ap.userName(),
              "image": ap.userImage(),
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
            senderId: ap.userId(),
            senderName: ap.userName(),
            receiverId: receiverId, 
            isRead: isRead ? true : false,
            softDelete: false,
            readers: [],
            readerCountIds: [],
            type: MessageType.image, 
            sentTime: DateTime.now()
          )
        );
        String? downloadUrl = await css.saveChatImageToStorage(chatId(), ap.userId(), file);
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
          senderId: ap.userId(),
          senderName: ap.userName(),
          receiverId: receiverId,
          isRead: isRead ? true : false,
          softDelete: false,
          readers: [],
          readerCountIds: [],
          type: MessageType.image, 
          sentTime: DateTime.now()
        );
        try {      
          ds.addMessageToChat(
            context,
            msgId: msgId,
            chatId: chatId(),  
            isGroup: isGroup,
            message: messageToSend,
            currentUserId: ap.userId(),
            userIdNotRead: userIdNotRead,
            readers: readers,
          ).then((_) async {
            await ds.updateMicroTask(chatId: chatId());
          });
        } catch(e, stacktrace) {
          debugPrint(stacktrace.toString());
        } 
        if(!isRead) {
          try {
            await Provider.of<FirebaseProvider>(context, listen: false).sendNotification(
              chatId: chatId(),
              registrationIds: registrationIds,
              tokens: tokens,
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
          } catch(e, stacktrace) {
            debugPrint(stacktrace.toString());
          } 
        }
        try {
          await loadSoundSent();
        } catch(e, stacktrace) {
          debugPrint(stacktrace.toString());
        }
      }
    } catch (e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  void isScreenOn({required String receiverId}) async {
    try {
      isScreenOnStream = ds.isScreenOn(chatId: chatId())!.listen((snapshot) {
        if(snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          if(data["on_screens"].where((el) => el["user_id"] == receiverId).isNotEmpty) {
            token = data["on_screens"].firstWhere((el) => el["user_id"] == receiverId)["token"];
            isRead = data["on_screens"].firstWhere((el) => el["user_id"] == receiverId)["on"];
          } 
          if(data["on_screens"].where((el) => el["on"] == false).isNotEmpty) {
            userIdNotRead = [];
            for (var item in data["on_screens"].where((el) => el["on"] == false && el["user_id"] != userId()).toList()) {
              userIdNotRead.add(item["user_id"]);
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
      await ds.joinScreen(
        chatId: chatId(),
        userId: ap.userId()
      );
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen() async {
    try {
      await ds.leaveScreen(
        chatId: chatId(),
        userId: ap.userId()
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
    return 0;
  }

  Future<void> seeMsg({required String receiverId, required bool isGroup}) async {
    try {
      ds.seeMsg(
        chatId: chatId(),
        isGroup: isGroup,
        receiverId: receiverId,
        userId: ap.userId(),
        userName: ap.userName(),
        userImage: ap.userImage(),
      ).then((_) async {
        await ds.updateMicroTask(chatId: chatId());
      });
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> toggleIsActivity({required bool isActive}) async {
    try {
      await ds.updateChatIsActivity(
        userId: userId(), 
        chatId: chatId(),
        isActive: isActive
      );
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> deleteChat(BuildContext context, {required String receiverId}) async {
    try {
      await ds.deleteChat(chatId: chatId());
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> deleteMsgBulk({required bool softDelete}) async {
    try {
      for (ChatMessage item in selectedMessages) {
        ds.deleteMsgBulk(
          chatId: chatId(), 
          msgId: item.uid,
          softDelete: softDelete
        ).then((_) async {
          await ds.updateMicroTask(chatId: chatId());
        });
        await ds.removeReaderCountIds(chatId: chatId());
      }
      selectedMessages = [];
      Future.delayed(Duration.zero, () => notifyListeners());
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void isUserOnline({required String receiverId}) {
    try {
      isUserOnlineStream = ds.getChatUserOnline(userId: receiverId).listen((snapshot) {
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

  Future<void> isUserTyping() async {
    try {
      isUserTypingStream = ds.isUserTyping(chatId: chatId()).listen((snapshot) {
        if(snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List isActivities = data["is_activity"];
          int index = isActivities.indexWhere((el) => el["is_active"] == true && el["user_id"] != userId());
          if(index != -1) {
            isTyping = isActivities[index]["is_group"] == true
            ? "${isActivities[index]["name"]} sedang menulis pesan..."
            : "Mengetik...";
          } else {
            isTyping = "";
          }
          Future.delayed(Duration.zero, () => notifyListeners());
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  String userId() => sp.getString("userId") ?? "";
  String userName() => sp.getString("userName") ?? "";
  String chatId() => sp.getString("chatId") ?? "";
}