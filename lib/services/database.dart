import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat_message.dart';

const String userCollection = "Users";
const String usersOnlineCollection = "UsersOnline";
// const String memberCollection = "Members";
// const String readersCollection = "Readers";
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

  // Future<List<dynamic>>? getMembersChat(String chatId) async {
  //   List<dynamic> membersAssign = [];
  //   try {
  //     QuerySnapshot<Map<String, dynamic>> members = await db.collection(memberCollection)
  //     .where("id", isEqualTo: chatId)
  //     .get();
  //     for (QueryDocumentSnapshot<Object?> member in members.docs) {
  //       Map<String, dynamic> data = member.data() as Map<String, dynamic>;
  //       List<dynamic> members = data["members"];
  //       for (var member in members) {
  //         membersAssign.add(member);
  //       }
  //     }
  //     return membersAssign;
  //   } catch(e) {
  //     debugPrint(e.toString());
  //   }
  //   return membersAssign;
  // }

  // Future<List<dynamic>> getReadersChat(String chatId) async {
  //   List<dynamic> readersAssign = [];
  //   try {
  //     QuerySnapshot<Map<String, dynamic>> readers = await db.collection(readersCollection)
  //     .where("id", isEqualTo: chatId)
  //     .get();
  //     for (QueryDocumentSnapshot<Map<String, dynamic>> reader in readers.docs) {
  //       Map<String, dynamic> data = reader.data();
  //       List<dynamic> readers = data["readers"];
  //       for (var item in readers) {
  //         readersAssign.add(item);
  //       }
  //     }
  //     return readersAssign;
  //   } catch(e) {
  //     debugPrint(e.toString());
  //   }
  //   return readersAssign;
  // }

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

  Future<void>? getReaderMessage(String chatId) async {
    try {
      DocumentSnapshot chatDoc = await db
      .collection(chatCollection).doc(chatId)
      .get();
      Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
      List<dynamic> readers = data["readers"];
      QuerySnapshot<Map<String, dynamic>> msgDoc = await db.collection(chatCollection)
      .doc(chatId)
      .collection(messageCollection)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in msgDoc.docs) {
        readers.where((el) => el["message_id"] == doc.id).toList();
      }
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
      try {
        await db
        .collection(chatCollection)
        .doc(chatUid)
        .update({
          "readers": FieldValue.arrayUnion([{
            "seen": DateTime.now(),
            "message_id": doc.id,
            "reader_id": readerId,
            "reader_name": "",
            "is_read": isGroup ? true : message.isRead 
          }])
        });
      } catch(e) {
        debugPrint(e.toString());
      }
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
    required String userName,
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
          DocumentSnapshot<Map<String, dynamic>> chatDoc = await db
          .collection(chatCollection)
          .doc(chatUid).get();
            List<dynamic> relations = chatDoc.data()!["relations"];
            List<dynamic> readers = chatDoc.data()!["readers"];
            List<dynamic> chatCountRead = [];
            if(isGroup) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                List<dynamic> checkReaders = readers
                  .where((el) => el["reader_id"] == userUid)
                  .where((el) => el["message_id"] == msgDoc.id).toList();
                  if(checkReaders.isNotEmpty) {
                    for (var reader in checkReaders) {
                      chatCountRead.add({
                        "seen": reader["seen"],
                        "message_id": reader["message_id"],
                        "reader_id": reader["reader_id"],
                        "reader_name": userName,
                        "is_read": true,
                      }); 
                    }    
                  } else {
                    chatCountRead.add({
                      "seen": DateTime.now(),
                      "message_id": msgDoc.id,
                      "reader_id": userUid,
                      "reader_name": userName,
                      "is_read": true,
                    }); 
                  }
                chatDoc.reference.update({
                  "readers": FieldValue.arrayUnion(chatCountRead)
                }); 
              }         
            }
            if(isGroup) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                if(readers.where((el) => el["message_id"] == msgDoc.id).toList().length == relations.length) {
                  msgDoc.reference.update({"is_read": true});
                }
              }
            } else {
              List<dynamic> data = msg.docs
              .where((el) => el["sender_id"] == userUid)
              .where((el) => el["is_read"] == false).toList();
              if(data.isNotEmpty) {
                for (QueryDocumentSnapshot<Map<String, dynamic>> msgDoc in msg.docs) {
                  List<dynamic> checkReaders = readers
                  .where((el) => el["reader_id"] == userUid)
                  .where((el) => el["message_id"] == msgDoc.id).toList();
                  for (var reader in checkReaders) {
                    chatCountRead.add({
                      "seen": reader["seen"],
                      "message_id": reader["message_id"],
                      "reader_id": reader["reader_id"],
                      "reader_name": userName,
                      "is_read": true,
                    });  
                  }         
                  chatDoc.reference.update({
                    "readers": chatCountRead
                  });  
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

  Future<void> updateUserToken(String userUid, String? token) async {
    try {
      await db
      .collection(userCollection)
      .doc(userUid).update({
        "token": token
      });
      try {
        QuerySnapshot<Map<String, dynamic>> data = await db
        .collection(onScreenCollection)
        .get();
        if(data.docs.isNotEmpty) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> screenDoc in data.docs) {
            List<dynamic> onscreens = screenDoc.data()["on_screens"];
            int idx = onscreens.indexWhere((el) => el["userUid"] == userUid);
            onscreens[idx]["token"] = token;
            screenDoc.reference.update({
              "on_screens": onscreens
            });
          }
        }
      } catch(e) {
        debugPrint(e.toString());
      }
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
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> onlineMember(String userUid) async {
    try {
      Future.delayed(const Duration(seconds: 1), () async {
        QuerySnapshot<Map<String, dynamic>> data = await db
        .collection(chatCollection)
        .get();
        for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
          List<dynamic> membersData = doc.data()["members"];
          int idx = membersData.indexWhere((el) => el["uid"] == userUid);
          membersData[idx]["isOnline"] = true;
          doc.reference.update({
            "members": membersData
          });
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> offlineMember(String userUid) async {
    try {
      Future.delayed(const Duration(seconds: 1), () async {
        QuerySnapshot<Map<String, dynamic>> data = await db
        .collection(chatCollection)
        .get();
        for (QueryDocumentSnapshot<Map<String, dynamic>> doc in data.docs) {
          List<dynamic> membersData = doc.data()["members"];
          int idx = membersData.indexWhere((el) => el["uid"] == userUid);
          membersData[idx]["isOnline"] = false;
          doc.reference.update({
            "members": membersData
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

  Future<List<dynamic>> isScreenOn({required String chatUid}) async {
    List<dynamic> onScreensAssign = [];
    try {
      QuerySnapshot<Map<String, dynamic>> data = await db
      .collection(onScreenCollection)
      .where("id", isEqualTo: chatUid)
      .get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> item in data.docs) {
        Map<String, dynamic> data = item.data();
        List<dynamic> onScreens = data["on_screens"];
        for (var onScreen in onScreens) {
          onScreensAssign.add(onScreen);
        }
      }
    } catch(e) {
      debugPrint(e.toString());
    }
    return onScreensAssign;
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

  // Future<DocumentReference?> createMembers(Map<String, dynamic> data) async {
  //   try {
  //     return await db
  //     .collection(memberCollection)
  //     .add(data);
  //   } catch(e) {
  //     debugPrint(e.toString());
  //   }
  // }

  Future<DocumentReference?> createOnScreens(Map<String, dynamic> data) async {
    try {
      return await db
      .collection(onScreenCollection)
      .add(data);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  // Future<DocumentReference?> createReaders(Map<String, dynamic> data) async {
  //   try {
  //     return await db
  //     .collection(readersCollection)
  //     .add(data);
  //   } catch(e) {
  //     debugPrint(e.toString());
  //   }
  // }

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
          });
        } else {
          item.reference.update({
            "on_screens": FieldValue.arrayUnion([{
              "userUid": userUid,
              "on": true,
            }])
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