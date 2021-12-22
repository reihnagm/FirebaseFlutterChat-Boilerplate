import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/widgets/custom_button.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/providers/user.dart';
import 'package:chatv28/widgets/custom_input_fields.dart';
import 'package:chatv28/widgets/custom_list_view_tiles.dart';
import 'package:chatv28/widgets/top_bar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({ Key? key }) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late double deviceHeight; 
  late double deviceWidth;

  late AuthenticationProvider authenticationProvider;
  late DatabaseService databaseService;
  late TextEditingController searchFieldTextEditingController = TextEditingController();

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      Provider.of<UserProvider>(context, listen: false).getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    authenticationProvider = context.watch<AuthenticationProvider>();
    databaseService = DatabaseService();
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.03,
            vertical: deviceHeight * 0.02
          ),
          width: deviceWidth * 0.97,
          height: deviceHeight * 0.98,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TopBar("Users",
                primaryAction: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Provider.of<AuthenticationProvider>(context, listen: false).logout(context);
                  }, 
                ),
              ),
              CustomTextField(
                onEditingComplete: (val) {
                  context.watch<UserProvider>().getUsers(name: val);
                  FocusScope.of(context).unfocus();
                },
                controller: searchFieldTextEditingController,
                icon: Icons.search,
                hintText: "Search", 
                obscureText: true
              ),
              usersList(),
              createChatButton()
            ],
          ),
        );
      },
    );
  }

  Widget usersList() {
    List<ChatUser>? users = context.watch<UserProvider>().users; 
    return Expanded(child: () {
      if(users != null) {
        if(users.isNotEmpty) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (BuildContext context, int i) {
              return CustomListViewTile(
                title: users[i].name!,
                subtitle: "Last Active: ${timeago.format(users[i].lastActive!)}",
                height: deviceHeight * 0.10,  
                imagePath: users[i].imageUrl!, 
                isActive: users[i].isUserOnline(), 
                isSelected: context.watch<UserProvider>().selectedUsers.contains(users[i]), 
                onTap: () async {
                  DocumentReference? doc = await databaseService.createChat(
                    {
                      "is_group": false,
                      "is_activity": false,
                      "relations": [
                         authenticationProvider.chatUser.uid,
                         users[i].uid
                      ]
                      "members": [
                        {
                          "uid": authenticationProvider.chatUser.uid,
                          "email": authenticationProvider.chatUser.email,
                          "image": authenticationProvider.chatUser.imageUrl,
                          "isOnline": authenticationProvider.chatUser.isOnline,
                          "last_active": authenticationProvider.chatUser.lastActive,
                          "name": authenticationProvider.chatUser.name,
                          "token": authenticationProvider.chatUser.token
                        },
                        {
                          "uid": users[i].uid,
                          "email":users[i].email,
                          "image": users[i].imageUrl,
                          "isOnline": users[i].isOnline,
                          "last_active": users[i].lastActive,
                          "name": users[i].name,
                          "token": authenticationProvider.chatUser.token
                        }
                      ], 
                    }
                  );
                  NavigationService.pushNav(context, ChatPage(
                    chat: Chat(
                      uid: doc!.id, 
                      currentUserId: authenticationProvider.chatUser.uid!, 
                      activity: false, 
                      group: false, 
                      members: [
                        ChatUser(
                          uid: users[i].uid, 
                          name: users[i].name, 
                          email: users[i].email, 
                          imageUrl: users[i].imageUrl, 
                          isOnline: users[i].isOnline, 
                          lastActive: users[i].lastActive,
                          token: users[i].token
                        ),
                        ChatUser(
                          uid: authenticationProvider.chatUser.uid, 
                          name: authenticationProvider.chatUser.name, 
                          email: authenticationProvider.chatUser.name, 
                          imageUrl: authenticationProvider.chatUser.imageUrl, 
                          isOnline: authenticationProvider.chatUser.isOnline, 
                          lastActive: authenticationProvider.chatUser.lastActive,
                          token: users[i].token
                        ),
                      ], 
                      messages: []
                    )
                  ));
                },
                onLongPress: () {
                  context.read<UserProvider>().updateSelectedUsers(users[i]);
                },
              );
            },
          );
        } else {
          return const Center(
            child: Text("No Users Found.",
              style: TextStyle(
                color: Colors.white
              ),
            ),
          );
        }
      } else {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      }
    }());
  }

  Widget createChatButton() {
    return Visibility(
      visible:  context.watch<UserProvider>().selectedUsers.isNotEmpty,
      child: CustomButton(
        onTap: () {
           context.read<UserProvider>().createChat(context);
        }, 
        isBoxShadow: false,
        btnTxt: context.read<UserProvider>().selectedUsers.length == 1 
        ? "Chat with ${context.read<UserProvider>().selectedUsers.first.name}"
        : "Create Group Chat"
      )
    );
  }
}