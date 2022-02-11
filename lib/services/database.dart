import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String usersOnlineCollection = "UsersOnline";
const String onScreenCollection = "OnScreens";
const String chatCollection = "Chats";
const String messageCollection = "Messages"; 
const String tokenCollection = "Tokens";
const String membersCollection = "Members";
const String readerCountIdsCollection = "ReaderCountIds";


class DatabaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

   Future<void> register({required String uid, required String name, required String email, required String imageUrl}) async {
    try{  
      return await db
      .collection(userCollection)
      .doc(uid)
      .set({
        "name": name,
        "email": email, 
        "image": imageUrl,
        "last_active": DateTime.now(),
        "isOnline": true,
        "token": await FirebaseMessaging.instance.getToken()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> insertTokens({required String chatId, required Map<String, dynamic> data}) async {
    try {
      return await db
      .collection(tokenCollection)
      .doc(chatId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> insertMembers({required String chatId, required Map<String, dynamic> data}) async {
    try {
      return await db
      .collection(membersCollection)
      .doc(chatId)
      .set(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }


  Future<DocumentSnapshot>? getUser({required String userId}) {
    try{
      return db
      .collection(userCollection)
      .doc(userId)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? getChatUserOnline({required String userId}) {
    try{
      return db
      .collection(userCollection)
      .doc(userId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? isUserTyping({required String chatId}) {
    try{
      return db
      .collection(chatCollection)
      .doc(chatId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot>? getChatsForUser({required String userId}) {
    try {
      return db
      .collection(chatCollection)
      .where('relations', arrayContains: userId)
      .snapshots()
      .distinct();
    } catch(e) {
      debugPrint(e.toString());
    } 
  }

  Stream<QuerySnapshot>? streamMessagesForChat({required String chatId, required int limit}) {
    try {
      return db.collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .orderBy("sent_time", descending: true)
      .limit(limit)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? getMembersChat({required String chatId}) {
    try {
      return db
      .collection(membersCollection)
      .doc(chatId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? getTokensChat({required String chatId}) {
    try {
      return db
      .collection(tokenCollection)
      .doc(chatId)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot>? getLastMessageForChat({required String chatId}) {
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

  Future<QuerySnapshot>? getMessageCountForChat({required String chatId }) {
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
    required List readers,
    required List userIdNotRead,
  }) async {
    String messageType;
    String msgId = const Uuid().v4();

    WriteBatch batch = FirebaseFirestore.instance.batch();

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
  
    DocumentReference readerCountIdsDoc = db
    .collection(readerCountIdsCollection)
    .doc(msgId);
    DocumentReference msgDoc = db.collection(chatCollection)
    .doc(chatId)
    .collection(messageCollection)
    .doc(msgId);
    DocumentSnapshot chatDoc = await db
    .collection(chatCollection)
    .doc(chatId)
    .get();

    batch.set(readerCountIdsDoc, {
      "chat_id": chatId,
      "readerCountIds": isGroup ? userIdNotRead : [],
      "is_read": message.isRead,
      "is_group": isGroup ? true : false,
      "receiver_id": message.receiverId
    });

    batch.set(msgDoc, {
      "uid": msgId,
      "content": message.content,
      "type": messageType,
      "sender_id": message.senderId,
      "sender_name": message.senderName,
      "receiver_id": message.receiverId,
      "is_read": isGroup ? false : message.isRead,
      "is_group": isGroup ? true : false,
      "soft_delete": message.softDelete,
      "sent_time": message.sentTime,
      "readers": readers,
      "readerCountIds": isGroup ? userIdNotRead : []
    });
    try { 
      Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
      List members = data["members"];
      List membersAssign = [];
      for (var isActivity in members) {
        membersAssign.add({
          "chat_id": chatId,  
          "is_active": false,
          "is_group": isGroup,
          "name": isActivity["name"],
          "user_id": isActivity["uid"]
        });
        batch.update(chatDoc.reference, {
          "is_activity": membersAssign
        });
      }
      batch.commit();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateChatIsActivity(String userId, String chatId, bool isActive) async {
    try { 
      DocumentSnapshot doc = await db.collection(chatCollection).doc(chatId).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List isActivity = data["is_activity"];
      int index = isActivity.indexWhere((el) => el["user_id"] == userId && el["chat_id"] == chatId);
      isActivity[index]["is_active"] = isActive;
      doc.reference.update({
        "is_activity": isActivity
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateUserLastSeenTime({required String userId}) async {
    try {
      await db
      .collection(userCollection)
      .doc(userId)
      .update({
        "last_active": DateTime.now()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateMicroTask({required String chatId}) async {
    try {
      await db
      .collection(chatCollection)
      .doc(chatId)
      .update({
        "updated_at": DateTime.now()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> removeReaderCountIds({required String chatId}) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      QuerySnapshot<Map<String, dynamic>> qs =  await db
      .collection(readerCountIdsCollection)
      .where("chat_id", isEqualTo: chatId)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in qs.docs) {
        batch.delete(doc.reference);
      }
      batch.commit();
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
      QuerySnapshot<Map<String, dynamic>> readerCountIds = await db
      .collection(readerCountIdsCollection)
      .where("chat_id", isEqualTo: chatId)
      .get();
      try {
        if(isGroup) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> readerCountId in readerCountIds.docs) {
            Map<String, dynamic> readerCountIdsObj = readerCountId.data(); 
            bool isGroup = readerCountIdsObj["is_group"];
            if(isGroup) {
              readerCountId.reference.update({ 
                "readerCountIds": FieldValue.arrayRemove([userId]),
              });
            } else {
              readerCountId.reference.update({
                "is_read": true
              });
            }
          }

          for (QueryDocumentSnapshot<Map<String, dynamic>> msg in msg.docs) {
            Map<String, dynamic> msgObj = msg.data();
            List readers = msgObj["readers"];
            int indexReader = readers.indexWhere((el) => el["uid"] == userId);

            if(msgObj["sender_id"] != userId) {         
              if(indexReader != -1) { 
                readers[indexReader]["seen"] = DateTime.now();
                readers[indexReader]["is_read"] = true;
                msg.reference.update({
                  "readerCountIds": FieldValue.arrayRemove([userId]),
                  "readers": readers               
                }); // Update existing data
              } else {
                msg.reference.update({
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
            } 
            if(readers.every((el) => el["is_read"] == true)) {
              msg.reference.update({"is_read": true});
            }
          }      
        } else {
          List data = msg.docs
          .where((el) => el["receiver_id"] == userId)
          .where((el) => el["is_read"] == false).toList();
          if(data.isNotEmpty) {
            for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
              Map<String, dynamic> msgObj = msgDoc.data();
              List readers = msgObj["readers"];
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
      });
        DocumentSnapshot<Map<String, dynamic>> user = await db
        .collection(userCollection)
        .doc(userId)
        .get();
        QuerySnapshot<Map<String, dynamic>> tokens = await db
        .collection(tokenCollection)
        .get();
        QuerySnapshot<Map<String, dynamic>> onscreens = await db
        .collection(onScreenCollection)
        .get();
        QuerySnapshot<Map<String, dynamic>> members = await db
        .collection(membersCollection)
        .get();
        
        user.reference.update({
         "last_active": DateTime.now()
        });

        if(tokens.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> tokenDoc in tokens.docs) {
            List tokens = tokenDoc.data()["tokens"];
            if(tokens.where((el) => el["user_id"] == userId).isNotEmpty) {
              int index = tokens.indexWhere((el) => el["user_id"] == userId);
              tokens[index]["token"] = await FirebaseMessaging.instance.getToken();
              tokenDoc.reference.update({
                "tokens": tokens
              }); 
            }
          }
        }

        if(onscreens.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> screenDoc in onscreens.docs) {
            List onscreens = screenDoc.data()["on_screens"];
            if(onscreens.where((el) => el["user_id"] == userId).isNotEmpty) {
              int index = onscreens.indexWhere((el) => el["user_id"] == userId);
              onscreens[index]["token"] = await FirebaseMessaging.instance.getToken();
              screenDoc.reference.update({
                "on_screens": onscreens
              });
            }
          }
        }
        
        if(members.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> memberDoc in members.docs) {
            List members = memberDoc.data()["members"];
            if(members.where((el) => el["uid"] == userId).isNotEmpty) {
              int index = members.indexWhere((el) => el["uid"] == userId);
              members[index]["isOnline"] = isOnline;
              members[index]["last_active"] = DateTime.now();
              memberDoc.reference.update({
                "members": members
              });
            }
          }
        }
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

  Future<DocumentSnapshot?> checkChat({required String chatId}) async {
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

  Future<void> deleteChat({ required String chatId}) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      QuerySnapshot<Map<String, dynamic>> messages = await db.collection(chatCollection).doc(chatId).collection(messageCollection).get();
      DocumentSnapshot<Map<String, dynamic>> chats = await db.collection(chatCollection).doc(chatId).get();
      DocumentSnapshot<Map<String, dynamic>> onScreens = await db.collection(onScreenCollection).doc(chatId).get();
      DocumentSnapshot<Map<String, dynamic>> members = await db.collection(membersCollection).doc(chatId).get();
      DocumentSnapshot<Map<String, dynamic>> tokens = await db.collection(tokenCollection).doc(chatId).get();

      QuerySnapshot<Map<String, dynamic>> readerCountIds = await db.collection(readerCountIdsCollection).where("chat_id", isEqualTo: chatId).get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in readerCountIds.docs) {
        batch.delete(doc.reference);
      }
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in messages.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(onScreens.reference);
      batch.delete(members.reference);
      batch.delete(tokens.reference);
      batch.delete(chats.reference);
      batch.commit();
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
      } else {
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

  Future<void> joinScreen({required String chatId, required String userId}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .doc(chatId).get();
      List onScreens = data.data()!["on_screens"];
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
      List onScreens = data.data()!["on_screens"];
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