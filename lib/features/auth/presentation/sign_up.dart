import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
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

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String _selectedDesignation = 'RN';
  bool _obscurePassword = true;

  static const Color _pageBackground = Color(0xFFF7F9FC);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _label = Color(0xFF344054);
  static const Color _muted = Color(0xFF98A2B3);
  static const Color _border = Color(0xFFE4E7EC);
  static const Color _inputBackground = Color(0xFFF9FAFB);
  static const Color _danger = Color(0xFFD92D20);

  final List<String> nurseDesignations = const [
    'RN',
    'LVN',
    'LPN',
    'CNA',
    'HHA',
    'THERAPIST',
    'CAREGIVER',
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final payload = {
      'email': _email.text.trim(),
      'password': _password.text,
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'designation': _selectedDesignation,
    };

    final userId = await ref.read(authProvider.notifier).register(payload);

    if (!mounted) return;

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VerifyEmailScreen(userId: userId, email: _email.text.trim()),
        ),
      );
      return;
    }

    final error = ref.read(authProvider).error;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Registration failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB42318),
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),

                      const SizedBox(height: 32),

                      _buildHeading(),

                      const SizedBox(height: 28),

                      _buildRegistrationCard(isLoading: authState.isLoading),

                      const SizedBox(height: 24),

                      _buildSignInRow(),

                      const SizedBox(height: 28),

                      _buildSecurityFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.arrow_back_rounded, size: 21, color: _heading),
            ),
          ),
        ),

        const SizedBox(width: 14),

        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10101828),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              'assets/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: ColorConstants.appGradient,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TrabajoHub',
                style: TextStyle(
                  color: _heading,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Nurse',
                style: TextStyle(
                  color: _body,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your nurse account',
          style: TextStyle(
            color: _heading,
            fontSize: 32,
            height: 1.08,
            letterSpacing: -0.9,
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 10),

        Text(
          'Join TrabajoHub to discover shifts, manage visits, keep track of your schedule, and build your work profile.',
          style: TextStyle(
            color: _body,
            fontSize: 14.5,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard({required bool isLoading}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal details',
            style: TextStyle(
              color: _heading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Use the same details that appear on your professional credentials.',
            style: TextStyle(color: _body, fontSize: 12.5, height: 1.4),
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstName,
                  focusNode: _firstNameFocus,
                  label: 'First name',
                  hintText: 'Sarah',
                  icon: Icons.person_outline_rounded,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _lastNameFocus.requestFocus();
                  },
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildTextField(
                  controller: _lastName,
                  focusNode: _lastNameFocus,
                  label: 'Last name',
                  hintText: 'Williams',
                  icon: Icons.badge_outlined,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _emailFocus.requestFocus();
                  },
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _email,
            focusNode: _emailFocus,
            label: 'Email address',
            hintText: 'nurse@example.com',
            icon: Icons.mail_outline_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            onSubmitted: (_) {
              _passwordFocus.requestFocus();
            },
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.isEmpty) {
                return 'Enter your email address';
              }

              final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

              if (!emailPattern.hasMatch(text)) {
                return 'Enter a valid email address';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          _buildPasswordField(isLoading: isLoading),

          const SizedBox(height: 20),

          _buildDesignationField(enabled: !isLoading),

          const SizedBox(height: 24),

          _buildAccountInfo(),

          const SizedBox(height: 24),

          _buildCreateAccountButton(isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required bool enabled,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          autocorrect: false,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          decoration: _inputDecoration(hintText: hintText, icon: icon),
        ),
      ],
    );
  }

  Widget _buildPasswordField({required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: _label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          obscuringCharacter: '•',
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) {
            final text = value ?? '';

            if (text.isEmpty) {
              return 'Create a password';
            }

            if (text.length < 8) {
              return 'Use at least 8 characters';
            }

            if (!RegExp(r'[A-Z]').hasMatch(text)) {
              return 'Add at least one uppercase letter';
            }

            if (!RegExp(r'[a-z]').hasMatch(text)) {
              return 'Add at least one lowercase letter';
            }

            if (!RegExp(r'[0-9]').hasMatch(text)) {
              return 'Add at least one number';
            }

            return null;
          },
          decoration: _inputDecoration(
            hintText: 'Create a secure password',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 21,
                color: _muted,
              ),
            ),
          ),
        ),

        const SizedBox(height: 9),

        const Text(
          'Use at least 8 characters with uppercase, lowercase, and a number.',
          style: TextStyle(color: _muted, fontSize: 11.5, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildDesignationField({required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional designation',
          style: TextStyle(
            color: _label,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: _selectedDesignation,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _body),
          decoration: _inputDecoration(
            hintText: 'Select designation',
            icon: Icons.workspace_premium_outlined,
          ),
          items: nurseDesignations
              .map(
                (designation) => DropdownMenuItem(
                  value: designation,
                  child: Text(
                    _designationLabel(designation),
                    style: const TextStyle(
                      color: _heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedDesignation = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  String _designationLabel(String designation) {
    switch (designation) {
      case 'RN':
        return 'Registered Nurse (RN)';
      case 'LVN':
        return 'Licensed Vocational Nurse (LVN)';
      case 'LPN':
        return 'Licensed Practical Nurse (LPN)';
      case 'CNA':
        return 'Certified Nursing Assistant (CNA)';
      case 'HHA':
        return 'Home Health Aide (HHA)';
      case 'THERAPIST':
        return 'Therapist';
      case 'CAREGIVER':
        return 'Caregiver';
      default:
        return designation;
    }
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: accentColor, size: 20),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'After creating your account, you will verify your email and continue setting up your nurse profile and credentials.',
              style: TextStyle(
                color: _label,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountButton({required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : ColorConstants.appGradient,
          color: isLoading ? const Color(0xFFD0D5DD) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: accentColor.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _register,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    key: ValueKey('create'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create nurse account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, size: 21, color: _body),
      suffixIcon: suffix,
      filled: true,
      fillColor: _inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accentColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF04438)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF04438), width: 1.6),
      ),
      errorStyle: const TextStyle(
        color: _danger,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSignInRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: _body, fontSize: 14),
        ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Text(
                'Sign in',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFooter() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 15, color: _muted),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Your account information is protected and securely transmitted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
