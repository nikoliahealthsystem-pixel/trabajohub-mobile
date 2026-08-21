import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../providers/auth_provider.dart';

class TwoFASetupScreen extends ConsumerStatefulWidget {
  const TwoFASetupScreen({super.key});

  @override
  ConsumerState<TwoFASetupScreen> createState() =>
      _TwoFASetupScreenState();
}

class _TwoFASetupScreenState extends ConsumerState<TwoFASetupScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Step 0 = loading QR, 1 = show QR, 2 = confirm code, 3 = success
  int _step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQR());
  }

  Future<void> _loadQR() async {
    setState(() => _step = 0);
    final ok = await ref.read(authProvider.notifier).setup2FA();
    if (mounted) setState(() => _step = ok ? 1 : 0);
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == 6) _confirmCode();
  }

  Future<void> _confirmCode() async {
    if (_code.length < 6) return;
    final ok = await ref.read(authProvider.notifier).enable2FA(_code);
    if (!mounted) return;
    if (ok) setState(() => _step = 3);
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
                  onTap: () => Navigator.pop(context),
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
                const Text('Set up\ntwo-factor auth',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
                const SizedBox(height: 6),
                Text(
                  _step == 1
                      ? 'Scan the QR code with your authenticator app'
                      : _step == 2
                      ? 'Enter the 6-digit code to confirm'
                      : 'Securing your account',
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildStepBody(authState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody(authState) {
    switch (_step) {
      case 0:
        return const Center(
            child:
            CircularProgressIndicator(color: Color(0xFF0A9FBF)));

      case 1:
        return _buildQRStep(authState);

      case 2:
        return _buildConfirmStep(authState);

      case 3:
        return _buildSuccessStep();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQRStep(dynamic authState) {
    final qrCode = authState.twoFAQrCode as String?;
    final secret = authState.twoFASecret as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _StepIndicator(current: 1, total: 2),
        const SizedBox(height: 24),

        // QR code image
        if (qrCode != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Image.memory(
              // qrCodeUrl is a base64 data URL: "data:image/png;base64,..."
              _base64FromDataUrl(qrCode),
              width: 220, height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Manual entry secret
        if (secret != null) ...[
          const Text('Or enter this code manually:',
              style: TextStyle(fontSize: 13, color: Color(0xFF536C79))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: secret));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Secret copied to clipboard'),
                    behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0A9FBF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(secret,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFF0A7D95),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  const Icon(Icons.copy_rounded,
                      size: 16, color: Color(0xFF0A9FBF)),
                ],
              ),
            ),
          ),
        ],

        const Spacer(),

        // Recommended apps note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8ED)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF536C79)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Use Google Authenticator, Authy, or any TOTP app to scan the QR code.',
                  style:
                  TextStyle(fontSize: 12, color: Color(0xFF536C79)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Button(buttonText: 'I\'ve scanned the code',
          onPressed: () => setState(() => _step = 2),),
        SizedBox(height: 12,)
      ],
    );
  }

  Widget _buildConfirmStep(dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _StepIndicator(current: 2, total: 2),
        const SizedBox(height: 32),
        const Text(
          'Enter the 6-digit code shown in your authenticator app to complete setup:',
          style: TextStyle(fontSize: 14, color: Color(0xFF536C79), height: 1.5),
        ),
        const SizedBox(height: 28),

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
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE2E8ED)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE2E8ED)),
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

        if (authState.error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
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
                    authState.error!.replaceAll('Exception: ', ''),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFB91C1C)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        Button(buttonText: 'Activate 2FA',isLoading: authState.isLoading,onPressed: _confirmCode,),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _step = 1;
              for (final c in _controllers) c.clear();
            }),
            child: const Text('Go back',
                style: TextStyle(color: Color(0xFF536C79))),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0A9FBF), Color(0xFF28D744)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0A9FBF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('2FA enabled!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2632))),
          const SizedBox(height: 8),
          const Text(
            'Your account is now protected.\nYou\'ll need your authenticator app to log in.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Color(0xFF536C79), height: 1.5),
          ),
          const SizedBox(height: 32),
          Button(buttonText: 'Done',onPressed: () => Navigator.pop(context),)
        ],
      ),
    );
  }

  Uint8List _base64FromDataUrl(String dataUrl) {
    final base64 = dataUrl.split(',').last;
    return base64Decode(base64);
  }
}

// ── Disable 2FA sheet ─────────────────────────────────────────────────

class Disable2FASheet extends ConsumerStatefulWidget {
  const Disable2FASheet({super.key});

  static Future<bool?> show(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const Disable2FASheet(),
      );

  @override
  ConsumerState<Disable2FASheet> createState() => _Disable2FASheetState();
}

class _Disable2FASheetState extends ConsumerState<Disable2FASheet> {
  final _passwordController = TextEditingController();
  final List<TextEditingController> _totpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _totpFocusNodes =
  List.generate(6, (_) => FocusNode());
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    for (final c in _totpControllers) c.dispose();
    for (final f in _totpFocusNodes) f.dispose();
    super.dispose();
  }

  String get _totpCode =>
      _totpControllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _totpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _totpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty || _totpCode.length < 6) return;
    final ok = await ref.read(authProvider.notifier).disable2FA(
      totpCode: _totpCode,
      password: _passwordController.text,
    );
    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Disable 2FA',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2632))),
          const SizedBox(height: 6),
          const Text(
            'Enter your password and current authenticator code to disable two-factor authentication.',
            style: TextStyle(fontSize: 13, color: Color(0xFF536C79), height: 1.4),
          ),
          const SizedBox(height: 20),

          // Password field
          const Text('PASSWORD',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B4),
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Current password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18, color: const Color(0xFF94A3B4),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8ED))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8ED))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF0A9FBF), width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // TOTP input
          const Text('AUTHENTICATOR CODE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B4),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
                  (i) => SizedBox(
                width: 44,
                child: TextField(
                  controller: _totpControllers[i],
                  focusNode: _totpFocusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2632)),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFFE2E8ED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(color: Color(0xFFE2E8ED)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF0A9FBF), width: 1.5),
                    ),
                  ),
                  onChanged: (v) => _onDigitChanged(v, i),
                ),
              ),
            ),
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF09595)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFB91C1C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.error!.replaceAll('Exception: ', ''),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: authState.isLoading
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                  : const Text('Disable 2FA',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(total, (i) {
      final active = i + 1 == current;
      return Container(
        margin: const EdgeInsets.only(right: 6),
        width: active ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0A9FBF)
              : const Color(0xFFE2E8ED),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }),
  );
}