import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../providers/auth_provider.dart';

class PayoutSettings {
  final bool stripeConnected;
  final bool stripeOnboardingComplete;
  final bool stripeChargesEnabled;
  final bool stripePayoutsEnabled;

  const PayoutSettings({
    required this.stripeConnected,
    required this.stripeOnboardingComplete,
    required this.stripeChargesEnabled,
    required this.stripePayoutsEnabled,
  });

  factory PayoutSettings.empty() {
    return const PayoutSettings(
      stripeConnected: false,
      stripeOnboardingComplete: false,
      stripeChargesEnabled: false,
      stripePayoutsEnabled: false,
    );
  }

  factory PayoutSettings.fromJson(Map<String, dynamic> json) {
    final rawStripe = json['stripe'];

    final stripe = rawStripe is Map
        ? Map<String, dynamic>.from(rawStripe)
        : const <String, dynamic>{};

    return PayoutSettings(
      stripeConnected: stripe['connected'] == true,
      stripeOnboardingComplete: stripe['onboardingComplete'] == true,
      stripeChargesEnabled: stripe['chargesEnabled'] == true,
      stripePayoutsEnabled: stripe['payoutsEnabled'] == true,
    );
  }

  bool get stripeReady =>
      stripeConnected && stripeOnboardingComplete && stripePayoutsEnabled;

  bool get stripeNeedsAction => stripeConnected && !stripeReady;
}

class PayoutMethodCard extends ConsumerStatefulWidget {
  const PayoutMethodCard({super.key});

  @override
  ConsumerState<PayoutMethodCard> createState() => PayoutMethodCardState();
}

class PayoutMethodCardState extends ConsumerState<PayoutMethodCard>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _saving = false;
  bool _refreshingStripe = false;
  bool _awaitingStripeReturn = false;

  String? _inlineError;

  PayoutSettings _settings = PayoutSettings.empty();

  Dio get _dio => DioClient.dio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPaymentSettings(showError: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingStripeReturn) {
      _awaitingStripeReturn = false;

      Future<void>.delayed(const Duration(milliseconds: 700), () async {
        if (!mounted) return;

        await _loadPaymentSettings(showError: false, refreshStripe: true);
      });
    }
  }

  Map<String, dynamic> _responseData(Response response) {
    final body = response.data;

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return map;
    }

    return <String, dynamic>{};
  }

  Future<void> _loadPaymentSettings({
    required bool showError,
    bool refreshStripe = false,
  }) async {
    try {
      if (mounted) {
        setState(() {
          if (refreshStripe) {
            _refreshingStripe = true;
          } else {
            _loading = true;
          }

          _inlineError = null;
        });
      }

      final response = await _dio.get('/users/me/payment-method');

      final data = _responseData(response);

      if (!mounted) return;

      setState(() {
        _settings = PayoutSettings.fromJson(data);
        _loading = false;
        _refreshingStripe = false;
      });

      if (_settings.stripeReady) {
        await ref.read(authProvider.notifier).fetchMe();
      }
    } catch (error) {
      if (!mounted) return;

      final message = _extractError(error, 'Unable to load payout settings.');

      setState(() {
        _loading = false;
        _refreshingStripe = false;
        _inlineError = message;
      });

      if (showError) {
        _showSnack(message, isError: true);
      }
    }
  }

  Future<void> _connectStripe() async {
    try {
      setState(() {
        _saving = true;
        _inlineError = null;
      });

      final response = await _dio.post(
        '/users/me/payment-method/stripe/connect',
      );

      final data = _responseData(response);
      final onboardingUrl = data['onboardingUrl']?.toString();

      if (onboardingUrl == null || onboardingUrl.trim().isEmpty) {
        throw const _PayoutUiException(
          'TrabajoHub could not start secure Stripe onboarding. Please try again.',
        );
      }

      final uri = Uri.tryParse(onboardingUrl);

      if (uri == null || !uri.hasScheme || !uri.host.contains('stripe.com')) {
        throw const _PayoutUiException(
          'The Stripe onboarding link returned by the server is invalid.',
        );
      }

      _awaitingStripeReturn = true;

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _awaitingStripeReturn = false;

        throw const _PayoutUiException(
          'Could not open Stripe. Please try again.',
        );
      }

      if (!mounted) return;

      _showSnack(
        _settings.stripeConnected
            ? 'Stripe setup opened. Return to TrabajoHub when finished.'
            : 'Secure Stripe onboarding opened.',
      );
    } catch (error) {
      _awaitingStripeReturn = false;

      final message = _friendlyStripeError(error);

      if (!mounted) return;

      setState(() {
        _inlineError = message;
      });

      _showSnack(message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _refreshStripeStatus() async {
    await _loadPaymentSettings(showError: true, refreshStripe: true);

    if (!mounted) return;

    if (_settings.stripeReady) {
      _showSnack('Stripe payouts are ready.');
    } else if (_settings.stripeConnected) {
      _showSnack(
        'Stripe status refreshed. More information may still be required.',
      );
    }
  }

  String _friendlyStripeError(Object error) {
    final raw = _extractError(error, 'Unable to start Stripe payout setup.');

    final normalized = raw.toLowerCase();

    if (normalized.contains('signed up for connect') ||
        normalized.contains('you can only create new accounts') ||
        (normalized.contains('stripe connect') &&
            normalized.contains('account'))) {
      return 'Stripe payout setup is temporarily unavailable because TrabajoHub Connect is not fully activated. Please try again later or contact support.';
    }

    if (normalized.contains('account link') ||
        normalized.contains('onboarding')) {
      return 'Stripe could not start secure onboarding. Please try again in a moment.';
    }

    return raw;
  }

  String _extractError(Object error, String fallback) {
    if (error is _PayoutUiException) {
      return error.message;
    }

    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final candidates = [data['message'], data['error'], data['detail']];

        for (final candidate in candidates) {
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            return candidate.toString().trim();
          }
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The request timed out. Check your connection and try again.';

        case DioExceptionType.connectionError:
          return 'Unable to reach TrabajoHub. Check your internet connection and try again.';

        default:
          break;
      }
    }

    return fallback;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF027A48),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: _loading
          ? const _PayoutLoadingState()
          : Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),

                  if (_inlineError != null) ...[
                    _InlineError(
                      message: _inlineError!,
                      onRetry: () {
                        _loadPaymentSettings(showError: true);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  _buildStripeSection(),

                  const SizedBox(height: 15),

                  const _SecurityNotice(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payout account',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Connect Stripe securely to receive verified TrabajoHub earnings.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStripeSection() {
    final ready = _settings.stripeReady;
    final connected = _settings.stripeConnected;
    final needsAction = _settings.stripeNeedsAction;

    late final Color statusColor;
    late final Color statusBackground;
    late final IconData statusIcon;
    late final String statusTitle;
    late final String statusDescription;
    late final String buttonText;

    if (ready) {
      statusColor = const Color(0xFF027A48);
      statusBackground = const Color(0xFFECFDF3);
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Stripe payouts ready';
      statusDescription =
          'Your Stripe account is connected, onboarding is complete, and payouts are enabled.';
      buttonText = 'Manage Stripe';
    } else if (needsAction) {
      statusColor = const Color(0xFFB54708);
      statusBackground = const Color(0xFFFFFAEB);
      statusIcon = Icons.pending_actions_outlined;
      statusTitle = 'Stripe setup needs attention';
      statusDescription = _settings.stripeOnboardingComplete
          ? 'Stripe onboarding is complete, but payouts are not enabled yet. Refresh your status or continue setup if Stripe requests more information.'
          : 'Finish Stripe onboarding before you can receive payouts.';
      buttonText = 'Continue setup';
    } else {
      statusColor = const Color(0xFF635BFF);
      statusBackground = const Color(0xFFF4F3FF);
      statusIcon = Icons.account_balance_outlined;
      statusTitle = 'Get paid with Stripe';
      statusDescription =
          'Securely connect your payout account. Stripe handles identity verification and bank details.';
      buttonText = 'Connect Stripe';
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(statusIcon, color: statusColor, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stripe',
                      style: TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusDescription,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _StatusChip(label: 'Connected', complete: connected),
              _StatusChip(
                label: 'Onboarding',
                complete: _settings.stripeOnboardingComplete,
              ),
              _StatusChip(
                label: 'Payouts',
                complete: _settings.stripePayoutsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: _saving ? null : _connectStripe,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF635BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
              if (connected) ...[
                const SizedBox(width: 9),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _refreshingStripe ? null : _refreshStripeStatus,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _refreshingStripe
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 19),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool complete;

  const _StatusChip({required this.label, required this.complete});

  @override
  Widget build(BuildContext context) {
    final color = complete ? const Color(0xFF027A48) : const Color(0xFFB54708);

    final background = complete
        ? const Color(0xFFECFDF3)
        : const Color(0xFFFFFAEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF98A2B3), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bank account, identity, and payout details are entered directly with Stripe and are not manually collected by TrabajoHub.',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutLoadingState extends StatelessWidget {
  const _PayoutLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 190,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PayoutUiException implements Exception {
  final String message;

  const _PayoutUiException(this.message);

  @override
  String toString() => message;
}
