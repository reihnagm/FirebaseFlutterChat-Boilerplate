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

  Stream<QuerySnapshot> getChatsForUser(String uid) {
    return db.collection(chatCollection)
    .where('relations', arrayContains: uid)
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

  Future<void> addMessageToChat(String chatID, ChatMessage message) async {
    try { 
      await db.collection(chatCollection)
      .doc(chatID)
      .collection(messageCollection)
      .add(message.toJson());
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

  Future<void> seeMsg(String uid, String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .doc(uid)
      .collection(messageCollection)
      .where("sender_id", isEqualTo: userId)
      .where("is_read", isEqualTo: false)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
        doc.reference.update({"is_read": true});
      }
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

  Future<void> updateUserOnline(String uid, bool isOnline) async {
    try {
      await db.collection(userCollection).doc(uid).update({
        "isOnline": isOnline
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchListChattedMessage(String uid) async {
    return await db.collection(chatCollection).doc(uid).collection(messageCollection).get();
  }

  Future<void> setRelationUserOnline(String uid, bool isOnline) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .where("relations", arrayContains: uid)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
        List<dynamic> members = doc.data()["members"];
        int index = members.indexWhere((el) => el["uid"] == uid);
        members[index]["isOnline"] = isOnline;
        db
        .collection(chatCollection)
        .doc(doc.id)
        .update({
          "members": members
        });
      }
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

  Future<bool?> isScreenOn({required String chatUid, required String userUid}) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await db.collection(chatCollection).doc(chatUid).get();
    List onScreens = doc.data()!["on_screens"];
    return onScreens.where((el) => el["userUid"] == userUid).first["on"];
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
      await db.collection(chatCollection).doc(chatID).delete();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> joinScreen(String chatUid, String userUid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .doc(chatUid)
      .get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
      if(index != -1) {
        onScreens[index]["on"] = true;
        await db
        .collection(chatCollection)
        .doc(chatUid)
        .update({
          "on_screens": onScreens
        });
      } else {
        await db
        .collection(chatCollection)
        .doc(chatUid)
        .update({
          "on_screens": FieldValue.arrayUnion(
            [
              {
                "userUid": userUid,
                "on": true
              }
            ]
          )
        });
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> leaveScreen(String chatUid, String userUid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data = await db
      .collection(chatCollection)
      .doc(chatUid)
      .get();
      List<dynamic> onScreens = data.data()!["on_screens"];
      int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
      onScreens[index]["on"] = false;
      await db
      .collection(chatCollection)
      .doc(chatUid)
      .update({
        "on_screens": onScreens
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}