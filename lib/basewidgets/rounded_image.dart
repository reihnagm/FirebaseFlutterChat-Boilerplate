import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:flutter/material.dart';

class RoundedImageNetwork extends StatelessWidget {
  final String imagePath;
  final double size;
  
  const RoundedImageNetwork({
    required this.imagePath,
    required this.size,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imagePath,
      imageBuilder: (BuildContext context, ImageProvider<Object> imageProvider) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: imageProvider,
            ),
            borderRadius: BorderRadius.circular(30.0),
            color: ColorResources.black,
          ),
        );
      },
      placeholder: (BuildContext context, String url) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            image: const DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/images/default_image.png'),
            ),
            borderRadius: BorderRadius.circular(30.0),
            color: ColorResources.black,
          ),
        );
      },
      errorWidget: (BuildContext context, String url, dynamic error) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            image: const DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/images/default_image.png'),
            ),
            borderRadius: BorderRadius.circular(30.0),
            color: ColorResources.black,
          ),
        );
      },
    );
  }
}

class RoundedImageNetworkWithStatusIndicator extends RoundedImageNetwork {
  final bool isActive;
  final bool group;

  const RoundedImageNetworkWithStatusIndicator({
    required Key key,
    required String imagePath,
    required double size,
    required this.isActive,
    required this.group,
  }) : super(key: key, imagePath: imagePath, size: size);


  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        super.build(context),
        group 
        ? const SizedBox() 
        : Container(
          height: size * 0.20,
          width: size * 0.20,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(size)
          ),
        )
      ],
    );
  }
}

class RoundedImageNetworkWithoutStatusIndicator extends RoundedImageNetwork {
  final bool group;

  const RoundedImageNetworkWithoutStatusIndicator({
    required Key key,
    required String imagePath,
    required double size,
    required this.group,
  }) : super(key: key, imagePath: imagePath, size: size);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        super.build(context),
      ],
    );
  }
}