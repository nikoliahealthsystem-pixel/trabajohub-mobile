import 'package:flutter/material.dart';

class InputDropDown extends StatefulWidget {
  final List<String> options;
  final void Function(String) onOptionSelected;
  final String inputTitle;
  final FormFieldValidator<String>? validator;

  const InputDropDown({
    super.key,
    required this.options,
    required this.onOptionSelected,
    required this.inputTitle,
    this.validator,
  });

  @override
  State<InputDropDown> createState() => _InputDropDownState();
}

class _InputDropDownState extends State<InputDropDown> {
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.options.isNotEmpty ? widget.options[0] : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormField<String>(
        validator: widget.validator,
        builder: (FormFieldState<String> field) {
          return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: field.hasError ? Colors.red : const Color(0xFFE1E7EA),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.inputTitle,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  DropdownButton<String>(
                    isDense: true,
                    value: selectedOption,
                    items: widget.options.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOption = newValue!;
                      });
                      widget.onOptionSelected(newValue!); // Notify parent
                    },
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: const SizedBox(),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        field.errorText ?? '',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              ));
        },
      ),
    );
  }
}
