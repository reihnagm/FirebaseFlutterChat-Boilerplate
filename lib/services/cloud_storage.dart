import 'dart:io';

import 'package:chat/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CloudStorageService {
  final DatabaseService ds;

  CloudStorageService({
    required this.ds
  });

  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String?> saveGroupImageToStorage({
     required String groupName, 
     required PlatformFile groupImage
    }) async {
    try {
      Reference ref = storage.ref().child("images/groups/$groupName.${groupImage.extension}");
      UploadTask task = ref.putFile(File(groupImage.path!));
      return await task.then((result) async {
        return await result.ref.getDownloadURL();
      });
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
    return "";
  }
 
  Future<String?> saveUserImageToStorage({ 
    required String uid, 
    required String name,
    required String email,
    required PlatformFile file
  }) async {
    try {
      Reference ref = storage.ref().child("images/users/$uid/profile.${file.extension}");
      UploadTask task = ref.putFile(File(file.path!));
      String? imageUrl = await task.then((result) async {
        return await result.ref.getDownloadURL();
      });
      await ds.register(
        uid: uid, 
        name: name, 
        email: email, 
        imageUrl: imageUrl!
      );
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
    return "";
  }

  Future<String?> saveChatImageToStorage(String chatId, String userId, PlatformFile platformFile) async {
    try {
      Reference ref = storage.ref().child("images/chats/$chatId/${userId}_${Timestamp.now().millisecondsSinceEpoch}.${platformFile.extension}");
      UploadTask task = ref.putFile(File(platformFile.path!));
      return await task.then((result) async {
        return await result.ref.getDownloadURL();
      });
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
    return "";
  }
}