import 'dart:async';
import 'dart:io';

import 'package:chatv28/providers/chats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:chatv28/services/media.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/basewidget/animated_dialog/show_animate_dialog.dart';
import 'package:chatv28/basewidget/signout_confirmation_dialog/signout_confirmation_dialog.dart';
import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/basewidget/button/custom_button.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/providers/user.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/basewidget/top_bar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({ Key? key }) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late double deviceHeight; 
  late double deviceWidth;

  late DatabaseService databaseService; 
  late MediaService mediaService;
  late TextEditingController searchFieldTextEditingController;

  File? file;
  PlatformFile? groupImage;
  String groupName = "";
  String groupChatId = "";
  FocusNode focusNodeGroupName = FocusNode();

  void chooseGroupAvatar() async {
    PlatformFile? f = await mediaService.pickImageFromLibrary();
    if(f != null) { 
      groupImage = f;
      File? cropped = await ImageCropper.cropImage(
        sourcePath: f.path!,
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: "Crop It"
          toolbarColor: Colors.blueGrey[900],
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false
        ),
        iosUiSettings: const IOSUiSettings(
          minimumAspectRatio: 1.0,
        )
      );  
      if(cropped != null) {
        setState(() => file = cropped);
      } else {
        setState(() => file = null);
      }
    }   
  }

  @override 
  void initState() {
    super.initState();
    searchFieldTextEditingController = TextEditingController();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      context.read<AuthenticationProvider>().initAuthStateChanges();
      context.read<UserProvider>().getUsers();
    });
  }

  @override 
  void dispose() {
    searchFieldTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    databaseService = DatabaseService();
    mediaService = MediaService();
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.03,
            vertical: deviceHeight * 0.02
          ),
          height: deviceHeight * 0.98,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TopBar(
                barTitle: "Users",
                barTitleColor: ColorResources.backgroundBlackPrimary,
                primaryAction: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: ColorResources.backgroundBlackPrimary,
                  ),
                  onPressed: () async {
                    showAnimatedDialog(context,
                      const SignOutConfirmationDialog(),
                      isFlip: false
                    );
                  }, 
                ),
                secondaryAction: IconButton(
                  icon: const Icon(
                    Icons.group_add,
                    color: ColorResources.backgroundBlackPrimary,
                  ),
                  onPressed: () async {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: ColorResources.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10.0), 
                          topRight: Radius.circular(10.0)
                        )
                      ),
                      context: context, 
                      builder: (context) {
                        return SafeArea(
                          child: LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              return Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        
                                        Container(
                                          margin: EdgeInsets.all(Dimensions.marginSizeSmall),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text("Create a group",
                                                    style: TextStyle(
                                                      color: ColorResources.textBlackPrimary,
                                                      fontSize: Dimensions.fontSizeLarge,
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                ],
                                              ),  
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  file != null 
                                                  ? Stack(
                                                      children: [
                                                        Container(
                                                          width: 80.0,
                                                          height: 100.0,
                                                          padding: const EdgeInsets.all(10.0),
                                                          child: Image.file(
                                                            file!,
                                                            width: 50.0,
                                                            height: 50.0,
                                                          )
                                                        ),
                                                        Positioned(
                                                          bottom: 0.0,
                                                          left: 0.0,
                                                          right: 0.0,
                                                          child: InkWell(
                                                            onTap: () => chooseGroupAvatar(),
                                                            child: const Icon(
                                                              Icons.edit,
                                                              size: 25.0,
                                                              color: ColorResources.black,
                                                            ),
                                                          )
                                                        ),
                                                      ],
                                                    )
                                                  : Stack(
                                                      children: [
                                                        Container(
                                                          width: 80.0,
                                                          height: 100.0,
                                                          padding: const EdgeInsets.all(10.0),
                                                          decoration: BoxDecoration(
                                                            color: ColorResources.backgroundBlueSecondary,
                                                            boxShadow: boxShadow,
                                                            shape: BoxShape.circle
                                                          ),
                                                          child: const Icon(
                                                            Icons.group,
                                                            size: 45.0,
                                                            color: ColorResources.white,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: 0.0,
                                                          left: 0.0,
                                                          right: 0.0,
                                                          child: InkWell(
                                                            onTap: () => chooseGroupAvatar(),
                                                            child: const Icon(
                                                              Icons.edit,
                                                              size: 25.0,
                                                              color: ColorResources.black,
                                                            ),
                                                          )
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 20.0),
                                              Form(
                                                key: formKey,
                                                child: Column(
                                                  children: [
                                                    TextFormField(
                                                      style: TextStyle(
                                                        fontSize: Dimensions.fontSizeSmall
                                                      ),
                                                      cursorColor: ColorResources.backgroundBlueSecondary,
                                                      validator: (val) {
                                                        if(val == null || val.isEmpty) {
                                                          focusNodeGroupName.requestFocus();
                                                          return "Name can't empty";
                                                        } else {
                                                          return null;
                                                        }
                                                      },
                                                      initialValue: groupName,
                                                      onChanged: (val) {
                                                        groupName = val;
                                                      },
                                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                                      focusNode: focusNodeGroupName,
                                                      decoration: const InputDecoration(
                                                        filled: true,
                                                        fillColor: ColorResources.white,
                                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                                        labelText: "Name",
                                                        labelStyle: TextStyle(
                                                          color: ColorResources.textBlackPrimary
                                                        ),
                                                        alignLabelWithHint: true,
                                                        contentPadding: EdgeInsets.all(16.0),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide(
                                                            color: ColorResources.backgroundBlueSecondary,
                                                            width: 2.0                                                             
                                                          )
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide(
                                                            color: ColorResources.backgroundBlueSecondary,
                                                            width: 2.0                                                             
                                                          )
                                                        ),
                                                        errorBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide.none
                                                        ),
                                                        focusedErrorBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide(
                                                            color: ColorResources.error,
                                                            width: 2.0                                                             
                                                          )
                                                        ),
                                                        disabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide(
                                                            color: ColorResources.backgroundBlueSecondary,
                                                            width: 2.0   
                                                          )
                                                        ),
                                                        focusedBorder:  OutlineInputBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                          borderSide: BorderSide(
                                                            color: ColorResources.backgroundBlueSecondary,
                                                            width: 2.0   
                                                          )
                                                        ),
                                                      ),
                                                    )
                                                  ],  
                                                ) 
                                              ),
                                            ],
                                          )
                                        ),
                                        Consumer<UserProvider>(
                                          builder: (BuildContext context, UserProvider userProvider, Widget? child) {
                                            return Expanded(
                                              child: ListView.builder(
                                                itemCount: userProvider.users!.length,
                                                itemBuilder: (BuildContext context, int i) {
                                                  return CustomListViewTile(
                                                    title: userProvider.users![i].name!,
                                                    group: false,
                                                    subtitle: "Last Active: ${timeago.format(userProvider.users![i].lastActive!)}",
                                                    height: deviceHeight * 0.10,  
                                                    imagePath: userProvider.users![i].image!, 
                                                    isActive: userProvider.users![i].isUserOnline(), 
                                                    isSelected: userProvider.selectedUsers.contains(userProvider.users![i]), 
                                                    onTap: () {
                                                      userProvider.updateSelectedUsers(userProvider.users![i]);
                                                    },
                                                  );   
                                                },
                                              ),
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: EdgeInsets.all(Dimensions.marginSizeSmall),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CustomButton(
                                              height: 40.0,
                                              btnTxt: "Cancel", 
                                              btnTextColor: ColorResources.backgroundBlueSecondary,
                                              isBorder: true,
                                              btnBorderColor: ColorResources.backgroundBlueSecondary,
                                              btnColor: ColorResources.white,
                                              onTap: () {
                                                Navigator.of(context).pop();
                                              }
                                            )
                                          ),
                                          const SizedBox(width: 10.0),
                                          Expanded(
                                            child: CustomButton(
                                              height: 40.0,
                                              btnTxt: "Create", 
                                              btnColor: ColorResources.backgroundBlueSecondary,
                                              isLoading: context.watch<UserProvider>().createGroupStatus == CreateGroupStatus.loading ? true : false,
                                              onTap: context.watch<UserProvider>().createGroupStatus == CreateGroupStatus.loading ? () {} : () async {
                                                if(formKey.currentState!.validate()) {
                                                  formKey.currentState!.save();
                                                  if(file != null) {
                                                    await context.read<UserProvider>().createChat(
                                                      context, 
                                                      groupName: groupName,
                                                      groupImage: groupImage!
                                                    );
                                                  } else {
                                                    await context.read<UserProvider>().createChat(
                                                      context, 
                                                      groupName: groupName,
                                                    );
                                                  }
                                                } 
                                              }
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ) 
                        );
                      },
                    );
                  }, 
                ),
              ),
              CustomTextSearchField(
                onEditingComplete: (val) {
                  context.read<UserProvider>().getUsers(name: val);
                  FocusScope.of(context).unfocus();
                },
                controller: searchFieldTextEditingController,
                icon: Icons.search,
                hintText: "Search", 
              ),
              Consumer<AuthenticationProvider>(
                builder: (BuildContext context, AuthenticationProvider authenticationProvider, Widget? child) {
                  if(authenticationProvider.chatUser == null) {
                    return const Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(
                            color: ColorResources.loaderBluePrimary,
                          ),
                        ),
                      ),
                    );
                  }
                  return usersList();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget usersList() {
    List<ChatUser>? users = context.watch<UserProvider>().users;
    return Expanded(
      child: () {
      if(users != null) {
        if(users.isNotEmpty) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (BuildContext context, int i) {
              return CustomListViewUsersTile(
                title: users[i].name!,
                group: false,
                subtitle: "Last Active: ${timeago.format(users[i].lastActive!)}",
                height: deviceHeight * 0.10,  
                imagePath: users[i].image!, 
                isActive: users[i].isUserOnline(),  
                onTap: () async {
                  String currentUserId = context.read<AuthenticationProvider>().userId();
                  String peerId = users[i].uid!;
                  if(currentUserId.compareTo(peerId) > 0) {
                    groupChatId = '$currentUserId-$peerId';
                  } else {
                    groupChatId = '$peerId-$currentUserId';
                  }
                  DocumentSnapshot? createChatDoc = await databaseService.checkChat(groupChatId);
                  if(createChatDoc!.exists) {  
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setString("chatId", createChatDoc.id);
                    NavigationService().pushNav(context, ChatPage(
                      avatar: users[i].image!,
                      title: users[i].name!,
                      subtitle: users[i].isOnline.toString(),
                      receiverId: users[i].uid!,
                      receiverName: users[i].name!,
                      receiverImage: users[i].image!,
                      groupName: "",
                      groupImage: "",
                      isGroup: false,
                      tokens: const [],
                      members: const [],
                    ));
                  } else {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setString("chatId", groupChatId);
                    NavigationService().pushNav(context, ChatPage(
                      avatar: users[i].image!,
                      title: users[i].name!,
                      subtitle: users[i].isOnline.toString(),
                      receiverId: users[i].uid!,
                      receiverName: users[i].name!,
                      receiverImage: users[i].image!,
                      groupName: "",
                      groupImage: "",
                      isGroup: false,
                      tokens: const [],
                      members: const [],
                    ));
                    // await databaseService.createConversation(context.read<AuthenticationProvider>().userId(), {
                    //   "id": groupChatId,
                    //     "is_group": false,
                    //     "is_activity": [
                    //       {
                    //         "chat_id": groupChatId,
                    //         "user_id": context.read<AuthenticationProvider>().chatUser!.uid!,
                    //         "name": users[i].name,
                    //         "is_active": false,
                    //         "is_group": false
                    //       },
                    //       {
                    //         "chat_id": groupChatId,
                    //         "user_id": users[i].uid,
                    //         "name": context.read<AuthenticationProvider>().chatUser!.name,
                    //         "is_active": false,
                    //         "is_group": false
                    //       }
                    //     ],
                    //     "group": {
                    //       "name": "",
                    //       "image": "",
                    //       "tokens": []
                    //     },
                    //     "members": [
                    //       {
                    //         "uid": context.read<AuthenticationProvider>().chatUser!.uid!,
                    //         "email": context.read<AuthenticationProvider>().chatUser!.email,
                    //         "name": context.read<AuthenticationProvider>().chatUser!.name,
                    //         "image": context.read<AuthenticationProvider>().chatUser!.image,
                    //         "isOnline": context.read<AuthenticationProvider>().chatUser!.isOnline,
                    //         "last_active": context.read<AuthenticationProvider>().chatUser!.lastActive,
                    //       },
                    //       {
                    //         "uid": users[i].uid,
                    //         "email":users[i].email,
                    //         "name": users[i].name,
                    //         "image": users[i].image,
                    //         "isOnline": users[i].isOnline,
                    //         "last_active": users[i].lastActive,
                    //       }
                    //     ],
                    //     "created_at": DateTime.now(),
                    //     "updated_at": DateTime.now(),
                    //   }
                    // );
                    // await databaseService.createConversation(users[i].uid!, {
                    //   "id": groupChatId,
                    //     "is_group": false,
                    //     "is_activity": [
                    //       {
                    //         "chat_id": groupChatId,
                    //         "user_id": context.read<AuthenticationProvider>().chatUser!.uid!,
                    //         "name": users[i].name,
                    //         "is_active": false,
                    //         "is_group": false
                    //       },
                    //       {
                    //         "chat_id": groupChatId,
                    //         "user_id": users[i].uid,
                    //         "name": context.read<AuthenticationProvider>().chatUser!.name,
                    //         "is_active": false,
                    //         "is_group": false
                    //       }
                    //     ],
                    //     "group": {
                    //       "name": "",
                    //       "image": "",
                    //       "tokens": []
                    //     },
                    //     "members": [
                    //       {
                    //         "uid": context.read<AuthenticationProvider>().chatUser!.uid!,
                    //         "email": context.read<AuthenticationProvider>().chatUser!.email,
                    //         "name": context.read<AuthenticationProvider>().chatUser!.name,
                    //         "image": context.read<AuthenticationProvider>().chatUser!.image,
                    //         "isOnline": context.read<AuthenticationProvider>().chatUser!.isOnline,
                    //         "last_active": context.read<AuthenticationProvider>().chatUser!.lastActive,
                    //       },
                    //       {
                    //         "uid": users[i].uid,
                    //         "email":users[i].email,
                    //         "name": users[i].name,
                    //         "image": users[i].image,
                    //         "isOnline": users[i].isOnline,
                    //         "last_active": users[i].lastActive,
                    //       }
                    //     ],
                    //     "created_at": DateTime.now(),
                    //     "updated_at": DateTime.now(),
                    //   }
                    // );
                    await databaseService.createChat(
                      groupChatId,
                      {
                        "id": groupChatId,
                        "is_group": false,
                        "is_activity": [
                          {
                            "chat_id": groupChatId,
                            "user_id": context.read<AuthenticationProvider>().chatUser!.uid!,
                            "name": users[i].name,
                            "is_active": false,
                            "is_group": false
                          },
                          {
                            "chat_id": groupChatId,
                            "user_id": users[i].uid,
                            "name": context.read<AuthenticationProvider>().chatUser!.name,
                            "is_active": false,
                            "is_group": false
                          }
                        ],
                        "group": {
                          "name": "",
                          "image": "",
                          "tokens": []
                        },
                        "members": [
                          {
                            "uid": context.read<AuthenticationProvider>().chatUser!.uid!,
                            "email": context.read<AuthenticationProvider>().chatUser!.email,
                            "name": context.read<AuthenticationProvider>().chatUser!.name,
                            "image": context.read<AuthenticationProvider>().chatUser!.image,
                            "isOnline": context.read<AuthenticationProvider>().chatUser!.isOnline,
                            "last_active": context.read<AuthenticationProvider>().chatUser!.lastActive,
                          },
                          {
                            "uid": users[i].uid,
                            "email":users[i].email,
                            "name": users[i].name,
                            "image": users[i].image,
                            "isOnline": users[i].isOnline,
                            "last_active": users[i].lastActive,
                          }
                        ],
                        "created_at": DateTime.now(),
                        "updated_at": DateTime.now(),
                        "relations": [
                          context.read<AuthenticationProvider>().userId(),
                          users[i].uid
                        ],
                      }
                    );
                    await databaseService.createOnScreens(groupChatId, {
                      "id": groupChatId,
                      "on_screens": FieldValue.arrayUnion([ 
                        {
                          "user_id": context.read<AuthenticationProvider>().userId(),
                          "token":  await FirebaseMessaging.instance.getToken(), 
                          "on": true
                        },
                        {
                          "user_id": users[i].uid,
                          "token": users[i].token,
                          "on": false
                        },
                      ]),
                    });
                  }
                },
              );
            },
          );
        } else {
          return const Center(
            child: Text("No Users Found.",
              style: TextStyle(
                color: ColorResources.textBlackPrimary
              ),
            ),
          );
        }
      } else {
        return const Center(
          child: SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(
              color: ColorResources.loaderBluePrimary,
            ),
          ),
        );
      }
    }());
  }
}