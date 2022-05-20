import 'package:flutter/material.dart';

import 'package:chat/utils/color_resources.dart';

class ShowSnackbar {
  ShowSnackbar._();
  static snackbar(BuildContext context, String content, String label, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(content,
          style: const TextStyle(
            color: ColorResources.white
          ),
        ),
        action: SnackBarAction(
          textColor: Colors.white,
          label: label,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()
        ),
      )
    );
  }
}