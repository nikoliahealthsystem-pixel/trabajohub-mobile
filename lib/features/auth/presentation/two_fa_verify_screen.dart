import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import '../../../active_session.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../providers/auth_provider.dart';

class TwoFAVerifyScreen extends ConsumerStatefulWidget {
  const TwoFAVerifyScreen({super.key});

  @override
  ConsumerState<TwoFAVerifyScreen> createState() =>
      _TwoFAVerifyScreenState();
}

class _TwoFAVerifyScreenState extends ConsumerState<TwoFAVerifyScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_code.length < 6) return;
    final ok = await ref.read(authProvider.notifier).verify2FA(_code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) =>ActiveSession()), (_) => false);      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,),
      );
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-submit when all 6 digits entered
    if (_code.length == 6) _submit();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          // Header
          Container(
            width: double.maxFinite,
            decoration: const BoxDecoration(
              gradient: ColorConstants.appGradient,
            ),
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).cancel2FAChallenge();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Two-factor\nauthentication',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
                const SizedBox(height: 8),
                const Text(
                    'Enter the 6-digit code from your authenticator app',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // OTP input grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                          (i) => SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2632)),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE2E8ED)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE2E8ED)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0A9FBF), width: 2),
                            ),
                          ),
                          onChanged: (v) => _onDigitChanged(v, i),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF09595)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Color(0xFFB91C1C)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!
                                  .replaceAll('Exception: ', ''),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB91C1C)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Verify button
                  Button(
                    buttonText: 'Verify',
                    onPressed:
                  authState.isLoading ? null : _submit,),

                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref
                            .read(authProvider.notifier)
                            .cancel2FAChallenge();
                        Navigator.pop(context);
                      },
                      child: const Text('Use a different account',
                          style: TextStyle(color: Color(0xFF536C79))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}