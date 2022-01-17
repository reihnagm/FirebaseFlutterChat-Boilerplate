
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Utils {  
  static Future<String> downloadFile(String url, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);

    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  static SharedPreferences? prefs;
  static Future initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }
}
