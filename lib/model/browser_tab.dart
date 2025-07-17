import 'package:equatable/equatable.dart';

class BrowserTab extends Equatable {
  final int id;
  final String url;
  final String title;
  final String favIconUrl;

  BrowserTab({required this.id, required this.url, required this.title, required this.favIconUrl});

  @override
  List<Object?> get props => [id, url, title, favIconUrl];
}
