// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

import 'package:chatv28/utils/color_resources.dart';

class TopBar extends StatelessWidget {
  final String? barTitle;
  final Color barTitleColor;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final double? fontSize;

  late double deviceHeight;
  late double deviceWidth;

  TopBar(
    this.barTitle, 
  {
    Key? key, 
    this.barTitleColor = ColorResources.white,
    this.primaryAction,
    this.secondaryAction,
    this.fontSize = 35,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }  

  Widget buildUI() {
    return SizedBox(
      height: deviceHeight * 0.10,
      width: deviceWidth,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(secondaryAction != null) secondaryAction!,
          titleBar(),
          if(primaryAction != null) primaryAction!
        ],
      ),
    );
  }

  Widget titleBar() {
    return Text(
      barTitle!, 
      overflow: TextOverflow.ellipsis,
      style:  TextStyle(
        color: barTitleColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w700
      ),
    );
  }
}