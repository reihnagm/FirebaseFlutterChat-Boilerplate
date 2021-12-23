import 'package:chatv28/models/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const String userCollection = "Users";
const String chatCollection = "Chats";
const String messageCollection = "Messages"; 

class DatabaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUser(String uid) {
    return db.collection(userCollection).doc(uid).get();
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
    return db.collection(chatCollection).doc(chatID)
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

  Future<void> updateMsgRead(String uid) async {
    try {
      await db.collection(messageCollection).doc("GSAlCaDPTgMkS63WGHB4").update({
        "is_read": true
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

  Future<void> updateUserOnline(String uid, bool isOnline) async {
    try {
      await db.collection(userCollection).doc(uid).update({
        "isOnline": isOnline
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> userIsChatted(String uid) async {
    return await db.collection(chatCollection)
    .where("relations", arrayContains: uid)
    .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchListChattedMessage(String uid) async {
    return await db.collection(chatCollection).doc(uid).collection(messageCollection).get();
  }

  Future<void> setRelationUserOnline(String uid, bool isOnline) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db.collection(chatCollection)
      .where("relations", arrayContains: uid)
      .get();
      for (var doc in data.docs) {
        List<dynamic> members = doc.data()["members"];
        int index = members.indexWhere((el) => el["uid"] == uid);
        members[index]["isOnline"] = isOnline;
        db.collection(chatCollection).doc(data.docs[0].id).update({
          "members": members
        });
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat(String chatID) async {
    try {
      await db.collection(chatCollection).doc(chatID).delete();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<DocumentReference?> createChat(Map<String, dynamic> data) async {
    try {
      DocumentReference chat = await db.collection(chatCollection).add(data);
      return chat;
    } catch(e) {
      debugPrint(e.toString());
    }
  }
}