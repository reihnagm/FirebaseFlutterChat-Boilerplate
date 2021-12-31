import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String chatCollection = "Chats";
const String messageCollection = "Messages"; 

class DatabaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<DocumentSnapshot>? getUser(String uid) {
    try{
      return db.collection(userCollection).doc(uid).get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot> getChatsForUser(String userUid) {
    return db.collection(chatCollection)
    .where('relations', arrayContains: userUid)
    .snapshots();
  }

  Stream<QuerySnapshot> streamMessagesForChat(String chatID) {
    return db.collection(chatCollection)
    .doc(chatID)
    .collection(messageCollection)
    .orderBy("sent_time", descending: false)
    .snapshots();
  }

  Future<QuerySnapshot> getLastMessageForChat(String chatID) {
    return db.collection(chatCollection)
    .doc(chatID)
    .collection(messageCollection)
    .orderBy("sent_time", descending: true)
    .limit(1)
    .get();
  }

  Stream<QuerySnapshot> getUsers({String? name}) {
    Query query = db.collection(userCollection);
    if(name != null) {
      query = query.where("name", isGreaterThanOrEqualTo: name)
      .where("name", isLessThanOrEqualTo: name + "z");
    }
    return query.snapshots();
  }

  Future<void> addMessageToChat(String chatUid, String receiverId, ChatMessage message) async {
    try { 
      DocumentReference doc = await db.collection(chatCollection)
      .doc(chatUid)
      .collection(messageCollection)
      .add(message.toJson());
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await db.collection(chatCollection)
          .doc(chatUid)
          .update({
            "readers": FieldValue.arrayUnion([{
              "message_id": doc.id,
              "receiver_id": receiverId,
              "is_read": message.isRead
            }])
          });
        } catch(e) {
          debugPrint(e.toString());
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateChatData(String chatID, Map<String, dynamic> data) async {
    try { 
      await db.collection(chatCollection).doc(chatID).update(data);
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

  Future<void> seeMsg({required String chatUid, required String senderId, required String userUid}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> msg = await db
      .collection(chatCollection)
      .doc(chatUid)
      .collection(messageCollection)
      .where("sender_id", isEqualTo: senderId)
      .where("is_read", isEqualTo: false)
      .get();
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          QuerySnapshot<Map<String, dynamic>> chat = await db
          .collection(chatCollection)
          .get();
          for (QueryDocumentSnapshot<Map<String, dynamic>> doc in chat.docs) {
            List<dynamic> readers = doc.data()["readers"];
            List<dynamic> chatCountRead = [];
            List<dynamic> checkReaders = readers.where((el) => el["receiver_id"] == userUid).where((el) => el["is_read"] == false).toList();
            if(checkReaders.isNotEmpty) {
              for (var reader in checkReaders) {
                reader["is_read"] = true;
                chatCountRead.add(reader);  
              }     
              doc.reference.update({
                "readers": chatCountRead
              }); 
            }
          }
          for (QueryDocumentSnapshot<Map<String, dynamic>> doc in msg.docs) {
            doc.reference.update({"is_read": true});
          }
        } catch(_) {}
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateUserToken(String uid, String? token) async {
    try {
      await db.collection(userCollection).doc(uid).update({
        "token": token
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateUserOnline(String userUid, bool isOnline) async {
    try {
      await db
      .collection(userCollection)
      .doc(userUid)
      .update({
        "isOnline": isOnline
      });
      Future.delayed(const Duration(seconds: 1), () async {
        QuerySnapshot<Map<String, dynamic>> data = await db
        .collection(chatCollection)
        .where("relations", arrayContains: userUid)
        .get();
        for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
          List<dynamic> members = doc.data()["members"];
          int index = members.indexWhere((el) => el["uid"] == userUid);
          members[index]["isOnline"] = isOnline;
          doc.reference.update({
            "members": members
          });
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> checkCreateChat(String uid) async {
    try {
      return await db
      .collection(chatCollection)
      .where("relations", arrayContains: uid)
      .get();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<List<dynamic>?> isScreenOn({required String chatUid}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await db.collection(chatCollection).doc(chatUid).get();
      List<dynamic> onScreens = doc.data()!["on_screens"];
      return onScreens;
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<DocumentReference?> createChat(Map<String, dynamic> data) async {
    try {
      return await db
      .collection(chatCollection)
      .add(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(String chatID) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db.collection(chatCollection).doc(chatID).collection(messageCollection).get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
        batch.delete(item.reference);
      }
      batch.commit();
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await db.collection(chatCollection).doc(chatID).delete();
        } catch(e) {
          debugPrint(e.toString());
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen({required String token, required String chatUid, required String userUid}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .doc(chatUid)
      .get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
      if(index != -1) {
        onScreens[index]["on"] = true;
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await db
            .collection(chatCollection)
            .doc(chatUid)
            .update({
              "on_screens": onScreens
            });
          } catch(e) {
            debugPrint(e.toString());
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await db
            .collection(chatCollection)
            .doc(chatUid)
            .update({
              "on_screens": FieldValue.arrayUnion([{
                "userUid": userUid,
                "on": true,
                "token": token
              }])
            });
          } catch(e) {
            debugPrint(e.toString());
          }
        });
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen({required String chatUid, required String userUid}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .doc(chatUid)
      .get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
      onScreens[index]["on"] = false;
      Future.delayed(const Duration(seconds: 1), () async {
        await db
        .collection(chatCollection)
        .doc(chatUid)
        .update({
          "on_screens": onScreens
        });
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}