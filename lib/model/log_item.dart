// Package imports:
import 'package:equatable/equatable.dart';

class LogItem extends Equatable {
  final String tag;
  final String content;
  final bool isPrefill;
  final String dateTimeString;

  @override
  List<Object?> get props => [
    tag,
    content,
    isPrefill,
    dateTimeString,
  ];

  const LogItem({
    required this.tag,
    required this.content,
    required this.isPrefill,
    required this.dateTimeString,
  });
}
