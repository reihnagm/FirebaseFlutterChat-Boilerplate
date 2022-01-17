import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String conversationCollection = "Conversations";
const String usersOnlineCollection = "UsersOnline";
const String onScreenCollection = "OnScreens";
const String conversationsCollection = "Conversations";
const String chatCollection = "Chats";
const String messageCollection = "Messages"; 

class DatabaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

   Future<void> register(String uid, String name, String email, String imageUrl) async {
    try{  
      return await db.collection(userCollection).doc(uid).set({
        "name": name,
        "email": email, 
        "image": imageUrl,
        "last_active": DateTime.now().toUtc(),
        "isOnline": true,
        "token": await FirebaseMessaging.instance.getToken()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<DocumentSnapshot>? getUser(String uid) {
    try{
      return db
      .collection(userCollection)
      .doc(uid)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? getChatUserOnline(String uid) {
    try{
      return db
      .collection(userCollection)
      .doc(uid)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? isUserTyping(String chatId) {
    try{
      return db
      .collection(chatCollection)
      .doc(chatId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot>? getChatsForUser(String userId) {
    try {
      return db
      .collection(chatCollection)
      .where('relations', arrayContains: userId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    } 
  }

  Stream<QuerySnapshot>? streamMessagesForChat(String chatId) {
    try {
      return db.collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .orderBy("sent_time", descending: true)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot>? getLastMessageForChat(String chatId) {
    try {
      return db.collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .orderBy("sent_time", descending: true)
      .limit(1)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot>? getMessageCountForChat(String chatId) {
    try {
      return db
      .collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .orderBy("sent_time", descending: true)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot> getUsers({String? name}) {
    Query query = db.collection(userCollection);
    if(name != null) {
      query = query.where("name", isGreaterThanOrEqualTo: name)
      .where("name", isLessThanOrEqualTo: name + "z");
    }
    return query.snapshots();
  }

  Future<QuerySnapshot?> readerCountIds({required String chatId, required String userId}) async {
    try {
      QuerySnapshot readerCountIds = await db
      .collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .where("readerCountIds", arrayContains: userId)
      .get();
      return readerCountIds;
    } catch(e) {  
      debugPrint(e.toString());
    }
  }

  Future<void> addMessageToChat(
    BuildContext context,
  {
    required String msgId,
    required String chatId, 
    required ChatMessage message, 
    required bool isGroup, 
    required String currentUserId,
    required List<dynamic> readers,
    required List<dynamic> userIdNotRead,
  }) async {
    String messageType;
    switch (message.type) {
      case MessageType.text: 
        messageType = "text";
      break;
      case MessageType.image:
        messageType = "image";
      break;
      default:
        messageType = "";
    }
    try { 
      String msgId = const Uuid().v4();
      db.collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .doc(msgId)
      .set({
        "uid": msgId,
        "content": message.content,
        "type": messageType,
        "sender_id": message.senderId,
        "sender_name": message.senderName,
        "receiver_id": message.receiverId,
        "is_read": isGroup ? false : message.isRead,
        "soft_delete": message.softDelete,
        "sent_time": message.sentTime,
        "readers": readers,
        "readerCountIds": isGroup ? userIdNotRead : []
      }).then((_) async {
        DocumentSnapshot doc = await db.collection(chatCollection).doc(chatId).get();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> isActivity = data["is_activity"];
        int index = isActivity.indexWhere((el) => el["user_id"] == currentUserId && el["chat_id"] == chatId);
        isActivity[index]["is_active"] = false;
        doc.reference.update({
          "is_activity": isActivity
        });
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteMsgBulk({required String chatId, required String msgId, required bool softDelete}) async {
    try {
      if(softDelete) {
        await db
        .collection(chatCollection)
        .doc(chatId)
        .collection(messageCollection)
        .doc(msgId)
        .update({
          "soft_delete": softDelete
        });
      } 
      else {
        await db
        .collection(chatCollection)
        .doc(chatId)
        .collection(messageCollection)
        .doc(msgId)
        .delete();
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateChatIsActivity(String userId, String chatId, bool isActive) async {
    try { 
      DocumentSnapshot doc = await db.collection(chatCollection).doc(chatId).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> isActivity = data["is_activity"];
      int index = isActivity.indexWhere((el) => el["user_id"] == userId && el["chat_id"] == chatId);
      isActivity[index]["is_active"] = isActive;
      doc.reference.update({
        "is_activity": isActivity
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateUserLastSeenTime(String uid) async {
    try {
      await db
      .collection(userCollection)
      .doc(uid)
      .update({
        "last_active": DateTime.now().toUtc()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateMicroTask(String chatId) async {
    try {
      await db
      .collection(chatCollection)
      .doc(chatId)
      .update({
        "updated_at": DateTime.now().toUtc()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> seeMsg({
    required String chatId, 
    required String receiverId, 
    required String userId,
    required String userName,
    required String userImage,
    required bool isGroup
  }) async {
    try {
      QuerySnapshot<Map<String, dynamic>> msg = await db
      .collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .get();
      try {
        if(isGroup) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
            DocumentSnapshot<Map<String, dynamic>> msgDoc1 = await db
            .collection(chatCollection)
            .doc(chatId)
            .collection(messageCollection)
            .doc(msgDoc.id)
            .get();
            Map<String, dynamic> msgObj = msgDoc1.data() as Map<String, dynamic>;

            List<dynamic> readers = msgObj["readers"];
            int indexReader = readers.indexWhere((el) => el["uid"] == userId);

            if(msgObj["sender_id"] != userId) {         
              if(indexReader != -1) { 
                readers[indexReader]["seen"] = DateTime.now();
                readers[indexReader]["is_read"] = true;
                msgDoc.reference.update({
                  "readerCountIds": FieldValue.arrayRemove([userId]),
                  "readers": readers               
                }); // Update existing data
              } else {
                msgDoc.reference.update({
                  "readerCountIds": FieldValue.arrayRemove([userId]),
                  "readers": [{
                    "uid": readers[indexReader]["uid"],
                    "name": readers[indexReader]["name"],
                    "image": readers[indexReader]["image"],
                    "is_read": readers[indexReader]["is_read"],
                    "seen": readers[indexReader]["seen"]
                  }]
                });
              }
            } else {
              msgDoc.reference.update({
                "content": msgObj["content"],
                "type": msgObj["type"],
                "sender_name": msgObj["sender_name"],
                "receiver_id": msgObj["receiver_id"],
                "is_read": msgObj["is_read"],
                "sent_time": Timestamp.fromDate(msgObj["sent_time"].toDate()),             
              });
            }
          }         
        }
        if(isGroup) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
            Map<String, dynamic> msgObj = msgDoc.data();
            List<dynamic> readers = msgObj["readers"];
            if(readers.every((el) => el["is_read"] == true)) {
              msgDoc.reference.update({"is_read": true});
            }
          }
        } else {
          List<dynamic> data = msg.docs
          .where((el) => el["receiver_id"] == userId)
          .where((el) => el["is_read"] == false).toList();
          if(data.isNotEmpty) {
            for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
              Map<String, dynamic> msgObj = msgDoc.data();
              List<dynamic> readers = msgObj["readers"];
              int readerIndex = readers.indexWhere((el) => el["uid"] == userId);
              if(readerIndex != -1) {
                readers[readerIndex]["is_read"] = true;
                msgDoc.reference.update({
                  "is_read": true,
                  "readers": readers                      
                }); // Update existing data
              } else {
                msgDoc.reference.update({
                  "is_read": true,
                  "readers": [{
                    "uid": readers[readerIndex]["uid"],
                    "name": readers[readerIndex]["name"],
                    "image": readers[readerIndex]["image"],
                    "is_read": readers[readerIndex]["is_read"],
                    "seen": readers[readerIndex]["seen"],
                  }]
                });
              }
            }
          }
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateUserOnlineToken(String userId, bool isOnline) async {
    try {
      db
      .collection(userCollection)
      .doc(userId)
      .update({
        "isOnline": isOnline
      }).then((_) async {
        await db
        .collection(userCollection)
        .doc(userId)
        .update({
          "token": await FirebaseMessaging.instance.getToken()
        });
      }).then((_) async {
        QuerySnapshot<Map<String, dynamic>> onscreens = await db
        .collection(onScreenCollection)
        .get();
         QuerySnapshot<Map<String, dynamic>> chats = await db
        .collection(chatCollection)
        .get();
        if(onscreens.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> screenDoc in onscreens.docs) {
            List<dynamic> onscreens = screenDoc.data()["on_screens"];
            int index = onscreens.indexWhere((el) => el["user_id"] == userId);
            if(index != -1) {
              onscreens[index]["token"] = await FirebaseMessaging.instance.getToken();
              screenDoc.reference.update({
                "on_screens": onscreens
              }); // Update existing data
            } 
          }
        }
        if(chats.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> chatDoc in chats.docs) {
            Map<String, dynamic> group = chatDoc.data()["group"];
            List<dynamic> tokens = group["tokens"];
            int index = tokens.indexWhere((el) => el["user_id"] == userId);
            if(index != -1) {
              tokens[index]["token"] = await FirebaseMessaging.instance.getToken();
              chatDoc.reference.update({
                "group": {
                  "name": group["name"],
                  "image": group["image"],
                  "tokens": tokens
                }
              }); // Update existing data
            } 
          }
        }
      }).then((_) async {
        await updateUserLastSeenTime(userId);
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? isScreenOn({required String chatId}) {
    try {
      return db
      .collection(onScreenCollection)
      .doc(chatId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> checkConversation(String userId) async {
    try {
      return await db
      .collection(chatCollection)
      .where("relations", arrayContains: userId)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<DocumentSnapshot?> checkChat(String chatId) async {
    try {
      return await db
      .collection(chatCollection)
      .doc(chatId)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createChat(String chatId, Map<String, dynamic> data) async {
    try {
      return await db
      .collection(chatCollection)
      .doc(chatId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createConversation(String userId, Map<String, dynamic> data) async {
    try {
      return await db
      .collection(conversationCollection)
      .doc(userId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createChatGroup(String chatId, Map<String, dynamic> data) async {
    try {
      return await db
      .collection(chatCollection)
      .doc(chatId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createOnScreens(String chatId, Map<String, dynamic> data) async {
    try {
      return await db
      .collection(onScreenCollection)
      .doc(chatId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(String chatId) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      QuerySnapshot<Map<String, dynamic>> chatData = await db.collection(chatCollection).doc(chatId).collection(messageCollection).get();
      DocumentSnapshot<Map<String, dynamic>> onScreens = await db.collection(onScreenCollection).doc(chatId).get();
      batch.delete(onScreens.reference);
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in chatData.docs) {
        batch.delete(item.reference);
      }
      batch.commit();
      Future.delayed(Duration.zero, () async {
        try {
          await db.collection(chatCollection).doc(chatId).delete();
        } catch(e) {
          debugPrint(e.toString());
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen({required String chatId, required String userId}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .doc(chatId).get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["user_id"] == userId);
      if(index != -1) {
        onScreens[index]["on"] = true;
        onScreens[index]["token"] = await FirebaseMessaging.instance.getToken();
        data.reference.update({
          "on_screens": onScreens
        }); // Update existing data
      } else {
        data.reference.update({
          "on_screens": [{
            "user_id": userId,
            "on": true,
          }]
        });
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen({required String chatId, required String userId}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .doc(chatId)
      .get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["user_id"] == userId);
      if(index != -1) {
        onScreens[index]["on"] = false;
        data.reference.update({
          "id": chatId,
          "on_screens": onScreens
        }); // Update existing data
      } else {
        data.reference.update({
          "id": chatId,
          "on_screens": {
            "on": onScreens[index]["on"],
            "token": onScreens[index]["token"],
            "user_id": onScreens[index]["user_id"] 
          }
        }); 
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}