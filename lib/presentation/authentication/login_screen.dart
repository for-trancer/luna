import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/authentication/forgot_password_screen.dart';
import 'package:luna/presentation/authentication/sign_up_screen.dart';
import 'package:luna/presentation/authentication/widgets/auth_text_field.dart';
import 'package:luna/presentation/home/home_screen.dart';
import 'package:luna/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _handleLogin(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please Fill In All Fields'),
      ));
      return;
    }

    try {
      final user = await _authService.signIn(email, password);

      if (user != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Login Successful')));
        // Navigate To Home Screen
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains(']')) {
        // Extracting Only the content of exception from response
        errorMessage = errorMessage.split(']')[1].trim();
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          errorMessage,
          textAlign: TextAlign.center,
        ),
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: 400,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                authTitleText('Welcome Back!'),
                kHeight20,
                // email
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                ),
                kHeight20,
                // password
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.key,
                ),
                kHeight20,
                // forgot password
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) =>
                            ForgotPasswordScreen());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    width: 350,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                kHeight20,
                ElevatedButton(
                  onPressed: () {
                    _handleLogin(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    minimumSize: const Size(350, 40),
                  ),
                  child: const Text(
                    'SIGN IN',
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
      ),
    );
  }
}

Text authTitleText(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
  );
}
