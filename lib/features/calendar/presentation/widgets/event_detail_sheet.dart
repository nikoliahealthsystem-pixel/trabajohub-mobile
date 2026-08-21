import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/calendar_event_model.dart';
import 'calendar_event_dot.dart';

class EventDetailSheet extends StatelessWidget {
  final CalendarEventModel event;
  final VoidCallback onClose;

  const EventDetailSheet({super.key, required this.event, required this.onClose});

  static void show(BuildContext context, CalendarEventModel event, VoidCallback onClose) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) =>  Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 24),
          child: EventDetailSheet(event: event, onClose: onClose)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(event.colorHex);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, scrollController) => Container(
        decoration:  BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(event.type.emoji, style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.type.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2632),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRange(event.start, event.end, event.allDay),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Status pill
                  if (event.status.isNotEmpty)
                    _StatusPill(status: event.status),
                  const SizedBox(height: 16),
                  // Detail rows
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildDetailRows(event),
                  ),
                  const SizedBox(height: 20),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onClose();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8ED)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 15, color: Color(0xFF536C79), fontWeight: FontWeight.w600),
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

  Widget _buildDetailRows(CalendarEventModel event) {
    final meta = event.meta;
    final rows = <_DetailRow>[];

    switch (event.type) {
      case CalendarEventType.shift:
      case CalendarEventType.recurringShift:
        if (meta.caseIdentifier != null) rows.add(_DetailRow('Case', meta.caseIdentifier!));
        if (meta.location != null) rows.add(_DetailRow('Location', meta.location!));
        if (meta.visitType != null) rows.add(_DetailRow('Visit Type', _formatLabel(meta.visitType)));
        if (meta.designation != null) rows.add(_DetailRow('Designation', meta.designation!));
        if (meta.specialties.isNotEmpty) rows.add(_DetailRow('Specialties', meta.specialties.join(', ')));
        rows.add(_DetailRow('Status', _formatLabel(event.status)));
        if (meta.assignee != null) rows.add(_DetailRow('Assigned To', meta.assignee!));
        if (meta.payRate != null) rows.add(_DetailRow('Pay Rate', '\$${meta.payRate!.toStringAsFixed(2)}/hr'));
        if (meta.chargeRate != null) rows.add(_DetailRow('Charge Rate', '\$${meta.chargeRate!.toStringAsFixed(2)}/hr'));
        if (meta.pattern != null) rows.add(_DetailRow('Pattern', meta.pattern!));
        if (meta.period != null) rows.add(_DetailRow('Period', meta.period!));
        if (meta.isUrgent) rows.add(const _DetailRow('Urgent', 'Yes'));
        if (meta.isEmergencyFill) rows.add(const _DetailRow('Emergency Fill', 'Yes'));
        break;

      case CalendarEventType.visit:
        if (meta.caseIdentifier != null) rows.add(_DetailRow('Case', meta.caseIdentifier!));
        if (meta.location != null) rows.add(_DetailRow('Location', meta.location!));
        if (meta.visitType != null) rows.add(_DetailRow('Visit Type', _formatLabel(meta.visitType)));
        if (meta.nurse != null) rows.add(_DetailRow('Nurse', meta.nurse!));
        rows.add(_DetailRow('Status', _formatLabel(event.status)));
        if (meta.checkInTime != null) rows.add(_DetailRow('Check In', _formatDateTime(meta.checkInTime)));
        if (meta.checkOutTime != null) rows.add(_DetailRow('Check Out', _formatDateTime(meta.checkOutTime)));
        if (meta.durationMinutes != null) rows.add(_DetailRow('Duration', '${meta.durationMinutes} min'));
        if (meta.checkInDistance != null) rows.add(_DetailRow('Distance at CI', '${meta.checkInDistance!.toStringAsFixed(0)} m'));
        if (meta.overrideRequired) rows.add(_DetailRow('Override', meta.overrideReason ?? 'Required'));
        if (meta.notes != null) rows.add(_DetailRow('Notes', meta.notes!));
        break;

      case CalendarEventType.credentialExpiry:
        if (meta.nurse != null) rows.add(_DetailRow('Nurse', meta.nurse!));
        rows.add(_DetailRow('Credential', meta.customLabel ?? _formatLabel(meta.credentialType)));
        if (meta.expiresAt != null) rows.add(_DetailRow('Expires', _formatDateTime(meta.expiresAt)));
        if (meta.daysUntilExpiry != null)
          rows.add(_DetailRow('Days Remaining',
              meta.daysUntilExpiry! <= 0 ? 'Expired' : '${meta.daysUntilExpiry} days'));
        rows.add(_DetailRow('Status', _formatLabel(event.status)));
        break;

      case CalendarEventType.invoiceDue:
      case CalendarEventType.invoiceOverdue:
        if (meta.facilityName != null) rows.add(_DetailRow('Facility', meta.facilityName!));
        if (meta.invoiceNumber != null) rows.add(_DetailRow('Invoice #', meta.invoiceNumber!));
        if (meta.total != null) rows.add(_DetailRow('Total', '\$${meta.total!.toStringAsFixed(2)}'));
        if (meta.dueAt != null) rows.add(_DetailRow('Due Date', _formatDateTime(meta.dueAt)));
        rows.add(_DetailRow('Status', _formatLabel(event.status)));
        break;
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final isLast = entry.key == rows.length - 1;
        return entry.value._build(isLast: isLast);
      }).toList(),
    );
  }

  String _formatLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    return raw.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatRange(DateTime start, DateTime? end, bool allDay) {
    final df = DateFormat('EEE, MMM d, yyyy');
    final tf = DateFormat('h:mm a');
    if (allDay) return df.format(start);
    if (end == null) return '${df.format(start)} · ${tf.format(start)}';
    return '${df.format(start)}  ${tf.format(start)} – ${tf.format(end)}';
  }
}

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  Widget _build({bool isLast = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE8EDF2))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B4),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2632),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  static const _colors = {
    'OPEN': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'BOOKED': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'COMPLETED': (Color(0xFFEAF3DE), Color(0xFF3B6D11)),
    'CANCELLED': (Color(0xFFFCEBEB), Color(0xFFB91C1C)),
    'IN_PROGRESS': (Color(0xFFFEF3C7), Color(0xFFB45309)),
    'VERIFIED': (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    'FLAGGED': (Color(0xFFFCEBEB), Color(0xFFB91C1C)),
    'PENDING': (Color(0xFFFAEEDA), Color(0xFF854F0B)),
    'APPROVED': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'EXPIRED': (Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[status.toUpperCase()] ?? _colors['PENDING']!;
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.$2)),
    );
  }
}