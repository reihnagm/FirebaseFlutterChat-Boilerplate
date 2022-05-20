// import 'package:flutter/material.dart';

// import 'package:chat/widgets/message/chat_bubble.dart';

// class MessageText extends StatelessWidget {
//   const MessageText({
//     Key? key,
//     required this.alignment,
//     required this.color,
//     required this.message,
//     required this.messageColor,
//   }) : super(key: key);

//   final Alignment alignment;
//   final Color color;
//   final Message message;
//   final Color messageColor;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Align(
//         alignment: alignment, 
//           child: CustomPaint(
//           painter: ChatBubble(color: color, alignment: alignment),
//           child: Container(
//             margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   constraints: BoxConstraints(
//                       maxWidth: MediaQuery.of(context).size.width * 0.65),
//                   child: Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: Text(
//                       message.text,
//                       style: TextStyle(color: messageColor),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }