// Package imports:
import 'package:equatable/equatable.dart';

class StateLog extends Equatable {
  final String text;
  final int lifeSpan;

  @override
  List<Object?> get props => [
    text,
    lifeSpan,
  ];

  const StateLog({
    required this.text,
    required this.lifeSpan,
  });
}
