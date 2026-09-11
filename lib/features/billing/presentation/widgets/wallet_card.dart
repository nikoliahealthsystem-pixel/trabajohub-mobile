import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/wallet_model.dart';

class WalletCard extends StatefulWidget {
  final WalletModel wallet;
  final VoidCallback? onTap;

  const WalletCard({super.key, required this.wallet, this.onTap});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _showBalance = true;

  String _money(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _hidden() {
    return '••••••';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: ColorConstants.appGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY EARNINGS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'TrabajoHub Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: _showBalance ? 'Hide earnings' : 'Show earnings',
                      onPressed: () {
                        setState(() {
                          _showBalance = !_showBalance;
                        });
                      },
                      icon: Icon(
                        _showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Text(
                  'Lifetime earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _showBalance ? _money(wallet.lifetimeEarnings) : _hidden(),
                    key: ValueKey(_showBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Container(height: 1, color: Colors.white.withOpacity(.14)),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _WalletStat(
                        label: 'Available',
                        value: _showBalance
                            ? _money(wallet.availableBalance)
                            : _hidden(),
                        subtitle: 'Ready',
                        icon: Icons.account_balance_outlined,
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 52,
                      color: Colors.white.withOpacity(.16),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: _WalletStat(
                        label: 'Pending',
                        value: _showBalance
                            ? _money(wallet.pendingBalance)
                            : _hidden(),
                        subtitle: 'Processing',
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),

                if (widget.onTap != null) ...[
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(.12)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'View earnings & payouts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _WalletStat({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 17),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
