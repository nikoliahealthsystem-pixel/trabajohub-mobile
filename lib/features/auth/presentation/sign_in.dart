import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/features/auth/presentation/sign_up.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../../../core/widgets/input/input_field.dart';
import '../providers/auth_provider.dart';
import 'forgot_password.dart';
import 'two_fa_verify_screen.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Future<void> _signIn() async {
  //   // Basic validation
  //   if (email.text.isEmpty || password.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please fill in all fields')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final success = await ref.read(authProvider.notifier).login(
  //       email.text.trim(),
  //       password.text.trim(),
  //     );
  //
  //     if (success && mounted) {
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => ActiveSession()));
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Logged in'),
  //           behavior: SnackBarBehavior.floating,
  //           backgroundColor: Colors.green,),
  //       );
  //     } else if (mounted) {
  //       // You can use the error message from the state
  //       final error = ref.read(authProvider).error;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(error ?? 'Login failed'),
  //           behavior: SnackBarBehavior.floating,
  //           backgroundColor: Colors.redAccent,),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('An error occurred: $e'),
  //           behavior: SnackBarBehavior.floating,
  //           backgroundColor: Colors.redAccent,),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //
  //     }
  //   }
  // }

  Future<void> _handleLogin() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey,),
      );
      return;
    }
    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.login(email.text.trim(),
      password.text.trim(),);

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.requires2FA) {
      // Navigate to 2FA challenge screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TwoFAVerifyScreen()),
      );
    } else if (success) {
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) =>ActiveSession()), (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,),
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Login failed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,),
      );
    }
    // error is in authState.error — display it in your existing error widget
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    wordSpacing: -2),
              ),
              const Text(
                'Glad to see you again!',
                style: TextStyle(
                    fontSize: 20, wordSpacing: -2, color: Colors.grey),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Inputfield(
                  inputHintText: 'email@server.com',
                  inputTitle: 'Email Address',
                  textObscure: false,
                  textController: email,
                  isreadOnly: false,
                ),
                Inputfield(
                  isreadOnly: false,
                  inputHintText: 'Input Your Password',
                  inputTitle: 'Password',
                  textObscure: !_isPasswordVisible,
                  textController: password,
                  icon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ForgotPasswordScreen()));
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                        wordSpacing: -2,
                        fontWeight: FontWeight.w500,
                        color: accentColor),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Button(
              buttonText: "LogIn",
              onPressed: authState.isLoading ? null : _handleLogin,
              isLoading:authState.isLoading
          ),
          const SizedBox(height: 24),
          _buildSignUpRow()
        ],
      ),
    );
  }

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF94A3B4), fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SignUpScreen())),
          child:  Text('Sign Up', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }
}