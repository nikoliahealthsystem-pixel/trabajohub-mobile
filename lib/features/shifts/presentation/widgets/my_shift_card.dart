import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../visits/data/models/visit_model.dart';
import '../../../visits/presentation/visit_detail_screen.dart';
import '../../data/models/shift_assignment_model.dart' hide VisitModel;

class MyShiftCard extends StatelessWidget {
  final ShiftAssignmentModel assignment;
  final bool isCancelling;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const MyShiftCard({
    super.key,
    required this.assignment,
    required this.isCancelling,
    required this.onTap,
    this.onCancel,
  });

  static const _statusColors = {
    'ACCEPTED': (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    'COMPLETED': (Color(0xFFEAF3DE), Color(0xFF3B6D11)),
    'CANCELLED': (Color(0xFFFCEBEB), Color(0xFFA32D2D)),
    'PENDING': (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  };

  static final _statusBarColors = {
    'ACCEPTED': accentColor,
    'COMPLETED': const Color(0xFF28D744),
    'CANCELLED': const Color(0xFFE24B4A),
    'PENDING': const Color(0xFFEF9F27),
  };

  @override
  Widget build(BuildContext context) {
    final shift = assignment.shift;
    if (shift == null) return const SizedBox.shrink();

    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');
    final colors = _statusColors[assignment.status] ?? _statusColors['ACCEPTED']!;
    final barColor = _statusBarColors[assignment.status] ?? _statusBarColors['ACCEPTED']!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                            if (shift.shiftCase != null)
                              Text(
                                shift.shiftCase!.publicIdentifier,
                                style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B4), letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              shift.displayTitle,
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2632),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.$1,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          assignment.status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.$2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MetaItem(
                        icon: Icons.access_time_rounded,
                        label: '${dateFormat.format(shift.scheduledStart)}  ·  '
                            '${timeFormat.format(shift.scheduledStart)}–${timeFormat.format(shift.scheduledEnd)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MetaItem(icon: Icons.location_on_outlined, label: shift.locationDisplay),
                      const Spacer(),
                      Text(
                        '\$${shift.payRate.toStringAsFixed(0)}/hr',
                        style:  TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  if (assignment.status == 'ACCEPTED' && onCancel != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: isCancelling ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE24B4A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isCancelling
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Cancel shift', style: TextStyle(fontSize: 12, color: Color(0xFFE24B4A))),
                      ),
                    ),
                  ],

                  if (assignment.visit != null) ...[
                    const SizedBox(height: 10),
                    _buildVisitButton(context, assignment.visit!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildVisitButton(BuildContext context, VisitModel visit) {
    final canCheckIn = visit.status == VisitStatus.scheduled;
    final canCheckOut = visit.status == VisitStatus.checkedIn;
    final isActive = canCheckIn || canCheckOut;

    if (!isActive) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canCheckOut
                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                : [const Color(0xFF0A9FBF), const Color(0xFF28D744)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisitDetailFromState(visit: visit),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(
            canCheckOut ? Icons.logout_rounded : Icons.login_rounded,
            color: Colors.white,
            size: 16,
          ),
          label: Text(
            canCheckOut ? 'Check Out' : 'Check In',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: const Color(0xFF94A3B4)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF536C79))),
    ],
  );
}