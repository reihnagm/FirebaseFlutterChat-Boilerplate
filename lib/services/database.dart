import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String memberCollection = "Members";
const String readersCollection = "readers";
const String onScreenCollection = "OnScreens";
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

  Future<List<dynamic>>? getMembersChat(String chatId) async {
    List<dynamic> membersAssign = [];
    try {
      QuerySnapshot<Map<String, dynamic>> members = await db.collection(memberCollection)
      .where("id", isEqualTo: chatId)
      .get();
      for (QueryDocumentSnapshot<Object?> member in members.docs) {
        Map<String, dynamic> data = member.data() as Map<String, dynamic>;
        List<dynamic> members = data["members"];
        for (var item in members) {
          membersAssign.add(item);
        }
      }
      return membersAssign;
    } catch(e) {
      debugPrint(e.toString());
    }
    return membersAssign;
  }

   Future<List<dynamic>> getReadersChat(String chatId) async {
    List<dynamic> readersAssign = [];
    try {
      QuerySnapshot<Map<String, dynamic>> readers = await db.collection(readersCollection)
      .where("id", isEqualTo: chatId)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> reader in readers.docs) {
        Map<String, dynamic> data = reader.data();
        List<dynamic> readers = data["readers"];
        for (var item in readers) {
          readersAssign.add(item);
        }
      }
      return readersAssign;
    } catch(e) {
      debugPrint(e.toString());
    }
    return [];
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
          await db.collection(readersCollection)
          .add({
            "id": chatUid,
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
          QuerySnapshot<Map<String, dynamic>> readersDoc = await db
          .collection(readersCollection)
          .where("id", isEqualTo: chatUid)
          .get();
          DocumentSnapshot<Map<String, dynamic>> chatDoc = await db
          .collection(chatCollection)
          .doc(chatUid).get();
            List<dynamic> relations = chatDoc.data()!["relations"];
            List<dynamic> chatCountRead = [];
            if(isGroup) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                for (QueryDocumentSnapshot<Map<String, dynamic>> reader in readersDoc.docs) {
                  Map<String, dynamic> readerData = reader.data();
                  List<dynamic> readers = readerData["readers"];
                  List<dynamic> checkReaders = readers
                    .where((el) => el["reader_id"] == userUid)
                    .where((el) => el["message_id"] == msgDoc.id).toList();
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
              }      
              chatDoc.reference.update({
                "readers": FieldValue.arrayUnion(chatCountRead)
              });     
            }
            if(isGroup) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> reader in readersDoc.docs) {
                Map<String, dynamic> readerData = reader.data();
                List<dynamic> readers = readerData["readers"];
                if(readers.where((el) => el["message_id"] == msg.docs.last.id).toList().length == relations.length) {
                  msg.docs.last.reference.update({"is_read": true});
                }
              }
            } else {
              List<dynamic> data = msg.docs
              .where((el) => el["sender_id"] == userUid)
              .where((el) => el["is_read"] == false).toList();
              if(data.isNotEmpty) {
                for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                  for (QueryDocumentSnapshot<Map<String, dynamic>> reader in readersDoc.docs) {
                    Map<String, dynamic> readerData = reader.data();
                    List<dynamic> readers = readerData["readers"];
                    List<dynamic> checkReaders = readers
                    .where((el) => el["reader_id"] == userUid)
                    .where((el) => el["message_id"] == msgDoc.id).toList();
                    for (var reader in checkReaders) {
                      chatCountRead.add({
                        "message_id": reader["message_id"],
                        "reader_id": reader["reader_id"],
                        "seen": reader["seen"],
                        "is_read": true,
                      });  
                    }         
                    reader.reference.update({
                      "id": chatUid,
                      "readers": chatCountRead
                    });  
                    msgDoc.reference.update({"is_read": true});
                  }
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
        .collection(memberCollection)
        .get();
        for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
          List<dynamic> members = doc.data()["members"];
          int index = members.indexWhere((el) => el["uid"] == userUid);
          if(index != -1) {
            members[index]["isOnline"] = isOnline;
            doc.reference.update({
              "members": members
            });
          }
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

  Future<List<dynamic>> isScreenOn({required String chatUid}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .get();
      List<dynamic> onScreensAssign = [];
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
        Map<String, dynamic> data = item.data();
        List<dynamic> onScreens = data["on_screens"];
        onScreensAssign.add(onScreens);
      }
    } catch(e) {
      debugPrint(e.toString());
    }
    return [];
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

  Future<DocumentReference?> createMembers(Map<String, dynamic> data) async {
    try {
      return await db
      .collection(memberCollection)
      .add(data);
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

   Future<DocumentReference?> createReaders(Map<String, dynamic> data) async {
    try {
      return await db
      .collection(readersCollection)
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
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .get();
      if(data.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
          List<dynamic> onScreens = item.data()["on_screens"];
          int index = onScreens.indexWhere((el) => el["userUid"] == userUid);
          if(index != -1) {
            onScreens[index]["on"] = true;
            Future.delayed(Duration.zero, () async {
              try {
                item.reference.update({
                  "on_screens": onScreens
                });
              } catch(e) {
                debugPrint(e.toString());
              }
            });
          } else {
            Future.delayed(Duration.zero, () async {
              try {
                item.reference.update({
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
          onScreens[index]["on"] = false;
          item.reference.update({
            "on_screens": onScreens
          }); 
        }
      }
    } catch(e) {
      debugPrint(e.toString());
    }
  }

}