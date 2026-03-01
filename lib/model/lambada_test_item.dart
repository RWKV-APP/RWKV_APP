// Package imports:
import 'package:equatable/equatable.dart';

class LambadaTestItem extends Equatable {
  final String text;
  final String sourceText;
  final String targetText;

  const LambadaTestItem({
    required this.text,
    required this.sourceText,
    required this.targetText,
  });

  factory LambadaTestItem.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String;
    final lastSpaceIndex = text.lastIndexOf(' ');
    final sourceText = lastSpaceIndex != -1 ? text.substring(0, lastSpaceIndex) : text;
    final targetText = lastSpaceIndex != -1 ? ' ${text.substring(lastSpaceIndex + 1)}' : '';

    return LambadaTestItem(
      text: text,
      sourceText: sourceText,
      targetText: targetText,
    );
  }

  @override
  List<Object?> get props => [
    text,
    sourceText,
    targetText,
  ];
}
