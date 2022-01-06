class ChatUser {
  final String? uid;
  final String? name;
  final String? email;
  final String? image;
  final bool? isOnline;
  final DateTime? lastActive;
  final String? token;

  ChatUser({
    this.token,
    this.uid,
    this.name,
    this.email,
    this.image,
    this.isOnline,
    this.lastActive
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      token: json["token"],
      uid: json["uid"], 
      name: json["name"],
      email: json["email"], 
      image: json["image"], 
      isOnline: json["isOnline"],
      lastActive: json["last_active"].toDate()
    );
  }

  String lastDayActive() {
    return "${lastActive!.month}/${lastActive!.day}/${lastActive!.year}";
  }

  bool wasRecentlyActive() => DateTime.now().difference(lastActive!).inHours < 2;
  
  bool isUserOnline() => isOnline! ? true : false;
}