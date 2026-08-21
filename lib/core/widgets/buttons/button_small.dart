import 'package:flutter/material.dart';

class ButtonSmall extends StatelessWidget {
  final String buttonText;
  final bool isdark;

  const ButtonSmall({super.key, required this.buttonText, this.isdark = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isdark ? const Color(0xFFFF8800) : Colors.white,
        border: Border.all(
          color: isdark
              ? const Color(0xFFFF8800)
              : const Color.fromARGB(224, 38, 50, 56),
          width: 1,
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          buttonText,
          style: TextStyle(
            color: isdark ? Colors.white : const Color(0xFF263238),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
