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

  Stream<DocumentSnapshot>? getChatUserOnline(String uid) {
    try{
      return db.collection(userCollection).doc(uid).snapshots();
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Stream<QuerySnapshot>? getChatsForUser(String userUid) {
    try {
      return db.collection(chatCollection)
      .where('relations', arrayContains: userUid)
      .snapshots();
    } catch(e) {
      debugPrint(e.toString());
    } 
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

  Future<void> addMessageToChat({required String chatUid, required String readerId, required ChatMessage message, required bool isGroup}) async {
    try { 
      DocumentReference doc = await db.collection(chatCollection)
      .doc(chatUid)
      .collection(messageCollection)
      .add(message.toJson());
      Future.delayed(Duration.zero, () async {
        try {
          await db.collection(chatCollection)
          .doc(chatUid)
          .update({
            "readers": FieldValue.arrayUnion([{
              "seen": DateTime.now(),
              "message_id": doc.id,
              "reader_id": readerId,
              "is_read": isGroup ? true : message.isRead
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

  Future<void> seeMsg({
    required String chatUid, 
    required String senderId, 
    required String receiverId, 
    required String userUid,
    required bool isGroup
  }) async {
    try {
      QuerySnapshot<Map<String, dynamic>> msg = await db
      .collection(chatCollection)
      .doc(chatUid)
      .collection(messageCollection)
      .get();
      Future.delayed(Duration.zero, () async {
        try {
          QuerySnapshot<Map<String, dynamic>> chat = await db
          .collection(chatCollection)
          .get();
          for (QueryDocumentSnapshot<Map<String, dynamic>> chatDoc in chat.docs) {
            List<dynamic> readers = chatDoc.data()["readers"];
            List<dynamic> relations = chatDoc.data()["relations"];
            List<dynamic> chatCountRead = [];
            if(isGroup) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                List<dynamic> checkReaders = readers
                .where((el) => el["reader_id"] == userUid)
                .where((el) => el["message_id"] == msgDoc.id)  .toList();
                if(checkReaders.isNotEmpty) {
                  for (var reader in checkReaders) {
                    reader["is_read"] = true;
                    chatCountRead.add({
                      "seen": reader["seen"],
                      "message_id": reader["message_id"],
                      "reader_id": reader["reader_id"],
                      "is_read": reader["is_read"],
                    }); 
                  }    
                } else {
                  chatCountRead.add({
                    "seen": DateTime.now(),
                    "message_id": msgDoc.id,
                    "reader_id": userUid,
                    "is_read": true,
                  }); 
                }
              }      
              chatDoc.reference.update({
                "readers": FieldValue.arrayUnion(chatCountRead)
              });     
            } else {
              List<dynamic> checkReaders = readers.where((el) => el["reader_id"] == userUid).toList();
              if(checkReaders.isNotEmpty) {
                for (var reader in checkReaders) {
                  reader["is_read"] = true;
                  chatCountRead.add({
                    "seen": reader["seen"],
                    "message_id": reader["message_id"],
                    "reader_id": reader["reader_id"],
                    "is_read": reader["is_read"],
                  });  
                }     
              }
              chatDoc.reference.update({
                "readers": chatCountRead
              }); 
            }
            for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
              if(isGroup) {
                if(readers.where((el) => el["message_id"] == msgDoc.id).toList().length == relations.length) {
                  msgDoc.reference.update({"is_read": true});
                }
              } else {
                msgDoc.reference.update({"is_read": true});
              }
            }
          }
        } catch(e) {
          debugPrint(e.toString());
        }
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
      Future.delayed(Duration.zero, () async {
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
      .where("is_group", isEqualTo: false)
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
      Future.delayed(Duration.zero, () async {
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
        Future.delayed(Duration.zero, () async {
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
        Future.delayed(Duration.zero, () async {
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
      data.reference.update({
        "on_screens": onScreens
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}