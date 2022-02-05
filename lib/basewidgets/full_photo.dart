import 'package:photo_view/photo_view.dart';

import 'package:flutter/material.dart';

class FullPhotoScreen extends StatelessWidget {
  final String url;

  const FullPhotoScreen({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoView(
        imageProvider: NetworkImage(url),
      ),
    );
  }
}