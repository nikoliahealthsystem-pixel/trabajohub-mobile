import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/calendar_event_model.dart';

// Used by table_calendar's eventLoader to render coloured dots on days
class CalendarEventDot extends StatelessWidget {
  final CalendarEventModel event;

  const CalendarEventDot({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(event.colorHex);
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  static Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return accentColor;
  }
}

Color hexToColor(String hex) => CalendarEventDot._hexToColor(hex);