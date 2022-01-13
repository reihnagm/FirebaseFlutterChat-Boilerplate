import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String usersOnlineCollection = "UsersOnline";
// const String memberCollection = "Members";
// const String readersCollection = "Readers";
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
      return db.collection(userCollection).doc(uid).get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? getChatUserOnline(String uid) {
    try{
      return db.collection(userCollection).doc(uid).snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<DocumentSnapshot>? isUserTyping(String chatId) {
    try{
      return db.collection(chatCollection).doc(chatId).snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot>? getChatsForUser(String userId) {
    try {
      return db.collection(chatCollection)
      .where('relations', arrayContains: userId)
      .snapshots()
      .distinct();
    } catch(e) {
      debugPrint(e.toString());
    } 
  }

  Stream<QuerySnapshot> streamMessagesForChat(String chatId) {
    return db.collection(chatCollection)
    .doc(chatId)
    .collection(messageCollection)
    .orderBy("sent_time", descending: false)
    .snapshots();
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
      return db.collection(chatCollection)
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

  Future<QuerySnapshot?> readerCountIds({required String chatUid, required String userUid}) async {
    try {
      QuerySnapshot readerCountIds = await db
      .collection(chatCollection)
      .doc(chatUid)
      .collection(messageCollection)
      .where("readerCountIds", arrayContains: userUid)
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
    required List<String> uids, 
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
        "is_read": message.isRead,
        "soft_delete": message.softDelete,
        "sent_time": message.sentTime,
        "readers": readers,
        "readerCountIds": uids,
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
    // .add(message.toJson());
    } catch(e) {
      debugPrint(e.toString());
    }
    // await db.collection(chatCollection)
    // .doc(chatId).update({
    //   "updated_at": DateTime.now()
    // }); 
    // Trigger data changes
  }

  Future<void> deleteMsg({required String chatId, required String msgId, required bool softDelete}) async {
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

  Future<void> updateChatData(String userId, String chatId, bool isActive) async {
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
      await db.collection(userCollection).doc(uid).update({
        "last_active": DateTime.now().toUtc()
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> seeMsg({
    required String chatId, 
    required String receiverId, 
    required String userUid,
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
            .doc(msgDoc.id).get();
            Map<String, dynamic> msgObj = msgDoc1.data() as Map<String, dynamic>;

            List<dynamic> readers = msgObj["readers"];
            int indexReader = readers.indexWhere((el) => el["uid"] == userUid);

            if(msgObj["sender_id"] != userUid) {         
              if(indexReader != -1) {  
                // if(readers[indexReader]["is_read"] == false) {
                //   readers[indexReader]["seen"] = DateTime.now();
                //   await db.collection(chatCollection)
                //   .doc(chatId).update({
                //     "updated_at": DateTime.now()
                //   });
                // }
                //  Trigger data changes
                readers[indexReader]["is_read"] = true;
                msgDoc.reference.update({
                  "readerCountIds": FieldValue.arrayRemove([userUid]),
                  "readers": readers               
                }); // Update existing data
              } else {
                msgDoc.reference.update({
                  "readerCountIds": FieldValue.arrayRemove([userUid]),
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
          .where((el) => el["receiver_id"] == userUid)
          .where((el) => el["is_read"] == false).toList();
          if(data.isNotEmpty) {
            for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
              Map<String, dynamic> msgObj = msgDoc.data();
              List<dynamic> readers = msgObj["readers"];
              int readerIndex = readers.indexWhere((el) => el["uid"] == userUid);
              if(readerIndex != -1) {
                // if(readers[readerIndex]["is_read"] == false) {
                //   await db.collection(chatCollection)
                //   .doc(chatId).update({
                //     "updated_at": DateTime.now()
                //   });
                // } 
                //  Trigger data changes
                readers[readerIndex]["is_read"] = true;
                msgDoc.reference.update({
                  "is_read": true,
                  "readers": readers                      
                }); // Update existing data
              } else {
                // if(readers[readerIndex]["is_read"] == false) {
                //   await db.collection(chatCollection)
                //   .doc(chatId).update({
                //     "updated_at": DateTime.now()
                //   });
                // }
                // } Trigger data changes
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

  Future<void> updateUserOnlineToken(String userUid, bool isOnline) async {
    try {
      db
      .collection(userCollection)
      .doc(userUid)
      .update({
        "isOnline": isOnline
      }).then((_) async {
        await db
        .collection(userCollection)
        .doc(userUid)
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
            int index = onscreens.indexWhere((el) => el["userUid"] == userUid);
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
            int index = tokens.indexWhere((el) => el["userUid"] == userUid);
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
        await updateUserLastSeenTime(userUid);
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot>? isScreenOn({required String chatUid}) {
    try {
      return db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .snapshots();
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

  Future<DocumentReference?> createOnScreens(Map<String, dynamic> data) async {
    try {
      return await db
      .collection(onScreenCollection)
      .add(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(String chatId) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      QuerySnapshot<Map<String, dynamic>> chatData = await db.collection(chatCollection).doc(chatId).collection(messageCollection).get();
      QuerySnapshot<Map<String, dynamic>> onScreens = await db.collection(onScreenCollection).where("id", isEqualTo: chatId).get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in onScreens.docs) {
        batch.delete(item.reference);
      }
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

  Future<void> joinScreen({required String chatUid, required String userUid}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
        List<dynamic> onScreens = item.data()["on_screens"];
        int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
        if(index != -1) {
          onScreens[index]["on"] = true;
          onScreens[index]["token"] = await FirebaseMessaging.instance.getToken();
          item.reference.update({
            "on_screens": onScreens
          }); // Update existing data
        } else {
          item.reference.update({
            "on_screens": [{
              "userUid": userUid,
              "on": true,
            }]
          });
        }
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen({required String chatUid, required String userUid}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .get();
      if(data.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
          List<dynamic> onScreens = item.data()["on_screens"];
          int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
          if(index != -1) {
            onScreens[index]["on"] = false;
            item.reference.update({
              "id": chatUid,
              "on_screens": onScreens
            }); // Update existing data
          } else {
            item.reference.update({
              "id": chatUid,
              "on_screens": {
                "on": onScreens[index]["on"],
                "token": onScreens[index]["token"],
                "userUid": onScreens[index]["userUid"] 
              }
            }); 
          }
        }
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}