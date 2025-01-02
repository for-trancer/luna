import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/authentication/login_screen.dart';
import 'package:luna/presentation/authentication/sign_up_screen.dart';
import 'package:luna/presentation/authentication/widgets/auth_text_field.dart';
import 'package:luna/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _handlePasswordReset() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      log(email);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in the field')));
      return;
    }

    try {
      await _authService.forgotPassword(email);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent!')));
      Navigator.of(context).pop();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains(']')) {
        errorMsg = errorMsg.split(']')[1].trim();
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        errorMsg,
        textAlign: TextAlign.center,
      )));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        // Wrap Column in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Allow the column to take minimum space
            children: [
              Container(
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 150,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              kHeight10,
              // text
              authTitleText('Forgot Password?'),
              kHeight20,
              const Text(
                "Enter your email and we'll send you a reset\n link.",
                textAlign: TextAlign.center,
              ),
              kHeight20,
              // email
              AuthTextField(
                controller: _emailController,
                hintText: 'Email',
                icon: Icons.email,
              ),
              kHeight20,
              ElevatedButton(
                onPressed: () {
                  _handlePasswordReset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  minimumSize: const Size(double.infinity,
                      40), // Use double.infinity for full width
                ),
                child: const Text(
                  'SEND LINK',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              kHeight20,
              // Get Started
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) => SignUpScreen());
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 13,
                        )),
                    Text('Get Started',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          decoration: TextDecoration.underline,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
