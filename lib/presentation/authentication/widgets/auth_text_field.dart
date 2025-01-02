import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';

// TextField
// ignore: must_be_immutable
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: authScreenButtonBgColor,
      ),
      child: TextField(
        controller: controller,
        // check if it is an password field
        obscureText: hintText == 'Password' || hintText == 'Confirm Password',
        decoration: InputDecoration(
          hintText: hintText,
          suffixIcon: Icon(
            icon,
            color: secondaryColor,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
