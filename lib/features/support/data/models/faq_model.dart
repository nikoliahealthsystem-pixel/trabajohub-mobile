class FaqCategory {
  final String category;
  final String icon;
  final List<FaqItem> items;

  FaqCategory({
    required this.category,
    required this.icon,
    required this.items,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    return FaqCategory(
      category: json['category'],
      icon: json['icon'],
      items: (json['items'] as List)
          .map((item) => FaqItem.fromJson(item))
          .toList(),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['q'],
      answer: json['a'],
    );
  }
}