import 'package:equatable/equatable.dart';

class LogItem extends Equatable {
  final String tag;
  final String content;
  final bool isPrefill;

  @override
  List<Object?> get props => [
    tag,
    content,
    isPrefill,
  ];

  const LogItem({
    required this.tag,
    required this.content,
    required this.isPrefill,
  });
}
