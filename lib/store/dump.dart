part of 'p.dart';

class _Dump {
  final path = "/storage/emulated/0/Download/rwkvsee";
  late final latestDumpMessageId = qs(0);
}

/// Private methods
extension _$Dump on _Dump {
  FV _init() async {
    switch (P.app.demoType.q) {
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.tts:
        return;
      case DemoType.world:
    }
    qq;
    P.msg.list.lv(_onMessagesChanged);
  }

  FV _onMessagesChanged() async {
    qr;
    final dumpping = P.preference.dumpping.q;
    if (!dumpping) return;
    final messages = P.msg.list.q;
    if (messages.length != 3) return;
    final lastMessage = messages.last;
    final isMine = lastMessage.isMine;
    if (isMine) return;
    final paused = lastMessage.paused;
    if (paused) return;
    final changing = lastMessage.changing;
    if (changing) return;
    _dumpChatMessages(alertPermission: false);
  }

  FV _dumpChatMessages({bool alertPermission = true}) async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      // Handle the case where permission is not granted
      final msg = S.current.storage_permission_not_granted;
      if (alertPermission) Alert.warning(msg);
      return;
    }

    qr;

    final messages = P.msg.list.q;

    if (messages.isEmpty) return;

    if (latestDumpMessageId.q == messages.last.id) {
      qqw("Latest dump message id is the same as the latest message id, skipping");
      return;
    }

    latestDumpMessageId.q = messages.last.id;

    final List<String> imagePaths = [];
    String content = "";
    for (final m in messages) {
      final type = m.type;
      switch (type) {
        case MessageType.text:
          content += m.isMine ? "User:\n" : "Bot:\n";
          content += m.content + "\n";
          break;
        case MessageType.userImage:
          final imageUrl = m.imageUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            imagePaths.add(imageUrl);
            content += "Image:\n";
            content += (imageUrl.split("/").last) + "\n";
          }
          break;
        case MessageType.userAudio:
        case MessageType.userTTS:
        case MessageType.ttsGeneration:
          break;
      }
    }

    Directory? externalDir;
    if (Platform.isAndroid) {
      externalDir = Directory(path);
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      externalDir = await getApplicationDocumentsDirectory();
    }

    if (externalDir == null) {
      ScaffoldMessenger.of(getContext()!).showSnackBar(const SnackBar(content: T("Could not get external directory")));
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newDirPath = '${externalDir.path}/ChatDump_$timestamp';
    final newDir = Directory(newDirPath);
    await newDir.create(recursive: true);

    // Save text content
    final textFile = File('${newDir.path}/chat_log.txt');
    await textFile.writeAsString(content);

    // Save images
    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final originalFile = File(imagePath);
      if (await originalFile.exists()) {
        final fileName = imagePath.split('/').last;
        final newImagePath = '${newDir.path}/$fileName';
        await originalFile.copy(newImagePath);
      }
    }

    qqr("Files saved to ${newDir.path}");
  }
}

/// Public methods
extension $Dump on _Dump {
  FV startDump() async {
    P.app.hapticLight();
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Alert.warning(S.current.storage_permission_not_granted);
        return;
      }
    }
    await P.preference._saveDumpping(true);
    await showOkAlertDialog(
      context: getContext()!,
      title: S.current.dump_started,
      message: S.current.dump_see_files_alert_message(path),
    );
    _dumpChatMessages();
  }

  FV stopDump() async {
    P.app.hapticLight();
    await P.preference._saveDumpping(false);
    Alert.info(S.current.dump_stopped);
  }
}
