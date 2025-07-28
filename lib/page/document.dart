import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zone/db/objectbox.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/store/rag.dart';
import 'package:zone/widgets/app_scaffold.dart';

class PageDocuments extends ConsumerStatefulWidget {
  const PageDocuments({super.key});

  @override
  ConsumerState<PageDocuments> createState() => _PageDocumentsState();
}

class _PageDocumentsState extends ConsumerState<PageDocuments> {
  List<ChunkQueryResult> searchResults = [];

  bool isSearch = false;
  final searchFocus = FocusNode();

  final TextEditingController searchTextController = TextEditingController();
  final StreamController<String> searchText = StreamController();

  @override
  void initState() {
    super.initState();
    searchText.stream
        .map((event) => true)
        .timeout(Duration(milliseconds: 600))
        .onErrorReturn(false)
        .distinct((p, n) => p == n)
        .where((typing) => !typing)
        .skip(1)
        .listen((event) async {
          final text = searchTextController.text;
          final results = await P.rag.query(text);
          setState(() {
            searchResults = results;
          });
        });
  }

  void onSearchChanged(String text) {
    searchText.add(text);
  }

  void onSearchTap() async {
    await loadModel();
    searchTextController.text = '';
    setState(() {
      isSearch = true;
    });
    searchFocus.requestFocus();
  }

  void onAddDocumentTap() async {
    await loadModel();

    final XFile? xFile = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(
          extensions: ['mdx', 'md', 'pdf', 'txt', 'html', 'doc'],
        ),
      ],
    );
    if (xFile == null) {
      return;
    }
    P.rag.parseFile(xFile.path).listen((e) {});
  }

  Future loadModel() async {
    if (P.rag.embeddingModelLoaded) {
      return;
    }
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Material(
          color: Colors.black.withAlpha(128),
          child: Center(
            child: Material(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    try {
      await P.rag.loadEmbeddingModel().timeout(Duration(seconds: 10));
    } catch (e) {
      qqe(e);
    }
    entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(P.rag.documents);

    return Scaffold(
      appBar: isSearch ? buildSearchAppBar() : buildDocumentAppBar(),
      body: isSearch
          ? PopScope(
              onPopInvokedWithResult: (pop, c) {
                setState(() {
                  isSearch = false;
                });
              },
              canPop: false,
              child: buildSearchBody(),
            )
          : buildDocumentBody(docs),
    );
  }

  Widget buildDocumentBody(List<Document> docs) {
    return AppGradientBackground(
      child: docs.isEmpty
          ? Center(
              child: Text('No documents found.'),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return _Document(document: docs[index]);
              },
            ),
    );
  }

  Widget buildSearchBody() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final chunk = searchResults[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              chunk.text,
              style: TextStyle(),
              maxLines: 100,
            ),
            Row(
              children: [
                Text(
                  "score:${chunk.score}, document:${chunk.documentName}, length: ${chunk.text.length}",
                  style: TextStyle(color: Colors.grey),
                ),
                Spacer(),
              ],
            ),
            Divider(),
          ],
        );
      },
    );
  }

  PreferredSizeWidget buildDocumentAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text('Documents'),
      actions: [
        IconButton(
          onPressed: onSearchTap,
          icon: FaIcon(FontAwesomeIcons.magnifyingGlass),
        ),
        IconButton(
          onPressed: onAddDocumentTap,
          icon: FaIcon(FontAwesomeIcons.plus),
        ),
      ],
    );
  }

  PreferredSizeWidget buildSearchAppBar() {
    return AppBar(
      leading: SizedBox(),
      leadingWidth: 0,
      title: SearchBar(
        elevation: WidgetStatePropertyAll(0),
        controller: searchTextController,
        onChanged: onSearchChanged,
        focusNode: searchFocus,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.grey, size: 18),
        ),
        trailing: [
          IconButton(
            onPressed: () {
              searchFocus.unfocus();
              searchResults.clear();
              isSearch = false;
              setState(() {});
            },
            icon: FaIcon(FontAwesomeIcons.xmark),
          ),
        ],
        constraints: BoxConstraints(minHeight: 46),
        scrollPadding: EdgeInsets.zero,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _Document extends ConsumerWidget {
  final Document document;

  static final fileIcons = {
    'pdf': FontAwesomeIcons.filePdf,
    'mdx': FontAwesomeIcons.markdown,
    'md': FontAwesomeIcons.markdown,
    'txt': FontAwesomeIcons.fileLines,
    'doc': FontAwesomeIcons.fileWord,
    'docx': FontAwesomeIcons.fileWord,
    'xls': FontAwesomeIcons.fileExcel,
    'html': FontAwesomeIcons.fileCode,
  };

  _Document({required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final ext = document.name.split('.').last.toLowerCase();
    IconData icon = fileIcons[ext] ?? FontAwesomeIcons.file;

    final seconds = document.time / 1000;
    String time = "";

    if (seconds > 60) {
      time = "${(seconds / 60).toInt()} min ${(seconds % 60).toInt()} sec";
    } else {
      time = "${seconds.toInt()} sec";
    }

    final parsed = document.chunks <= document.parsed;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (!parsed)
              Positioned.fill(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: document.parsed,
                      child: Container(
                        color: Colors.lightGreen.withAlpha(100),
                      ),
                    ),
                    Expanded(
                      flex: document.chunks - document.parsed,
                      child: SizedBox(),
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(icon),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(document.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text("分块: ${document.chunks}, 字数: ${document.characters}"),
                        Text("${parsed ? '' : '${document.parsed}/${document.chunks}'}   耗时: $time".trim()),
                      ],
                    ),
                  ),
                  if (!parsed)
                    IconButton(
                      onPressed: () {
                        P.rag.parseDocument(document);
                      },
                      icon: FaIcon(FontAwesomeIcons.fileImport),
                    ),
                  IconButton(
                    onPressed: () {
                      P.rag.deleteDocument(document.id);
                    },
                    icon: FaIcon(FontAwesomeIcons.trashCan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
