import 'package:equatable/equatable.dart';

class BrowserWindow extends Equatable {
  final int id;
  final int left;
  final int top;
  final int width;
  final int height;
  final String state;
  final String type;
  final bool focused;

  const BrowserWindow({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.state,
    required this.type,
    required this.focused,
  });

  @override
  List<Object?> get props => [id, left, top, width, height, state, type, focused];
}
