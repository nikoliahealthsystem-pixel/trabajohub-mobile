import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/payout_model.dart';

class PayoutDetailsModal extends StatelessWidget {
  final PayoutModel payout;

  const PayoutDetailsModal({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    final fullDateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payout Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount & Status
          Center(
            child: Column(
              children: [
                Text(
                  '\$${payout.netPayout.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusBackground(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payout.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details
          _buildRow('Payout ID', payout.id),
          _buildRow('Gross Charge', '\$${payout.grossCharge.toStringAsFixed(2)}'),
          _buildRow('System Fee', '\$${payout.systemCommission.toStringAsFixed(2)}'),
          _buildRow('Net Amount', '\$${payout.netPayout.toStringAsFixed(2)}'),

          if (payout.stripeTransferId != null)
            _buildRow('Stripe Transfer', payout.stripeTransferId!),

          _buildRow('Created At', fullDateFormat.format(payout.createdAt)),

          if (payout.paidAt != null)
            _buildRow('Paid At', fullDateFormat.format(payout.paidAt!)),

          if (payout.shiftId != null)
            _buildRow('Shift ID', payout.shiftId!),

          if (payout.notes != null && payout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              payout.notes!,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Color(0xFF536C79),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBackground() {
    switch (payout.status) {
      case PayoutStatus.settled:
        return const Color(0xFFDCFCE7);
      case PayoutStatus.failed:
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _getStatusColor() {
    switch (payout.status) {
      case PayoutStatus.settled:
        return const Color(0xFF15803D);
      case PayoutStatus.failed:
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFB45309);
    }
  }
}