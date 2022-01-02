import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:chatv28/utils/color_resources.dart';

class TopBar extends StatelessWidget {
  final String? barTitle;
  late final double? barTitleFontSize;
  final Color barTitleColor;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  late double deviceHeight;
  late double deviceWidth;

  TopBar({
    Key? key,
    this.barTitle, 
    this.barTitleColor = ColorResources.white,
    this.primaryAction,
    this.secondaryAction,
  })  : super(key: key) {
    barTitleFontSize = 14.0.sp;
  }

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
      style: TextStyle(
        color: barTitleColor,
        fontSize: barTitleFontSize,
        fontWeight: FontWeight.w700
      ),
    );
  }
}

class TopBarChat extends StatelessWidget {
  final String? barTitle;
  final String? subTitle;
  late final double? barTitleFontSize;
  late final double? barSubtitleFontSize;
  final Color barTitleColor;
  final Color? barSubtitleColor;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  late double deviceHeight;
  late double deviceWidth;

  TopBarChat({
    Key? key,
    this.barTitle, 
    this.subTitle,
    this.barTitleColor = ColorResources.white,
    this.barSubtitleColor = ColorResources.white,
    this.primaryAction,
    this.secondaryAction,
  }) : super(key : key) {
    barTitleFontSize = 14.0.sp;
    barSubtitleFontSize = 8.0.sp;
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }  

  Widget buildUI() {
    return Container(
      width: deviceWidth,
      decoration: const BoxDecoration(
        color: ColorResources.backgroundBlueSecondary
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(secondaryAction != null) secondaryAction!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBar(),
                const SizedBox(height: 5.0),
                subTitleBar()
              ],
            ),
          ),
          if(primaryAction != null) primaryAction!
        ],
      ),
    );
  }

  Widget titleBar() {
    return Text(
      barTitle!, 
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: barTitleColor,
        fontSize: barTitleFontSize,
        fontWeight: FontWeight.w700
      ),
    );
  }

  Widget subTitleBar() {
    return Text(
      subTitle!, 
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: barSubtitleColor,
        fontSize: barSubtitleFontSize,
        fontWeight: FontWeight.w700
      ),
    );
  }
}