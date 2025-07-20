import 'package:equatable/equatable.dart';

class BrowserTab extends Equatable {
  final int id;
  final String url;
  final String title;
  final int windowId;
  final double lastAccessed;

  const BrowserTab({
    required this.id,
    required this.url,
    required this.title,
    required this.windowId,
    required this.lastAccessed,
  });

  @override
  List<Object?> get props => [id, url, windowId];
}
