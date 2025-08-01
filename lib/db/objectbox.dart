import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zone/objectbox.g.dart' show openStore;

@Entity()
class DocumentChunk {
  @Id()
  int id = 0;

  int documentId = 0;

  String content = '';

  int length = 0;

  int offset = 0;

  List<String> tags = [];

  @HnswIndex(
    dimensions: 1024,
    distanceType: VectorDistanceType.cosine,
    neighborsPerNode: 64,
    flags: null,
    indexingSearchCount: 200, // reduce value to speed up indexing
  )
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  static DocumentChunk fromMap(Map<String, dynamic> map) {
    return DocumentChunk()
      ..id = map['id']
      ..documentId = map['documentId']
      ..content = map['content']
      ..length = map['length']
      ..offset = map['offset']
      ..tags = map['tags']
      ..embedding = map['embedding'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'length': length,
      'offset': offset,
      'tags': tags,
      'embedding': embedding,
    };
  }
}

@Entity()
class Document {
  @Id()
  int id = 0;

  String name = '';

  String path = '';

  String modelName = '';

  int lines = 0;

  int characters = 0;

  int tokens = 0;

  int time = 0;

  int length = 0;

  int parsed = 0;

  int chunks = 0;

  int timestamp = 0;

  List<String> tags = [];

  static Document fromMap(Map<String, dynamic> map) {
    return Document()
      ..id = map['id']
      ..name = map['name']
      ..path = map['path']
      ..modelName = map['model_name']
      ..lines = map['lines']
      ..characters = map['characters']
      ..tokens = map['tokens']
      ..time = map['time']
      ..length = map['length']
      ..parsed = map['parsed']
      ..chunks = map['chunks']
      ..timestamp = map['timestamp']
      ..tags = map['tags'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'model_name': modelName,
      'lines': lines,
      'characters': characters,
      'tokens': tokens,
      'time': time,
      'length': length,
      'parsed': parsed,
      'chunks': chunks,
      'timestamp': timestamp,
      'tags': tags,
    };
  }
}

class ObjectBox {
  late final Store store;

  static late ObjectBox instance;

  ObjectBox._create(this.store);

  static Future<ObjectBox> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: "${docsDir.path}${Platform.pathSeparator}embeddings.obx");
    instance = ObjectBox._create(store);
    return instance;
  }

  static Future cleanup() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = "${docsDir.path}${Platform.pathSeparator}embeddings.obx";
    if (await File(file).exists()) {
      await File(file).delete();
    }
  }
}
