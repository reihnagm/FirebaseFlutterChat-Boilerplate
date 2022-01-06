import 'package:flutter/material.dart';

import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final Function (String) onSaved;
  final String regex;
  final String hintText;
  final Widget label;
  final bool obscureText;
  final Color? fillColor;

  const CustomTextFormField({
    Key? key, 
    this.controller,
    required this.onSaved,
    required this.regex,
    required this.hintText,
    required this.label,
    required this.obscureText,
    this.fillColor = ColorResources.white
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onSaved: (val) => onSaved(val!),
      cursorColor: ColorResources.hintColor,
      style: TextStyle(
        letterSpacing: 1.3,
        color: ColorResources.textBlackPrimary,
        fontSize: Dimensions.fontSizeSmall
      ),
      obscureText: obscureText,
      validator: (val) {
        return RegExp(regex).hasMatch(val!) ? null : 'Enter a valid value.';
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.email,
          size: 20.0,  
          color: ColorResources.backgroundBlackPrimary,
        ),
        label: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        fillColor: fillColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: ColorResources.hintColor,
          fontSize: Dimensions.fontSizeSmall
        )
      ),
    );
  }
}


class CustomTextMessageFormField extends StatelessWidget {
  final TextEditingController? controller;
  final Function (String) onSaved;
  final Function (String) onChange;
  final String regex;
  final String hintText;
  final Widget label;
  final bool obscureText;
  final Color? fillColor;

  const CustomTextMessageFormField({
    Key? key, 
    this.controller,
    required this.onSaved,
    required this.onChange,
    required this.regex,
    required this.hintText,
    required this.label,
    required this.obscureText,
    this.fillColor = ColorResources.white
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onSaved: (val) => onSaved(val!),
      onChanged: (val) => onChange(val),
      cursorColor: ColorResources.white,
      style: TextStyle(
        color: ColorResources.white,
        fontSize: Dimensions.fontSizeSmall
      ),
      maxLines: 2,
      decoration: InputDecoration(
        label: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        fillColor: fillColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: ColorResources.gainsBoro,
          fontSize: Dimensions.fontSizeSmall
        )
      ),
    );
  }
}

class CustomTextPasswordFormField extends StatefulWidget {
  final TextEditingController? controller;
  final Function (String) onSaved;
  final String regex;
  final String hintText;
  final Widget label;
  final Color? fillColor;

  const CustomTextPasswordFormField({
    Key? key, 
    this.controller,
    required this.onSaved,
    required this.regex,
    required this.hintText,
    required this.label,
    this.fillColor = ColorResources.white
  }) : super(key: key);

  @override
  State<CustomTextPasswordFormField> createState() => _CustomTextPasswordFormFieldState();
}

class _CustomTextPasswordFormFieldState extends State<CustomTextPasswordFormField> {
  bool obscureText = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onSaved: (val) => widget.onSaved(val!),
      cursorColor: ColorResources.hintColor,
      style: TextStyle(
        letterSpacing: 1.3,
        color: ColorResources.textBlackPrimary,
        fontSize: Dimensions.fontSizeSmall
      ),
      obscureText: obscureText,
      validator: (val) {
        return RegExp(widget.regex).hasMatch(val!) ? null : 'Enter a valid value.';
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.lock,
          size: 20.0,  
          color: ColorResources.backgroundBlackPrimary,
        ),
        fillColor: widget.fillColor,
        filled: true,
        suffixIcon: InkWell(
          onTap: () {
            setState(() {
              obscureText = !obscureText;
            });
          },
          child: Icon(
            obscureText 
            ? Icons.visibility_off
            : Icons.visibility,
            size: 20.0,  
            color: ColorResources.backgroundBlackPrimary,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        label: widget.label,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: ColorResources.hintColor,
          fontSize: Dimensions.fontSizeSmall
        )
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final Function(String) onEditingComplete;
  final String hintText; 
  final bool obscureText; 
  final TextEditingController controller;
  final IconData? icon;

  const CustomTextField({Key? key, 
    required this.onEditingComplete,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    this.icon
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onEditingComplete: () => onEditingComplete(controller.value.text),
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white
      ),
      obscureText: obscureText,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        fillColor: const Color.fromRGBO(30, 29, 37, 1.0),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: Icon(
          icon, 
          color: Colors.white54,
        )
      )
    );
  }
}

class CustomTextSearchField extends StatelessWidget {
  final Function(String) onEditingComplete;
  final String hintText; 
  final TextEditingController controller;
  final IconData? icon;

  const CustomTextSearchField({Key? key, 
    required this.onEditingComplete,
    required this.hintText,
    required this.controller,
    this.icon
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onEditingComplete: () => onEditingComplete(controller.value.text),
      cursorColor: ColorResources.textBlackPrimary,
      style: TextStyle(
        fontSize: Dimensions.fontSizeSmall,
        color: ColorResources.textBlackPrimary
      ),
      decoration: InputDecoration(
        alignLabelWithHint: true,
        fillColor: ColorResources.white,
        filled: true,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: Dimensions.fontSizeSmall,
          color: ColorResources.textBlackPrimary,
        ),
        prefixIcon: Icon(
          icon, 
          color: ColorResources.backgroundBlackPrimary,
          size: 20.0,
        )
      )
    );
  }
}