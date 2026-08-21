import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/core/widgets/buttons/button_big.dart';
import 'package:trabajo_hub/core/widgets/input/input_drop_down.dart';
import 'package:trabajo_hub/core/widgets/input/input_field.dart';
import 'package:trabajo_hub/features/auth/presentation/verify_email.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _selectedDesination = 'RN';

  bool _obscurePassword = true;

  List<String> nurseDesignations = ["RN", "LVN", "LPN", "CNA", "HHA", "THERAPIST", "CAREGIVER"];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "email": _email.text.trim(),
      "password": _password.text,
      "firstName": _firstName.text.trim(),
      "lastName": _lastName.text.trim(),
      "designation": _selectedDesination,
    };

    final userId = await ref.read(authProvider.notifier).register(payload);

    if (!mounted) return;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(userId: userId,email:_email.text.trim())),
      );
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Registration failed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: accentColor.withOpacity(0.9), fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Let's get you started",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                          child: Inputfield(
                        inputHintText: 'John',
                        inputTitle: 'First Name',
                        textObscure: authState.isLoading,
                        textController: _firstName,
                        isreadOnly: authState.isLoading,
                        icon: Icon(Icons.person_outline,),
                            validator: (v) => v!.isEmpty ? 'First name is required' : null,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child:Inputfield(
                        inputHintText: 'Doe',
                        inputTitle: 'Last Name',
                        textObscure: authState.isLoading,
                        textController: _lastName,
                        isreadOnly: authState.isLoading,
                        validator: (v) => v!.isEmpty ? 'Last name is required' : null,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Inputfield(
                    textController: _email,
                    inputTitle: 'Email Address',
                    icon: Icon(Icons.email_outlined),
                    textObscure: authState.isLoading,
                    isreadOnly: authState.isLoading,
                    inputHintText: "Enter your email address",
                    validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  Inputfield(
                    inputTitle: 'Password',
                    textController: _password,
                    textObscure: _obscurePassword,
                    validator: (v) => (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
                    icon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B4),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    isreadOnly: false,
                    inputHintText: "************",
                  ),
                  const SizedBox(height: 16),
                  InputDropDown(
                      options: nurseDesignations,
                      onOptionSelected: (value) => setState(() => _selectedDesination = value),
                      inputTitle: "Designation"),
                  const SizedBox(height: 32),
                  Button(
                    icon: Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
                    buttonText: "Create Account",
                    onPressed: authState.isLoading ? null : _register,
                      isLoading:authState.isLoading
                  ),
                  const SizedBox(height: 20),
                  _buildSignInRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Color(0xFF94A3B4), fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child:  Text('Sign in', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }
}
