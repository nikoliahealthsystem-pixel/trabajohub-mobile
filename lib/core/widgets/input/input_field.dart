import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class Inputfield extends StatelessWidget {
  final String inputHintText;
  final String inputTitle;
  final bool textObscure;
  final bool isreadOnly;
  final Widget? icon;
  final TextEditingController textController;
  final FormFieldValidator<String>? validator;

  const Inputfield({
    super.key,
    required this.inputHintText,
    required this.inputTitle,
    required this.textObscure,
    required this.textController,
    this.icon,
    required this.isreadOnly,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE1E7EA),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inputTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            TextFormField(
              cursorColor: accentColor,
              readOnly: isreadOnly,
              obscureText: textObscure,
              controller: textController,
              validator: validator,
              decoration: InputDecoration(
                suffixIcon: icon,
                hintText: inputHintText,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none, // Removes the border line
              ),
            ),
          ],
        ),
      ),
    );
  }
}
