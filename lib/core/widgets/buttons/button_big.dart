import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class Button extends StatelessWidget {
  final String buttonText;
  final Widget icon;
  final bool isdark;
  final bool isLogout;
  final bool isLoading;
  final VoidCallback? onPressed;


  const Button(
      {super.key,
      required this.buttonText,
      this.isdark = true,
      this.isLogout = false,
      this.isLoading = false,
      this.icon = const SizedBox.shrink(),
      this.onPressed,});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isLoading ? null : isLogout
            ? null
            : isdark
                ? accentColor
                : Colors.white,
        border: Border.all(
          color: isLogout ? Colors.red : accentColor,
          width: 1,
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: isLoading?
        SizedBox(width: 22, height: 22, child:
        CircularProgressIndicator(strokeWidth: 2.5, color: accentColor)
        ):
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: icon,
            ),
            Text(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              buttonText,
              style: TextStyle(
                color: isLogout
                    ? Colors.red
                    : isdark
                        ? Colors.white
                        : const Color(0xFF263238),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
