import 'package:flutter/material.dart';
import '../../data/models/survey_model.dart';

class SurveyQuestionWidget extends StatelessWidget {
  final SurveyQuestion question;
  final String? currentAnswer;
  final ValueChanged<String> onAnswerChanged;

  const SurveyQuestionWidget({
    super.key,
    required this.question,
    this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.order + 1}. ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildAnswerInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(BuildContext context) {
    switch (question.type) {
      case QuestionType.TRUE_FALSE:
        return _buildTrueFalse();

      case QuestionType.MULTIPLE_CHOICE:
        return _buildMultipleChoice();

      case QuestionType.TEXT:
        return _buildTextField();
    }
  }

  Widget _buildTrueFalse() {
    return Column(
      children: [
        _buildOptionTile('true', 'Yes / True'),
        const SizedBox(height: 8),
        _buildOptionTile('false', 'No / False'),
      ],
    );
  }

  Widget _buildMultipleChoice() {
    return Column(
      children: question.options.map((option) {
        return _buildOptionTile(option, option);
      }).toList(),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      initialValue: currentAnswer,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Type your answer here...',
      ),
      maxLines: 3,
      onChanged: onAnswerChanged,
    );
  }

  Widget _buildOptionTile(String value, String label) {
    final isSelected = currentAnswer == value;

    return InkWell(
      onTap: () => onAnswerChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}