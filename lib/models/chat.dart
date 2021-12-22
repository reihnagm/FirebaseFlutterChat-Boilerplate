import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';

class Chat {
  final String uid;
  final String currentUserId;
  final bool activity;
  final bool group;
  final List<ChatUser> members;
  List<ChatMessage> messages; 
  late final List<ChatUser> recepients;

  Chat({
    required this.uid,
    required this.currentUserId,
    required this.activity,
    required this.group,
    required this.members,
    required this.messages,
  }) {
    recepients = members.where((el) => el.uid != currentUserId).toList();
  }

  List<ChatUser> fetchListRecepients() {
    return recepients;
  }

  bool isUsersOnline() => fetchListRecepients().any((el) => el.isUserOnline());
  String title() => !group ? recepients.first.name! : recepients.map((user) => user.name!).join(", ");
  String imageURL() => !group ? recepients.first.imageUrl! : "https://t4.ftcdn.net/jpg/03/99/12/41/360_F_399124149_L3lTd03yuk7b0lhOhoqbJ0dc6Wjw6WQH.jpg";
}