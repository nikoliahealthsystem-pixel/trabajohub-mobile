import 'package:flutter/material.dart';
import '../../data/models/calendar_event_model.dart';

// Matches the web component's badge colours
const _typeColors = {
  CalendarEventType.shift: (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
  CalendarEventType.recurringShift: (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
  CalendarEventType.visit: (Color(0xFFDCFCE7), Color(0xFF15803D)),
  CalendarEventType.credentialExpiry: (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
  CalendarEventType.invoiceDue: (Color(0xFFFEF3C7), Color(0xFFB45309)),
  CalendarEventType.invoiceOverdue: (Color(0xFFFFE4E6), Color(0xFFBE123C)),
};

class EventTypeFilterBar extends StatelessWidget {
  final Set<CalendarEventType> activeTypes;
  final ValueChanged<CalendarEventType> onToggle;
  final VoidCallback onReset;

  const EventTypeFilterBar({
    super.key,
    required this.activeTypes,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...CalendarEventType.values.map((type) {
                  final isActive = activeTypes.contains(type);
                  final colors = _typeColors[type]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onToggle(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? colors.$1 : const Color(0xFFF0F4F7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? colors.$2.withOpacity(0.3) : const Color(0xFFE2E8ED),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 5),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? colors.$2 : const Color(0xFF94A3B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B4), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}