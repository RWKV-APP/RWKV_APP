import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:collection/collection.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zone/db/objectbox.dart';
import 'package:zone/objectbox.g.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/rag_init_dialog.dart';
import 'package:zone/widgets/model_selector.dart';

import '../gen/l10n.dart' show S;

class ChunkQueryResult {
  final String text;
  final String documentName;
  final double score;
  final int dimension;
  final String model;
  final List<double> embedding;

  ChunkQueryResult({
    required this.text,
    required this.documentName,
    required this.score,
    required this.dimension,
    required this.model,
    required this.embedding,
  });
}

class RAG {
  bool embeddingModelLoaded = false;

  final documents = qs<List<Document>>([]);
  final documentParsing = qs<Set<int>>({});
  String _modelName = '';
  final Stopwatch _stopwatchParse = Stopwatch();
  late final boxChunk = ObjectBox.instance.store.box<DocumentChunk>();
  late final boxDoc = ObjectBox.instance.store.box<Document>();

  Future init() async {
    try {
      await ObjectBox.init();
      documents.q = await boxDoc.getAllAsync();
    } catch (e) {
      qqe('init error: $e');
      // await ObjectBox.cleanup();
    }
  }

  Future<bool> checkLoadModel() async {
    if (P.fileManager.getEmbeddingModel() == null) {
      Alert.warning(S.current.please_download_the_required_models_first);
      ModelSelector.show(embedding: true);
      return false;
    }

    if (!embeddingModelLoaded) {
      await RagInitDialog.show(getContext()!);
    }
    return embeddingModelLoaded;
  }

  Future loadEmbeddingModel() async {
    if (!embeddingModelLoaded) {
      final file = P.fileManager.getEmbeddingModel();
      if (file == null) {
        return;
      }
      _modelName = file.name;
      await P.rwkv.loadEmbeddingModel(file).timeout(Duration(seconds: 30));
      embeddingModelLoaded = true;
    }
  }

  Future<List<ChunkQueryResult>> query(String text, {int? count}) async {
    qqq('rag query: $text');
    if (text.isEmpty) {
      return [];
    }

    final availableDoc = documents.q
        .where((e) => e.modelName == _modelName) //
        .map((e) => e.id)
        .toList();

    final queryVector = (await P.rwkv.embed([text]))[0];
    final condition = DocumentChunk_
        .embedding //
        .nearestNeighborsF32(queryVector, 200)
        .and(DocumentChunk_.documentId.oneOf(availableDoc));
    final query = boxChunk.query(condition).build()..limit = count ?? 10;
    final result = await query.findWithScoresAsync();
    query.close();
    final id2doc = <int, Document>{
      for (var doc in documents.q) doc.id: doc,
    };
    final r = result
        .map(
          (e) => ChunkQueryResult(
            text: e.object.content,
            documentName: id2doc[e.object.documentId]?.name ?? '-',
            dimension: e.object.embedding!.length,
            model: id2doc[e.object.documentId]?.modelName ?? '-',
            score: e.score,
            embedding: e.object.embedding!,
          ),
        )
        .sortedBy((e) => -e.score)
        .toList();
    return r;
  }

  Stream<Document> parseFile(String path) async* {
    int id = -1;
    try {
      qqq('parseFile: $path');
      await for (var doc in _chunkFile(path)) {
        qqq('update=>${doc.name}, ${doc.parsed}/${doc.chunks}');
        documents.q = [if (id == -1) doc, ...documents.q];
        if (id == -1) {
          id = doc.id;
          documentParsing.q.add(id);
        }
        yield doc;
      }
    } catch (e) {
      final parsing = documents.q.firstWhereOrNull((e) => e.parsed != e.length);
      deleteDocument(parsing?.id);
      qqe('parseFile error: $e');
      rethrow;
    } finally {
      qqq('parseFile done');
      _stopwatchParse.stop();
      documentParsing.q = documentParsing.q.where((e) => e != id).toSet();
    }
  }

  Future regenerateDocumentEmbedding(Document doc) async {
    final condition = DocumentChunk_.documentId.equals(doc.id);
    final query = boxChunk.query(condition).build();
    final chunks = await query.findAsync();
    if (chunks.isEmpty) {
      return;
    }
    await boxChunk.putManyAsync(chunks.map((e) => e..embedding = null).toList());
    query.close();
    await boxDoc.putAsync(
      doc
        ..parsed = 0
        ..time = 0,
    );
    parseDocument(doc);
  }

  Future deleteDocument(int? id) async {
    if (id == null) {
      return;
    }
    boxDoc.remove(id);
    documents.q = await boxDoc.getAllAsync();

    final condition = DocumentChunk_.documentId.equals(id);
    final query = boxChunk.query(condition).build();
    query.remove();
    query.close();
  }

  Stream<Document> _chunkFile(String path) async* {
    final file = File(path);
    var doc = Document()
      ..name = file.path.split(separator).last
      ..path = path
      ..chunks = 0
      ..parsed = 0
      ..modelName = _modelName
      ..time = 0
      ..timestamp = DateTime.now().millisecondsSinceEpoch
      ..length = await file.length();

    doc = await boxDoc.putAndGetAsync(doc);

    yield doc;

    _stopwatchParse.reset();
    _stopwatchParse.start();
    final stream = DocumentParser(path: path).parse();
    await for (var parsed in stream) {
      final chunk = parsed.chunks.join(' ').replaceAll('\n', '');
      if (chunk.length < 5) continue;
      await boxChunk.putAsync(
        DocumentChunk()
          ..documentId = doc.id
          ..content = chunk,
      );
      doc.time = _stopwatchParse.elapsed.inMilliseconds;
      doc.chunks += 1;
      doc.lines += parsed.chunks.length;
      doc.characters += chunk.length;
      yield doc;
    }
    await boxDoc.putAsync(doc);
    yield doc;
    _stopwatchParse.stop();

    yield* _parseDocumentInternal(doc);
  }

  void parseDocument(Document doc) async {
    if (!await P.rag.checkLoadModel()) {
      return;
    }

    documentParsing.q = {doc.id, ...documentParsing.q};
    try {
      await for (var e in _parseDocumentInternal(doc)) {
        documents.q = [e, ...documents.q.where((d) => d.id != e.id)];
      }
    } catch (e) {
      qqe(e);
    } finally {
      documentParsing.q = documentParsing.q.where((e) => e != doc.id).toSet();
    }
  }

  void shareDocument(Document doc) async {
    final condition = DocumentChunk_.documentId.equals(doc.id);
    final query = boxChunk.query(condition).build();
    final chunks = await query.findAsync();
    query.close();

    final docMap = doc.toMap();
    docMap['chunks'] = chunks.map((e) => e.toMap()).toList();
    final json = jsonEncode(docMap);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}${Platform.pathSeparator}${doc.name}.json');
    if (file.existsSync()) await file.delete();
    await file.writeAsString(json);

    final xFile = XFile(file.path, mimeType: 'text/plain');
    await SharePlus.instance.share(
      ShareParams(previewThumbnail: xFile, files: [xFile]),
    );
  }

  Stream<Document> _parseDocumentInternal(Document doc) async* {
    Condition<DocumentChunk> condition = DocumentChunk_
        .documentId //
        .equals(doc.id)
        .and(DocumentChunk_.embedding.isNull());
    final chunks = boxChunk.query(condition).build().stream();

    _stopwatchParse.reset();
    _stopwatchParse.start();
    int time = doc.time;
    await for (final chunk in chunks) {
      final embedding = await P.rwkv.embed([chunk.content]);
      chunk.embedding = embedding[0];
      doc.time = time + _stopwatchParse.elapsed.inMilliseconds;
      doc.parsed += 1;
      yield doc;
      await boxDoc.putAsync(doc);
      await boxChunk.putAsync(chunk);
    }
    _stopwatchParse.stop();
  }

  static double similarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) {
      throw Exception("Invalid embedding length");
    }
    var sum = 0.0;
    var sumA = 0.0;
    var sumB = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
      sumA += a[i] * a[i];
      sumB += b[i] * b[i];
    }
    if (sumA == 0 || sumB == 0) {
      return (sumA == 0 && sumB == 0) ? 1.0 : 0.0;
    }
    return sum / (sqrt(sumA) * sqrt(sumB));
  }
}

class ParseResult {
  final List<String> chunks;
  final int offset;
  final int length;

  ParseResult({required this.chunks, required this.offset, required this.length});
}

class DocumentParser {
  final int minChunkSize = 50;
  final int maxChunkSize = 150;

  final String path;

  List<String> _chunks = [];
  final List<String> _buffer = [];
  final Runes separators;

  DocumentParser({required this.path, String separators = '!。；？！'}) : separators = separators.runes;

  Stream<ParseResult> parse() async* {
    if (path.toLowerCase().endsWith('.pdf')) {
      yield* _parsePdf();
      return;
    }
    yield* _parseText();
  }

  Stream<ParseResult> _parseText() async* {
    final file = File(path);
    final rndFile = file.openSync();
    final len = await rndFile.length();

    final text = await file.readAsString();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final chunks = _parseByte(char);
      if (chunks != null) {
        yield ParseResult(chunks: chunks, offset: i, length: len);
      }
    }
  }

  Stream<ParseResult> _parsePdf() async* {
    final bytes = await File(path).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final ext = PdfTextExtractor(document).extractTextLines().map((e) => e.text).join('\n');

    document.dispose();
    for (var i = 0; i < ext.length; i++) {
      final char = ext[i];
      final chunks = _parseByte(char);
      if (chunks != null) {
        yield ParseResult(chunks: chunks, offset: i, length: ext.length);
      }
    }
  }

  List<String>? _parseByte(String char) {
    _buffer.add(char);

    if (separators.contains(char.runes.first)) {
      final chunk = _buffer.join().trim();
      if (chunk.isEmpty) {
        return null;
      }
      _chunks.add(chunk);
      _buffer.clear();

      final totalLen = _chunks.map((e) => e.length).reduce((a, b) => a + b);
      if (totalLen < minChunkSize) {
        return null;
      }
      int len = 0;
      List<String> _result = [];
      List<String> _newChunks = _chunks.toList();
      while (len < maxChunkSize) {
        if (_newChunks.isEmpty) {
          break;
        }
        final first = _newChunks.removeAt(0);
        len += first.length;
        _result.add(first);
      }
      _chunks = _newChunks;
      return _result.where((e) => e.trim().isNotEmpty).toList();
    }
    return null;
  }
}
