import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CloudStorageService {
  final FirebaseStorage storage = FirebaseStorage.instance;
 
  Future<String?> saveUserImageToStorage(String uid, PlatformFile file) async {
    try {
      Reference ref = storage.ref().child("images/users/$uid/profile.${file.extension}");
      UploadTask task = ref.putFile(File(file.path!));
      return await task.then((result) async {
        return await result.ref.getDownloadURL();
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> saveChatImageToStorage(String chatId, String userId, PlatformFile platformFile) async {
    try {
      Reference ref = storage.ref().child("images/chats/$chatId/${userId}_${Timestamp.now().millisecondsSinceEpoch}.${platformFile.extension}");
      UploadTask task = ref.putFile(File(platformFile.path!));
      return await task.then((result) async {
        return await result.ref.getDownloadURL();
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }
}