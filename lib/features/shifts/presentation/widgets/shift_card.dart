import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/shift_model.dart';

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
    this.noMargin = false,
    required this.onBook,
    required this.onTap,
  });

  String get _rateSuffix {
    switch (shift.billingType.toUpperCase()) {
      case 'VISIT':
        return '/visit';
      case 'FIXED':
        return '';
      default:
        return '/hr';
    }
  }

  String get _duration {
    final minutes = shift.scheduledEnd
        .difference(shift.scheduledStart)
        .inMinutes;

    if (minutes <= 0) return '?';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '${mins}m';
    }

    if (mins == 0) {
      return '${hours}h';
    }

    return '${hours}h ${mins}m';
  }

  String get _pattern {
    return _formatLabel(shift.pattern);
  }

  String get _visitType {
    return _formatLabel(shift.visitType);
  }

  static String _formatLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    final start = shift.scheduledStart.toLocal();
    final end = shift.scheduledEnd.toLocal();

    final attentionColor = shift.isEmergencyFill
        ? const Color(0xFFB42318)
        : shift.isUrgent
        ? const Color(0xFFB54708)
        : accentColor;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: noMargin ? 0 : 16,
        vertical: noMargin ? 0 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: shift.isEmergencyFill
              ? const Color(0xFFFECACA)
              : shift.isUrgent
              ? const Color(0xFFFED7AA)
              : const Color(0xFFE4E7EC),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09101828),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shift.isEmergencyFill || shift.isUrgent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: attentionColor.withValues(alpha: .07),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        shift.isEmergencyFill
                            ? Icons.emergency_rounded
                            : Icons.bolt_rounded,
                        size: 15,
                        color: attentionColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        shift.isEmergencyFill
                            ? 'EMERGENCY FILL'
                            : 'URGENT SHIFT',
                        style: TextStyle(
                          color: attentionColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .45,
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
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
                              Row(
                                children: [
                                  _Tag(
                                    label: shift.requiredDesignation,
                                    background: const Color(0xFFEAF8FC),
                                    foreground: const Color(0xFF0A7D95),
                                  ),
                                  const SizedBox(width: 6),
                                  _Tag(
                                    label: _visitType,
                                    background: const Color(0xFFF2F4F7),
                                    foreground: const Color(0xFF475467),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 9),

                              Text(
                                shift.displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                  fontSize: 15.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.15,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: Color(0xFF98A2B3),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shift.locationDisplay,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF667085),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${shift.payRate.toStringAsFixed(shift.payRate % 1 == 0 ? 0 : 2)}$_rateSuffix',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'NURSE PAY',
                              style: TextStyle(
                                color: Color(0xFF98A2B3),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.calendar_today_outlined,
                              label: 'DATE',
                              value: dateFormat.format(start),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: const Color(0xFFE4E7EC),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.schedule_outlined,
                              label: 'TIME',
                              value:
                                  '${timeFormat.format(start)} ? ${timeFormat.format(end)}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: const Color(0xFFE4E7EC),
                          ),
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.timelapse_rounded,
                              label: 'DURATION',
                              value: _duration,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (shift.specialties.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: shift.specialties
                            .take(3)
                            .map(
                              (specialty) => _Tag(
                                label: _formatLabel(specialty),
                                background: const Color(0xFFF4F3FF),
                                foreground: const Color(0xFF6941C6),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        _MiniFeature(
                          icon: Icons.repeat_rounded,
                          label: _pattern,
                        ),

                        if (shift.allowInstantBook) ...[
                          const SizedBox(width: 12),
                          const _MiniFeature(
                            icon: Icons.flash_on_rounded,
                            label: 'Instant book',
                            emphasized: true,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        if (shift.billingType.toUpperCase() == 'HOURLY')
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EST. EARNINGS',
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .35,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${shift.estimatedEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF027A48),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (shift.billingType.toUpperCase() == 'HOURLY')
                          const SizedBox(width: 10),

                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475467),
                                    side: const BorderSide(
                                      color: Color(0xFFD0D5DD),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isBooking ? null : onBook,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: accentColor
                                        .withValues(alpha: .55),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isBooking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          shift.allowInstantBook
                                              ? 'Book now'
                                              : 'Book shift',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF98A2B3)),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _MiniFeature({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: emphasized ? const Color(0xFFB54708) : const Color(0xFF98A2B3),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: emphasized
                ? const Color(0xFFB54708)
                : const Color(0xFF667085),
            fontSize: 9.5,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
