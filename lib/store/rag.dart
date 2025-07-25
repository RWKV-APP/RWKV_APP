import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:collection/collection.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:zone/db/objectbox.dart';
import 'package:zone/objectbox.g.dart';
import 'package:zone/store/p.dart';

class EmbeddingQueryResult {
  final String text;
  final String documentName;

  EmbeddingQueryResult({required this.text, required this.documentName});
}

class RAG {
  bool embeddingModelLoaded = false;
  bool _isQuerying = false;
  final documents = qs<List<Document>>([]);
  String _modelName = '';

  Future init() async {
    try {
      await ObjectBox.init();
      documents.q = await loadDocumentList();
    } catch (e) {
      qqe('init error: $e');
    }
  }

  Future loadEmbeddingModel() async {
    if (!embeddingModelLoaded) {
      // final dir = r"D:\tmp\";
      final dir = (await getApplicationDocumentsDirectory()).path + "/";
      // final file = File("${dir}Qwen3-Embedding-0.6B-Q8_0.gguf");
      // final file = File("${dir}Qwen3-Embedding-0.6B-bf16.gguf");
      final file = File("${dir}bge-m3-F16.gguf");
      // final file = File("${dir}bge-m3-Q6_K.gguf");
      if (!file.existsSync()) {
        qqe('embedding model not found');
      }
      _modelName = file.path.split(Platform.pathSeparator).last;
      await P.rwkv.loadEmbeddingModel(file.path).timeout(Duration(seconds: 30));
      embeddingModelLoaded = true;
    }
  }

  Future<List<EmbeddingQueryResult>> query(String text) async {
    qqq('rag query: $text');
    if (text.isEmpty) {
      return [];
    }
    await loadEmbeddingModel();

    await Future(() async {
      while (_isQuerying) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }).timeout(Duration(seconds: 10));

    _isQuerying = true;
    final box = ObjectBox.instance.store.box<Embedding>();
    final queryVector = await P.rwkv.embed([text]);
    final condition = Embedding_.segment.nearestNeighborsF32(queryVector[0], 10);
    // final condition2 = Embedding_.content.contains(text);
    final result = await box.query(condition).build().findAsync();
    qqq('rag query done: ${result.length}');
    _isQuerying = false;
    final id2doc = <int, String>{
      for (var doc in documents.q) doc.id: doc.name,
    };
    return result.map((e) => EmbeddingQueryResult(text: e.content, documentName: id2doc[e.documentId] ?? '-')).toList();
  }

  Future<List<Document>> loadDocumentList() async {
    final box = ObjectBox.instance.store.box<Document>();
    return box.getAll();
  }

  Stream<Document> parseFile(String path) async* {
    try {
      // final p = (await getApplicationCacheDirectory()).path + "/FAQ.mdx";
      qqq('parseFile: $path');
      await for (var doc in _parseFile(path)) {
        qqq('update=>${doc.name}, ${doc.chunks}');
        final docs = documents.q;
        final exist = docs.any((e) => e.id == doc.id);
        documents.q = [if (!exist) doc, ...docs];
        yield doc;
      }
    } catch (e) {
      final parsing = documents.q.firstWhereOrNull((e) => e.parsed != e.length);
      deleteDocument(parsing?.id);
      qqe('parseFile error: $e');
      rethrow;
    } finally {
      qqq('parseFile done');
    }
  }

  Future deleteDocument(int? id) async {
    if (id == null) {
      return;
    }
    final boxEmbedding = ObjectBox.instance.store.box<Embedding>();
    final condition = Embedding_.documentId.equals(id);
    final ids = await boxEmbedding.query(condition).build().findIdsAsync();
    await boxEmbedding.removeManyAsync(ids);

    final boxDocument = ObjectBox.instance.store.box<Document>();
    boxDocument.remove(id);
    documents.q = await loadDocumentList();
  }

  Stream<Document> _parseFile(String path) async* {
    final file = File(path);

    final boxEmbedding = ObjectBox.instance.store.box<Embedding>();

    final fileName = file.path.split(separator).last;
    final startAt = DateTime.now().millisecondsSinceEpoch;

    var doc = Document()
      ..name = fileName
      ..path = path
      ..chunks = 0
      ..parsed = 0
      ..modelName = _modelName
      ..length = await file.length();

    final boxDocument = ObjectBox.instance.store.box<Document>();
    doc = await boxDocument.putAndGetAsync(doc);

    yield doc;

    final stream = DocumentParser(path: path).parse();
    await for (var parsed in stream) {
      final chunk = await _embedText(parsed.chunks.join('\n'));
      await boxEmbedding.putAsync(
        Embedding()
          ..segment = chunk.embedding
          ..documentId = doc.id
          ..content = chunk.content,
      );
      doc.chunks += 1;
      doc.time = DateTime.now().millisecondsSinceEpoch - startAt;
      doc.lines += parsed.chunks.length;
      doc.parsed = parsed.offset;
      doc.words += chunk.content.length;
      yield doc;
    }
    doc.parsed = doc.length;
    doc.time = DateTime.now().millisecondsSinceEpoch - startAt;
    await boxDocument.putAsync(doc);
    yield doc;
  }

  Future<_EmbeddedChunk> _embedText(String chunk) async {
    final embedding = await P.rwkv.embed([chunk]);
    final _chunk = _EmbeddedChunk(content: chunk, embedding: embedding[0]);
    return _chunk;
  }

  double _similarity(List<double> a, List<double> b) {
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

class _EmbeddedChunk {
  final String content;
  final List<double> embedding;

  _EmbeddedChunk({required this.content, required this.embedding});
}

class ParseResult {
  final List<String> chunks;
  final int offset;
  final int length;

  ParseResult({required this.chunks, required this.offset, required this.length});
}

class DocumentParser {
  final int minChunkSize = 200;
  final int maxChunkSize = 300;

  final String path;

  List<String> _chunks = [];
  final List<int> _buffer = [];

  late final _splitRunes = '\n\r,.;:?!。，、；：？！'.runes;

  DocumentParser({required this.path});

  Stream<ParseResult> parse({int offset = 0}) async* {
    if (path.toLowerCase().endsWith('.pdf')) {
      yield* _parsePdf();
      return;
    }
    yield* _parseText(offset: offset);
  }

  Stream<ParseResult> _parseText({int offset = 0}) async* {
    final file = File(path);
    final rndFile = file.openSync();
    final len = await rndFile.length();
    final parseLength = len - offset;
    await rndFile.setPosition(offset);

    var _offset = offset;
    while (_offset < len) {
      final byte = await rndFile.readByte();
      final chunks = _parseByte(byte);
      if (chunks != null) {
        yield ParseResult(chunks: chunks, offset: _offset, length: parseLength);
      }
      _offset++;
    }
  }

  Stream<ParseResult> _parsePdf() async* {
    final bytes = await File(path).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final ext = PdfTextExtractor(document).extractText();
    document.dispose();
    final bts = utf8.encode(ext);
    for (int i = 0; i < bts.length; i++) {
      final chunks = _parseByte(bts[i]);
      if (chunks != null) {
        yield ParseResult(chunks: chunks, offset: i, length: bts.length);
      }
    }
  }

  List<String>? _parseByte(int byte) {
    _buffer.add(byte);

    if (_splitRunes.contains(byte)) {
      final chunk = utf8.decode(_buffer).trim();
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
