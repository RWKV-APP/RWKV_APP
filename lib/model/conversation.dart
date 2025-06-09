import 'package:equatable/equatable.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/message.dart';

final class Conversation extends Equatable {
  final int id;
  final String name;
  final List<Message> messages;
  final int createdAt;
  final int updatedAt;

  const Conversation({
    required this.id,
    required this.name,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final messages = HF.jsonArray(json['messages']).map((e) => Message.fromJson(e)).toList();
    return Conversation(
      id: json['id'],
      name: json['name'],
      messages: messages,
      createdAt: json['createdAt'] ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    updatedAt,
  ];
}
