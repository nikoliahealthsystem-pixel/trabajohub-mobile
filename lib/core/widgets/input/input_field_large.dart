import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';


class InputFieldLarge extends StatelessWidget {
  final String inputHintText;
  final String inputTitle;
  final TextEditingController textController;
  final FormFieldValidator<String>? validator;

  const InputFieldLarge({
    super.key,
    required this.inputHintText,
    required this.inputTitle,
    required this.textController,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              TextFormField(
                cursorColor: accentColor,
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                controller: textController,
                validator: validator,
                decoration: InputDecoration(
                  hintText: inputHintText,
                  hintStyle: const TextStyle(
                      color: Colors.grey), // Style for hint text
                  border: InputBorder.none, // Removes the border line
                ),
              )
            ],
          )),
    );
  }
}
