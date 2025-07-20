import 'package:equatable/equatable.dart';

class BrowserTab extends Equatable {
  final int id;
  final String url;
  final String title;

  BrowserTab({required this.id, required this.url, required this.title});

  @override
  List<Object?> get props => [id, url, title];
}
