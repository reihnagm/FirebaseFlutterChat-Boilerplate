import 'package:flutter/material.dart';


class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final Function (String) onSaved;
  final String regex;
  final String hintText;
  final bool obscureText;
  final Color? fillColor;

  const CustomTextFormField({
    Key? key, 
    this.controller,
    required this.onSaved,
    required this.regex,
    required this.hintText,
    required this.obscureText,
    this.fillColor = const Color.fromRGBO(30, 29, 37, 1.0)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onSaved: (val) => onSaved(val!),
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white
      ),
      obscureText: obscureText,
      validator: (val) {
        return RegExp(regex).hasMatch(val!) ? null : 'Enter a valid value.';
      },
      decoration: InputDecoration(
        fillColor:  fillColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54
        )
      ),
    );
  }
}


// ignore: must_be_immutable
class CustomTextField extends StatelessWidget {
  final Function(String) onEditingComplete;
  final String hintText; 
  final bool obscureText; 
  final TextEditingController controller;
  IconData? icon;

  CustomTextField({Key? key, 
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