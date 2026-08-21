import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/features/auth/presentation/verify_email.dart';
import 'package:trabajo_hub/features/auth/state/auth_state.dart';

import '../../../core/widgets/buttons/button_big.dart';
import '../../../core/widgets/input/input_field.dart';
import '../providers/auth_provider.dart';
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  void _submit() async {
    await ref.read(authProvider.notifier).forgotPassword(emailController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("If the email exists, a reset link has been sent"),behavior: SnackBarBehavior.floating,backgroundColor: accentColor,),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Forgot Password",style: TextStyle(fontSize: 28,fontWeight: FontWeight.w700),),
            SizedBox(height: 12,),
            Text("Enter the email address associated with your account and we'll send you a link to reset your password.",style: TextStyle(fontSize: 14),),
            SizedBox(height: 32,),
            Inputfield(
              inputHintText: 'email@server.com',
              inputTitle: 'Email Address',
              textObscure: false,
              textController: emailController,
              isreadOnly: false,
            ),
            const SizedBox(height: 20),
            Button(
                buttonText: "Send Reset Link",
                onPressed: authState.isLoading ? null : _submit,
                isLoading: authState.isLoading
            ),
            SizedBox(height: 12,),
            Center(child:
            TextButton(onPressed: ()=>Navigator.pop(context), child: Text("Back to Sign In",style: TextStyle(color: accentColor),)),)
          ],
        ),
      ),
    );
  }
}