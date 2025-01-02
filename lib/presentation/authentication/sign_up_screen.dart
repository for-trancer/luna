import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:luna/presentation/authentication/login_screen.dart';
import 'package:luna/presentation/authentication/widgets/auth_text_field.dart';
import 'package:luna/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    // Check if any of the fields are empty
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    // Check if password and confirm password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    try {
      // Performing the sign up
      final user = await _authService.signUp(email, password);
      if (user != null) {
        // Displaying success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Sign Up Successful")));
        // Navigate to login
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => LoginScreen()));
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
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
              padding:
                  const EdgeInsets.all(16.0), // Add padding for better layout
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
                  // Text
                  authTitleText('Welcome To Luna!'),
                  kHeight20,
                  // Email
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                  ),
                  kHeight20,
                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.key,
                  ),
                  kHeight20,
                  // Confirm Password
                  AuthTextField(
                    controller: _confirmController,
                    hintText: 'Confirm Password',
                    icon: Icons.key,
                  ),
                  kHeight20,
                  ElevatedButton(
                    onPressed: () {
                      _handleSignUp(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(350, 40),
                    ),
                    child: const Text(
                      'SIGN UP',
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
                          builder: (BuildContext context) => LoginScreen());
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already Have An Account? ',
                            style: TextStyle(
                              fontSize: 13,
                            )),
                        Text('Login',
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
      ),
    );
  }
}
