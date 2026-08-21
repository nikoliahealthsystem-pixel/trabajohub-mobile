import 'package:flutter/material.dart';

enum EvvAction { checkIn, checkOut }

class EvvActionButton extends StatelessWidget {
  final EvvAction action;
  final bool isLoading;
  final VoidCallback onPressed;

  const EvvActionButton({
    super.key,
    required this.action,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckIn = action == EvvAction.checkIn;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : LinearGradient(
            colors: isCheckIn
                ? [const Color(0xFF0A9FBF), const Color(0xFF28D744)]
                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: isLoading ? const Color(0xFFE2E8ED) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: isLoading
              ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white))
              : Icon(
            isCheckIn
                ? Icons.login_rounded
                : Icons.logout_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            isLoading
                ? (isCheckIn ? 'Getting location…' : 'Checking out…')
                : (isCheckIn ? 'Check In' : 'Check Out'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}