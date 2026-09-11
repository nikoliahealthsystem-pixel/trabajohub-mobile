import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:trabajo_hub/active_session.dart';
import 'package:trabajo_hub/features/auth/presentation/sign_up.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'forgot_password.dart';
import 'two_fa_verify_screen.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _rememberMeKey = 'login_remember_me';
  static const String _rememberedEmailKey = 'login_remembered_email';

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _rememberLoaded = false;

  static const Color _pageBackground = Color(0xFFF7F9FC);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _label = Color(0xFF344054);
  static const Color _muted = Color(0xFF98A2B3);
  static const Color _border = Color(0xFFE4E7EC);
  static const Color _inputBackground = Color(0xFFF9FAFB);
  static const Color _danger = Color(0xFFD92D20);

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    try {
      final rememberValue = await _storage.read(key: _rememberMeKey);

      final rememberedEmail = await _storage.read(key: _rememberedEmailKey);

      if (!mounted) return;

      final shouldRemember = rememberValue == 'true';

      setState(() {
        _rememberMe = shouldRemember;
        _rememberLoaded = true;

        if (shouldRemember &&
            rememberedEmail != null &&
            rememberedEmail.trim().isNotEmpty) {
          email.text = rememberedEmail.trim();
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _rememberLoaded = true;
      });
    }
  }

  Future<void> _saveRememberPreference() async {
    try {
      await _storage.write(
        key: _rememberMeKey,
        value: _rememberMe ? 'true' : 'false',
      );

      if (_rememberMe) {
        await _storage.write(
          key: _rememberedEmailKey,
          value: email.text.trim(),
        );
      } else {
        await _storage.delete(key: _rememberedEmailKey);
      }
    } catch (_) {
      // Remember-me failure should never block login.
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final notifier = ref.read(authProvider.notifier);

    final success = await notifier.login(email.text.trim(), password.text);

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.requires2FA) {
      await _saveRememberPreference();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TwoFAVerifyScreen()),
      );

      return;
    }

    if (success) {
      await _saveRememberPreference();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ActiveSession()),
        (_) => false,
      );

      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                authState.error ?? 'Unable to sign in. Please try again.',
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 46,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandHeader(),

                      const SizedBox(height: 40),

                      _buildWelcomeSection(),

                      const SizedBox(height: 28),

                      _buildLoginCard(isLoading: authState.isLoading),

                      const SizedBox(height: 22),

                      _buildSignUpRow(),

                      const Spacer(),

                      const SizedBox(height: 32),

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

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12101828),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: ColorConstants.appGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TrabajoHub',
                style: TextStyle(
                  color: _heading,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Nurse',
                style: TextStyle(
                  color: _body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            color: _heading,
            fontSize: 34,
            height: 1.08,
            letterSpacing: -1.1,
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 10),

        Text(
          'Sign in to manage your shifts, visits, schedule, earnings, and account.',
          style: TextStyle(
            color: _body,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard({required bool isLoading}) {
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
            spreadRadius: 0,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email address',
                style: TextStyle(
                  color: _label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: email,
                focusNode: emailFocus,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                onFieldSubmitted: (_) {
                  passwordFocus.requestFocus();
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
                decoration: _inputDecoration(
                  hintText: 'nurse@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      color: _label,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 4,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: password,
                focusNode: passwordFocus,
                enabled: !isLoading,
                obscureText: !_isPasswordVisible,
                obscuringCharacter: '•',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enableSuggestions: false,
                autocorrect: false,
                onFieldSubmitted: (_) {
                  if (!isLoading) {
                    _handleLogin();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }

                  return null;
                },
                decoration: _inputDecoration(
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _isPasswordVisible
                        ? 'Hide password'
                        : 'Show password',
                    splashRadius: 22,
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _muted,
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              _buildRememberRow(isLoading: isLoading),

              const SizedBox(height: 24),

              _buildSignInButton(isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRememberRow({required bool isLoading}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isLoading || !_rememberLoaded
          ? null
          : () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _rememberMe ? accentColor : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _rememberMe ? accentColor : const Color(0xFFD0D5DD),
                  width: 1.4,
                ),
              ),
              child: _rememberMe
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Remember me on this device',
                style: TextStyle(
                  color: _label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Tooltip(
              message: 'Your password is never stored by TrabajoHub.',
              child: const Icon(
                Icons.info_outline_rounded,
                color: _muted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton({required bool isLoading}) {
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
          onPressed: isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
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
                    key: ValueKey('button'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign in',
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      errorStyle: const TextStyle(
        color: _danger,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSignUpRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'New to TrabajoHub? ',
          style: TextStyle(
            color: _body,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Text(
                'Create account',
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
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: _muted),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Secure access to your TrabajoHub account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Text(
            'For authorized nurses and healthcare professionals',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB0B7C3),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
