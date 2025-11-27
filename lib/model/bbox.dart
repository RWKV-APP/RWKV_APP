import 'package:equatable/equatable.dart';

final class BBox extends Equatable {
  final int x;
  final int y;
  final int width;
  final int height;
  final String text;
  final double r;
  final double p;

  const BBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.text,
    required this.r,
    required this.p,
  });

  @override
  List<Object?> get props => [x, y, width, height, text, r, p];
}
