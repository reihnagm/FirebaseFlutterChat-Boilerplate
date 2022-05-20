import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:chat/utils/box_shadow.dart';
import 'package:chat/utils/custom_themes.dart';
import 'package:chat/utils/dimensions.dart';
import 'package:chat/basewidgets/button/bounce_button.dart';

class CustomButton extends StatelessWidget {
  final Function() onTap;
  final String btnTxt;
  final double height;
  final Color loadingColor;
  final Color btnColor;
  final Color btnTextColor;
  final Color btnBorderColor;
  final bool isBorder;
  final bool isLoading;
  final bool isBoxShadow;

  const CustomButton({
    Key? key, 
    required this.onTap, 
    required this.btnTxt, 
    this.height = 45.0,
    this.isLoading = false,
    this.loadingColor = Colors.white,
    this.btnColor = const Color.fromRGBO(51, 49, 68, 1.0),
    this.btnTextColor = Colors.white,
    this.btnBorderColor = Colors.transparent,
    this.isBorder = false,
    this.isBoxShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Bouncing(
      onPress: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: isBoxShadow ? boxShadow : [],
          color: btnColor,
          border: Border.all(
            color: isBorder ? btnBorderColor : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(10.0)
        ),
        child: isLoading ? 
          Center(
            child: SpinKitFadingCircle(
              color: loadingColor,
              size: 25.0
            ),
          )
        : Center(
          child: Text(btnTxt,
            style: dongleLight.copyWith(
              color: btnTextColor,
              fontSize: Dimensions.fontSizeSmall,
            )
          ),
        )
      ),
    );
  }
}
