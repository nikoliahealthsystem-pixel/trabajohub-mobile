import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../providers/auth_provider.dart';


class PayoutSettings {
  final String? preferredMethod;
  final bool stripeConnected;
  final bool stripeOnboardingComplete;
  final bool stripeChargesEnabled;
  final bool stripePayoutsEnabled;
  final bool bankConfigured;
  final String? bankName;
  final String? accountHolderName;
  final String? maskedAccountNumber;
  final String? bankStatus;

  const PayoutSettings({
    required this.preferredMethod,
    required this.stripeConnected,
    required this.stripeOnboardingComplete,
    required this.stripeChargesEnabled,
    required this.stripePayoutsEnabled,
    required this.bankConfigured,
    required this.bankName,
    required this.accountHolderName,
    required this.maskedAccountNumber,
    required this.bankStatus,
  });

  factory PayoutSettings.empty() {
    return const PayoutSettings(
      preferredMethod: null,
      stripeConnected: false,
      stripeOnboardingComplete: false,
      stripeChargesEnabled: false,
      stripePayoutsEnabled: false,
      bankConfigured: false,
      bankName: null,
      accountHolderName: null,
      maskedAccountNumber: null,
      bankStatus: null,
    );
  }

  factory PayoutSettings.fromJson(Map<String, dynamic> json) {
    final stripe = Map<String, dynamic>.from(json['stripe'] ?? {});
    final bankTransfer = Map<String, dynamic>.from(json['bankTransfer'] ?? {});

    return PayoutSettings(
      preferredMethod: json['preferredMethod'] as String?,
      stripeConnected: stripe['connected'] == true,
      stripeOnboardingComplete: stripe['onboardingComplete'] == true,
      stripeChargesEnabled: stripe['chargesEnabled'] == true,
      stripePayoutsEnabled: stripe['payoutsEnabled'] == true,
      bankConfigured: bankTransfer['configured'] == true,
      bankName: bankTransfer['bankName'] as String?,
      accountHolderName: bankTransfer['accountHolderName'] as String?,
      maskedAccountNumber: bankTransfer['accountNumber'] as String?,
      bankStatus: bankTransfer['status'] as String?,
    );
  }
}

class PayoutMethodCard extends ConsumerStatefulWidget {
  const PayoutMethodCard({super.key});

  @override
  ConsumerState<PayoutMethodCard> createState() => PayoutMethodCardState();
}

class PayoutMethodCardState extends ConsumerState<PayoutMethodCard> {
  bool _loading = true;
  bool _saving = false;
  PayoutSettings _settings = PayoutSettings.empty();

  Dio get _dio => DioClient.dio;

  @override
  void initState() {
    super.initState();
    _loadPaymentSettings();
  }

  Map<String, dynamic> _responseData(Response response) {
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<void> _loadPaymentSettings() async {
    try {
      setState(() => _loading = true);

      final response = await _dio.get('/users/me/payment-method');
      final data = _responseData(response);

      if (!mounted) return;
      setState(() {
        _settings = PayoutSettings.fromJson(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Unable to load payout settings', isError: true);
    }
  }

  Future<void> _connectStripe() async {
    try {
      setState(() => _saving = true);

      final response = await _dio.post('/users/me/payment-method/stripe/connect');
      final data = _responseData(response);

      final onboardingUrl = data['onboardingUrl'] as String?;

      if (onboardingUrl == null || onboardingUrl.isEmpty) {
        _showSnack('Stripe onboarding link was not returned', isError: true);
        return;
      }

      final launched = await launchUrl(
        Uri.parse(onboardingUrl),
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        _showSnack('Could not open Stripe. Please try again.', isError: true);
        return;
      }

      await _loadPaymentSettings();
    } catch (e) {
      _showSnack(_extractError(e, 'Failed to connect Stripe'), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _setPreferredMethod(String method) async {
    try {
      setState(() => _saving = true);

      final response = await _dio.patch(
        '/users/me/payment-method/preferred',
        data: {
          'method': method,
        },
      );

      final data = _responseData(response);

      if (!mounted) return;
      setState(() {
        _settings = PayoutSettings.fromJson(data);
      });

      _showSnack('Preferred payout method updated');
      await ref.read(authProvider.notifier).fetchMe();
    } catch (e) {
      _showSnack(_extractError(e, 'Unable to update payout method'), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openBankTransferDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !_saving,
      builder: (_) => const _BankTransferDialog(),
    );

    if (saved == true) {
      await _loadPaymentSettings();
      await ref.read(authProvider.notifier).fetchMe();
    }
  }

  String _extractError(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return fallback;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF0F6E56),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stripeSelected = _settings.preferredMethod == 'STRIPE';
    final bankSelected = _settings.preferredMethod == 'BANK_TRANSFER';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: _loading
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(color: accentColor),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: accentColor),
              const SizedBox(width: 8),
              const Text(
                'Payout Method',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to receive your earnings.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          _PayoutOptionTile(
            title: 'Stripe',
            subtitle: _settings.stripeConnected
                ? _stripeStatusText()
                : 'Securely connect a Stripe account for payouts.',
            icon: Icons.account_balance_wallet_outlined,
            selected: stripeSelected,
            configured: _settings.stripeConnected,
            onSelect: _settings.stripeConnected && !_saving
                ? () => _setPreferredMethod('STRIPE')
                : null,
            trailing: TextButton(
              onPressed: _saving ? null : _connectStripe,
              child: Text(
                _settings.stripeConnected ? 'Manage' : 'Connect',
                style: TextStyle(color: accentColor),
              ),
            ),
          ),

          const SizedBox(height: 10),

          _PayoutOptionTile(
            title: 'Bank Transfer',
            subtitle: _settings.bankConfigured
                ? '${_settings.bankName ?? 'Bank'} • ${_settings.maskedAccountNumber ?? 'Account saved'}'
                : 'Add your bank details to receive direct transfers.',
            icon: Icons.account_balance_outlined,
            selected: bankSelected,
            configured: _settings.bankConfigured,
            statusLabel: _settings.bankStatus,
            onSelect: _settings.bankConfigured && !_saving
                ? () => _setPreferredMethod('BANK_TRANSFER')
                : null,
            trailing: TextButton(
              onPressed: _saving ? null : _openBankTransferDialog,
              child: Text(
                _settings.bankConfigured ? 'Update' : 'Add',
                style: TextStyle(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stripeStatusText() {
    if (_settings.stripePayoutsEnabled) {
      return 'Stripe is connected and payouts are enabled.';
    }

    if (_settings.stripeOnboardingComplete) {
      return 'Stripe onboarding is complete. Payout verification may still be pending.';
    }

    return 'Stripe is connected. Complete onboarding to enable payouts.';
  }
}

class _PayoutOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool configured;
  final String? statusLabel;
  final VoidCallback? onSelect;
  final Widget trailing;

  const _PayoutOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.configured,
    required this.onSelect,
    required this.trailing,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = accentColor;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withOpacity(0.06) : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xFFE8EDF2),
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: onSelect == null ? null : (_) => onSelect?.call(),
              activeColor: selectedColor,
            ),
            Icon(icon, color: selectedColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (configured) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF0F6E56),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _BankTransferDialog extends StatefulWidget {
  const _BankTransferDialog();

  @override
  State<_BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<_BankTransferDialog> {
  final _formKey = GlobalKey<FormState>();

  final _bankNameController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingOrSortCodeController = TextEditingController();
  final _swiftBicCodeController = TextEditingController();

  bool _saving = false;

  Dio get _dio => DioClient.dio;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _routingOrSortCodeController.dispose();
    _swiftBicCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _saving = true);

      await _dio.patch(
        '/users/me/payment-method/bank-transfer',
        data: {
          'bankName': _bankNameController.text.trim(),
          'accountHolderName': _accountHolderNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'routingOrSortCode': _routingOrSortCodeController.text.trim().isEmpty
              ? null
              : _routingOrSortCodeController.text.trim(),
          'swiftBicCode': _swiftBicCodeController.text.trim().isEmpty
              ? null
              : _swiftBicCodeController.text.trim().toUpperCase(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      final message = e is DioException && e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Unable to save bank details')
          : 'Unable to save bank details';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _accountNumberValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Account number is required';
    }

    if (text.length < 4 || text.length > 34) {
      return 'Account number must be 4–34 characters';
    }

    return null;
  }

  String? _swiftValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final valid = RegExp(r'^[A-Za-z0-9]{8}([A-Za-z0-9]{3})?$').hasMatch(text);

    if (!valid) {
      return 'SWIFT/BIC must be 8 or 11 alphanumeric characters';
    }

    return null;
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8EDF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_outlined, color: accentColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bank Transfer Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account number is sent securely to the server and stored encrypted. Only the masked account number will be shown later.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bankNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('Bank Name'),
                  validator: (value) => _required(value, 'Bank name'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _accountHolderNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Account Holder Name'),
                  validator: (value) => _required(value, 'Account holder name'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _accountNumberController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: _decoration(
                    'Account Number',
                    hint: 'Enter account number',
                  ),
                  validator: _accountNumberValidator,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _routingOrSortCodeController,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    'Routing/Sort Code',
                    hint: 'Optional where applicable',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length > 34) {
                      return 'Routing or sort code is too long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _swiftBicCodeController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration(
                    'SWIFT/BIC Code',
                    hint: 'Optional for international transfers',
                  ),
                  validator: _swiftValidator,
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Save Bank Transfer Details'),
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