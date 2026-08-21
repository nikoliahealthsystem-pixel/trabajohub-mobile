import 'package:flutter/foundation.dart';

enum QuestionType { TRUE_FALSE, MULTIPLE_CHOICE, TEXT }

class SurveyQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final int order;

  const SurveyQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    required this.order,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    QuestionType parseType(String t) {
      switch (t.toUpperCase()) {
        case 'TRUE_FALSE':
          return QuestionType.TRUE_FALSE;
        case 'MULTIPLE_CHOICE':
          return QuestionType.MULTIPLE_CHOICE;
        case 'TEXT':
          return QuestionType.TEXT;
        default:
          return QuestionType.TEXT;
      }
    }

    return SurveyQuestion(
      id: json['id'],
      question: json['question'],
      type: parseType(json['type']),
      options: List<String>.from(json['options'] ?? []),
      order: json['order'] ?? 0,
    );
  }
}

class SurveyResponseAnswer {
  final String questionId;
  final String answer;

  const SurveyResponseAnswer({required this.questionId, required this.answer});

  factory SurveyResponseAnswer.fromJson(Map<String, dynamic> json) =>
      SurveyResponseAnswer(
        questionId: json['questionId'],
        answer: json['answer'],
      );
}

class SurveyModel {
  final String id;
  final String shiftId;
  final String title;
  final String? description;
  final bool isActive;
  final List<SurveyQuestion> questions;

  const SurveyModel({
    required this.id,
    required this.shiftId,
    required this.title,
    this.description,
    required this.isActive,
    required this.questions,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) => SurveyModel(
    id: json['id'],
    shiftId: json['shiftId'],
    title: json['title'] ?? 'Shift Survey',
    description: json['description'],
    isActive: json['isActive'] ?? true,
    questions: (json['questions'] as List<dynamic>? ?? [])
        .map((q) => SurveyQuestion.fromJson(q))
        .toList(),
  );
}