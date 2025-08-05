import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/db/objectbox.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/user_type.dart';
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
  bool showClearButton = false;
  bool querying = false;
  final searchFocus = FocusNode();

  final TextEditingController searchTextController = TextEditingController();
  final StreamController<String> searchText = StreamController();

  bool isExpert = false;

  @override
  void initState() {
    super.initState();
    isExpert = P.preference.userType.q == UserType.expert;
    searchText.stream
        .map((event) => true)
        .timeout(Duration(milliseconds: 600))
        .onErrorReturn(false)
        .distinct((p, n) => p == n)
        .where((typing) => !typing)
        .skip(1)
        .listen((event) {
          onSearchSubmit();
        });
  }

  void onSearchSubmit() async {
    final text = searchTextController.text;
    setState(() {
      showClearButton = text.isNotEmpty;
      querying = true;
    });
    final results = await P.rag.query(text);
    setState(() {
      searchResults = results;
      querying = false;
    });
  }

  void onSearchChanged(String text) {
    searchText.add(text);
  }

  void onSettingTap() async {
    //
  }

  void onSearchTap() async {
    if (!await P.rag.checkLoadModel()) {
      return;
    }
    searchTextController.text = '';
    setState(() {
      isSearch = true;
    });
    searchFocus.requestFocus();
  }

  void onAddDocumentTap() async {
    if (!await P.rag.checkLoadModel()) {
      return;
    }
    if (P.rag.parsing.q) {
      Alert.warning('Please wait for the previous parsing to complete.');
      return;
    }
    final XFile? xFile = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(extensions: ['md', 'pdf', 'txt', 'docx', 'json']),
      ],
    );
    if (xFile == null) {
      return;
    }
    if (xFile.path.endsWith('.json')) {
      P.rag.importDocument(xFile.path);
      return;
    }

    final len = await xFile.length();
    final mb = len / 1024 / 1024;
    if (mb > 10) {
      Alert.error('File size too large (max 5MB)');
      return;
    }
    P.rag.parseFile(xFile.path).listen((e) {});
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
          ? Center(child: Text(S.current.no_document_found))
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
    if (querying) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      key: ValueKey(searchResults),
      padding: EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final chunk = searchResults[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              child: SelectableText(
                chunk.text,
                style: TextStyle(),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  "Score: ${chunk.score}\n"
                  "${chunk.documentName},  Length: ${chunk.text.length}",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 100,
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
      title: Text(S.current.documents),
      actionsPadding: EdgeInsets.zero,
      actions: [
        if (isExpert)
          IconButton(
            onPressed: onSearchTap,
            icon: Icon(Icons.search),
          ),
        IconButton(
          onPressed: onAddDocumentTap,
          icon: Icon(Icons.add),
        ),
        // if (isExpert)
        //   IconButton(
        //     onPressed: onSettingTap,
        //     icon: Icon(Icons.settings),
        //   ),
      ],
    );
  }

  PreferredSizeWidget buildSearchAppBar() {
    return AppBar(
      leading: SizedBox(),
      leadingWidth: 0,
      title: Row(
        children: [
          Expanded(
            child: SearchBar(
              elevation: WidgetStatePropertyAll(0),
              controller: searchTextController,
              // onChanged: onSearchChanged,
              onSubmitted: (v) => searchText.add(v),
              focusNode: searchFocus,
              leading: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.grey, size: 18),
              ),
              trailing: [
                if (showClearButton)
                  IconButton(
                    onPressed: () {
                      searchResults.clear();
                      searchTextController.clear();
                      setState(() {
                        showClearButton = false;
                      });
                    },
                    icon: FaIcon(FontAwesomeIcons.circleXmark, size: 18, color: Colors.grey),
                  ),
              ],
              constraints: BoxConstraints(minHeight: 46),
              scrollPadding: EdgeInsets.zero,
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              searchFocus.unfocus();
              setState(() {
                isSearch = false;
                searchTextController.clear();
                searchResults.clear();
              });
            },
            child: Text(S.current.cancel),
          ),
        ],
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

  static String getDisplayTime(int mill) {
    final datetime = DateTime.fromMillisecondsSinceEpoch(mill);
    return sprintf('%02d-%02d', [datetime.month, datetime.day]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final userType = ref.watch(P.preference.userType);
    final ext = document.name.split('.').last.toLowerCase();
    final docParsing = ref.watch(P.rag.documentParsing);
    IconData icon = fileIcons[ext] ?? FontAwesomeIcons.file;

    final seconds = document.time / 1000;
    String time = "";

    if (seconds > 60) {
      time = "${(seconds / 60).toInt()}min ${(seconds % 60).toInt()}sec";
    } else {
      time = "${seconds.toInt()}sec";
    }

    final parsing = docParsing.contains(document.id);
    final chunking = parsing && document.parsed == 0;
    final parsed = !parsing && document.chunks <= document.parsed;

    final isExpertUser = userType == UserType.expert;

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
            if (chunking) Positioned.fill(child: _BlinkAnimation()),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 50,
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
                        Text(
                          document.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        if (isExpertUser)
                          Text(
                            sprintf(S.current.parsed_chunks, [document.parsed, document.chunks]),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        // if (parsing) Text(sprintf(S.current.took_x, [time.trim()]), style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Row(
                          children: [
                            Text(getDisplayTime(document.timestamp), style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(width: 6),
                            SizedBox(height: 12, child: VerticalDivider()),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                sprintf(S.current.chars_x, [document.characters]),
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (parsed)
                    IconButton(
                      onPressed: () {
                        P.rag.shareDocument(document);
                      },
                      icon: FaIcon(FontAwesomeIcons.share),
                    ),
                  if (!parsed && !parsing)
                    IconButton(
                      onPressed: () {
                        P.rag.parseDocument(document);
                      },
                      icon: FaIcon(FontAwesomeIcons.fileImport),
                    ),
                  if (parsing)
                    IconButton(
                      onPressed: () {
                        P.rag.stopParsing(document);
                      },
                      icon: Icon(Icons.close),
                    ),
                  // if (parsed)
                  //   IconButton(
                  //     onPressed: () {
                  //       P.rag.regenerateDocumentEmbedding(document);
                  //     },
                  //     icon: FaIcon(FontAwesomeIcons.rotate),
                  //   ),
                  if (!parsing)
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

class _BlinkAnimation extends StatefulWidget {
  @override
  State<_BlinkAnimation> createState() => _BlinkAnimationState();
}

class _BlinkAnimationState extends State<_BlinkAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.grey : Colors.lightGreen;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary.withAlpha(150),
                primary.withAlpha(40),
                primary.withAlpha(150),
              ],
              stops: [0, _controller.value, 1],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
