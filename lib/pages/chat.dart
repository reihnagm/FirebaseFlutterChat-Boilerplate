import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/widgets/custom_input_fields.dart';
import 'package:chatv28/widgets/custom_list_view_tiles.dart';
import 'package:chatv28/widgets/top_bar.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/models/chat.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  const ChatPage({ 
    required this.chat,
    Key? key 
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late double deviceHeight;
  late double deviceWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      Provider.of<ChatProvider>(context, listen: false).listenToKeyboardType(chatId: widget.chat.uid);
      Provider.of<ChatProvider>(context, listen: false).listenToMessages(chatId: widget.chat.uid);
    });
  } 

  @override 
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ChatProvider>();
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width; 
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.03,
                      vertical: deviceHeight * 0.02
                    ),
                    width: deviceHeight * 0.97,
                    height: deviceHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TopBar(
                          widget.chat.title(),
                          fontSize: 16.0,
                          primaryAction: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white
                            ),
                            onPressed: () {
                              context.read<ChatProvider>().deleteChat(context, chatId: widget.chat.uid);
                            },
                          ),  
                          secondaryAction: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white
                            ),
                            onPressed: () {
                              context.read<ChatProvider>().goBack(context);
                            },
                          ),  
                        ),
                        messageList(),
                        sendMessageForm()
                      ],
                    ),
                  ),
                );
              },
            )
          ),
        ); 
      }
    );
  }

  Widget messageList() {
    if( context.watch<ChatProvider>().messages != null) {
      if( context.watch<ChatProvider>().messages!.isNotEmpty) {
        return Expanded(
          child: GroupedListView<ChatMessage, dynamic>(
            physics: const ScrollPhysics(),
            controller:  context.read<ChatProvider>().scrollController,
            elements:  context.watch<ChatProvider>().messages!,
            groupBy: (el) => DateFormat('dd MMM yyyy').format(el.sentTime),
            groupSeparatorBuilder: (date) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0)
                    ),
                    child: Text(date,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey
                      )
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
            groupComparator: (value1, value2) => value1.compareTo(value2),
            itemComparator: (item1, item2) => DateFormat('yyyy-MM-dd').format(item1.sentTime).compareTo(DateFormat('yyyy-MM-dd').format(item2.sentTime)),
            order: GroupedListOrder.DESC,
            shrinkWrap: true,
            indexedItemBuilder: (BuildContext context, ChatMessage items, int i) {
              ChatMessage chatMessage = context.read<ChatProvider>().messages![i];
              bool isOwnMessage = chatMessage.senderID ==  context.watch<AuthenticationProvider>().auth.currentUser!.uid;
              return CustomChatListViewTile(
                deviceWidth: deviceWidth * 0.80, 
                deviceHeight: deviceHeight, 
                isOwnMessage: isOwnMessage, 
                message: chatMessage, 
                sender: widget.chat.members.where((el) => el.uid == chatMessage.senderID).first
              );                
            },
          ),
        );
      } else {
        return const Align(
          alignment: Alignment.center,
          child: Text("Be the first to say Hi!",
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
  }

  Widget sendMessageForm() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(30, 29, 27, 1.0),
        borderRadius: BorderRadius.circular(10.0)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          messageTextField(),
          sendMessageButton(),
          imageMessageButton()
        ],  
      ),
    );
  }

  Widget messageTextField() {
    return SizedBox(
      width: deviceWidth * 0.60,
      child: CustomTextFormField(
        controller: context.read<ChatProvider>().messageTextEditingController,
        onSaved: (val) {},
        regex: r"^(?!\s*$).+", 
        hintText: "Type a message", 
        obscureText: false,
      ),
    );
  }

  Widget sendMessageButton() {
    return IconButton(
      onPressed: () {
        context.read<ChatProvider>().sendTextMessage(chatId: widget.chat.uid);
      }, 
      icon: const Icon(
        Icons.send,
        size: 20.0,
        color: Colors.white,
      )
    );
  }

  Widget imageMessageButton() {
    return SizedBox(
      width: 30.0,
      child: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(0, 82, 218, 1.0),
        onPressed: () {
           context.read<ChatProvider>().sendImageMessage(chatId: widget.chat.uid);
        },
        child: const Icon(
          Icons.camera_enhance,
          size: 20.0,
        ),
      ),
    );
  }

}

