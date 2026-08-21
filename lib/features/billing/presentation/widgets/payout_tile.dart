import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/payout_model.dart';
import 'payout_details_modal.dart';

class PayoutTile extends StatelessWidget {
  final PayoutModel payout;

  const PayoutTile({
    super.key,
    required this.payout,
  });

  static const _statusConfig = {
    PayoutStatus.settled: (
    Color(0xFFDCFCE7),
    Color(0xFF15803D),
    Icons.check_circle_outline_rounded,
    ),
    PayoutStatus.pending: (
    Color(0xFFFEF3C7),
    Color(0xFFB45309),
    Icons.hourglass_bottom_rounded,
    ),
    PayoutStatus.failed: (
    Color(0xFFFCEBEB),
    Color(0xFFB91C1C),
    Icons.error_outline_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[payout.status] ??
        _statusConfig[PayoutStatus.pending]!;
    final bg = config.$1;
    final fg = config.$2;
    final icon = config.$3;

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return InkWell(
      onTap: () => _showPayoutDetailsModal(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${payout.netPayout.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2632),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            payout.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gross: \$${payout.grossCharge.toStringAsFixed(2)}  ·  '
                          'Fee: \$${payout.systemCommission.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B4)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: Color(0xFF94A3B4)),
                        const SizedBox(width: 4),
                        Text(
                          payout.paidAt != null
                              ? '${dateFormat.format(payout.paidAt!)} · ${timeFormat.format(payout.paidAt!)}'
                              : dateFormat.format(payout.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B4)),
                        ),
                        if (payout.stripeTransferId != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_outlined,
                              size: 11, color: Color(0xFF28D744)),
                          const SizedBox(width: 2),
                          const Text('Stripe',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF28D744))),
                        ],
                      ],
                    ),
                    if (payout.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        payout.notes!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF536C79),
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayoutDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: PayoutDetailsModal(payout: payout),
      ),
    );
  }
}