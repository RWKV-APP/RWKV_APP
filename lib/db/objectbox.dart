import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zone/objectbox.g.dart' show openStore;

@Entity()
class Embedding {
  @Id()
  int id = 0;

  int documentId = 0;

  String content = '';

  int worlds = 0;

  int offset = 0;

  int length = 0;

  @HnswIndex(dimensions: 1024, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? segment;
}

@Entity()
class Document {
  @Id()
  int id = 0;

  String name = '';

  String path = '';

  String modelName = '';

  int lines = 0;

  int words = 0;

  int tokens = 0;

  int time = 0;

  int length = 0;

  int parsed = 0;

  int chunks = 0;

  List<String> tags = [];
}

class ObjectBox {
  late final Store store;

  static late ObjectBox instance;

  ObjectBox._create(this.store);

  static Future<ObjectBox> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: "${docsDir.path}\\embeddings.obx");
    instance = ObjectBox._create(store);
    return instance;
  }
}
