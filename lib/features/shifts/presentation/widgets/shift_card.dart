import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/shift_model.dart';
import 'package:intl/intl.dart';

class ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final bool noMargin;
  final bool isBooking;
  final VoidCallback onBook;
  final VoidCallback onTap;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.isBooking,
    this.noMargin=false,
    required this.onBook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal:noMargin ?0: 16, vertical:noMargin ?0: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift.displayTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2632),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF94A3B4)),
                                const SizedBox(width: 2),
                                Text(
                                  shift.locationDisplay,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${shift.payRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      _Chip(shift.requiredDesignation, Colors.cyan.shade50, const Color(0xFF0A7D95)),
                      if (shift.isUrgent) _Chip('Urgent', Colors.orange.shade50, Colors.orange.shade800),
                      _Chip(
                        shift.visitType.replaceAll('_', ' '),
                        Colors.indigo.shade50,
                        Colors.indigo.shade700,
                      ),
                      _Chip(shift.period, Colors.grey.shade100, const Color(0xFF536C79)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B4)),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(shift.scheduledStart)}  ·  '
                            '${timeFormat.format(shift.scheduledStart)} – ${timeFormat.format(shift.scheduledEnd)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF536C79)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFEEF1F4))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Est. \$${shift.estimatedEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF536C79), fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: isBooking ? null : onBook,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: isBooking
                              ? null
                              : ColorConstants.appGradient,
                          borderRadius: BorderRadius.circular(10),
                          color: isBooking ? const Color(0xFFE2E8ED) : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: isBooking
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                            'Book now',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );
}