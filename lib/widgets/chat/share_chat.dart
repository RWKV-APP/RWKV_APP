import 'dart:io' show File, Platform;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart' show Gal;
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path_provider/path_provider.dart' show getApplicationCacheDirectory;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/config.dart' show Config;
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/state/p.dart' show P;
import 'package:zone/widgets/chat/message.dart';

class ShareChatSheet extends ConsumerStatefulWidget {
  const ShareChatSheet({super.key});

  @override
  ConsumerState<ShareChatSheet> createState() => _ShareChatSheetState();
}

enum _PreviewType {
  none,
  share,
  save,
}

class _ShareChatSheetState extends ConsumerState<ShareChatSheet> {
  _PreviewType previewType = _PreviewType.none;
  List<model.Message> messages = [];

  void onCancelTap() {
    P.chat.selectedMessages.q = {};
    P.chat.selectMessageMode.q = false;
  }

  void onShareTap() {
    final selected = P.chat.selectedMessages.q;
    messages = P.msg.list.q.where((m) => selected.contains(m.id)).toList();

    setState(() {
      previewType = _PreviewType.share;
    });
  }

  void onSaveTap() {
    final selected = P.chat.selectedMessages.q;
    messages = P.msg.list.q.where((m) => selected.contains(m.id)).toList();

    setState(() {
      previewType = _PreviewType.save;
    });
  }

  void generate() {
    //
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(P.chat.selectedMessages).length;

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCancelTap,
                      label: Text(S.of(context).cancel),
                      icon: Icon(Icons.cancel_outlined),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: selectedCount == 0 ? null : onSaveTap,
                      label: Text(S.of(context).save),
                      icon: Icon(Icons.save_alt_outlined),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: selectedCount == 0 ? null : onShareTap,
                      label: Text(S.of(context).share),
                      icon: Icon(Icons.share_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (previewType != _PreviewType.none)
          _Preview(
            share: previewType == _PreviewType.share,
            messages: messages,
            onCancelTap: () {
              setState(() {
                messages = [];
                previewType = _PreviewType.none;
              });
            },
            onComplete: () {
              onCancelTap();
              messages = [];
              previewType = _PreviewType.none;
            },
          ),
      ],
    );
  }
}

class _Preview extends ConsumerStatefulWidget {
  final List<model.Message> messages;
  final VoidCallback onCancelTap;
  final VoidCallback onComplete;

  final bool share;

  _Preview({
    required this.share,
    required this.messages,
    required this.onCancelTap,
    required this.onComplete,
  });

  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<_Preview> {
  final keyRepaintBoundary = GlobalKey();
  late QrImage qrImage;
  late final ScrollController controller = ScrollController();
  File? imagePreview;

  @override
  void initState() {
    super.initState();
    final url = P.preference.isZhLang() ? P.app.shareChatQrCodeZh : P.app.shareChatQrCodeEn;
    qrImage = QrImage(QrCode(8, QrErrorCorrectLevel.H)..addData(url.q ?? "https://www.rwkv.com/"));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final file = await _generatePreview();
        setState(() {
          imagePreview = file;
        });
      } catch (e) {
        qqe(e);
        widget.onCancelTap();
        Alert.error("Failed to generate preview image");
      }
    });
  }

  void onConfirmTap(BuildContext context) async {
    final file = imagePreview;
    if (file == null) return;

    if (widget.share) {
      final xFile = XFile(file.path, mimeType: 'image/png');
      await SharePlus.instance.share(
        ShareParams(previewThumbnail: xFile, files: [xFile]),
      );
    } else {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final allowed = await Gal.requestAccess(toAlbum: true);
        if (!allowed) return;
      }
      await Gal.putImage(file.path);
    }
    widget.onComplete();
  }

  Future<File?> _generatePreview() async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final rb = keyRepaintBoundary.currentContext!.findRenderObject() as RenderBox;
    final step = rb.size.height.toDouble();
    final maxExtent = controller.position.maxScrollExtent;
    final repaintBoundary = keyRepaintBoundary.currentContext!.findRenderObject() as RenderRepaintBoundary;

    int width = 0;
    double offsetY = 0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;
    int i = 0;
    double lastScrolled = 0;
    while (true) {
      final remain = maxExtent - controller.position.pixels;
      // FIXME: 尝试添加一个顶部的偏移量，空白区域，解决图片花屏问题
      ui.Image img = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      width = img.width > width ? img.width : width;
      if (remain == 0 && i != 0) {
        final top = (step - lastScrolled) * pixelRatio;
        img = await _cropImage(img, Rect.fromLTRB(0, top, width.toDouble(), img.height.toDouble()));
      }
      canvas.drawImage(img, Offset(0, offsetY), paint);
      offsetY += img.height;
      i++;
      if (remain <= 0) {
        break;
      } else {
        final offset = remain > step ? i * step : maxExtent;
        lastScrolled = remain;
        controller.jumpTo(offset);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    final image = await recorder.endRecording().toImage(width, offsetY.toInt());

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dir = await getApplicationCacheDirectory();
    final file = File("${dir.path}${Platform.pathSeparator}tmp_$timestamp.png");

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    if (await file.exists()) await file.delete();
    await file.create();
    await file.writeAsBytes(bytes);

    return file;
  }

  Future<ui.Image> _cropImage(ui.Image img, Rect crop) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      img,
      crop,
      Rect.fromLTRB(0, 0, crop.width, crop.height),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    return await picture.toImage(
      crop.width.toInt(),
      crop.height.toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = ref.watch(P.app.dark);

    if (imagePreview == null) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black38,
        child: Stack(
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainer,
                ),
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
            Positioned(
              top: 20000,
              left: 0,
              right: 0,
              child: _shot(theme, dark),
            ),
          ],
        ),
      );
    }

    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.black38,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 36, vertical: 100),
                  child: Image.file(imagePreview!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Material(
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: widget.onCancelTap,
                    icon: Icon(Icons.close),
                    label: Text(S.of(context).cancel),
                  ),
                  TextButton.icon(
                    onPressed: () => onConfirmTap(context),
                    icon: Icon(Icons.check),
                    label: Text(S.of(context).confirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shot(ThemeData theme, bool dark) {
    return RepaintBoundary(
      key: keyRepaintBoundary,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              Divider(height: 28, indent: 16, endIndent: 16, thickness: 0.5),
              for (var msg in widget.messages) Message(msg, 1, selectMode: true),
              const SizedBox(height: 24),
              Stack(
                children: [
                  Divider(indent: 16, endIndent: 16, thickness: 0.5),
                  Center(
                    child: Container(
                      width: 50,
                      color: theme.scaffoldBackgroundColor,
                      alignment: Alignment.center,
                      child: Text(
                        S.current.end,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFooter(dark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool dark) {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T')[0];

    final qrCode = SizedBox(
      width: 50,
      height: 50,
      child: PrettyQrView(
        qrImage: qrImage,
        decoration: const PrettyQrDecoration(),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 16),
        Text(date, style: TextStyle(fontSize: 10, color: Colors.grey)),
        Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(S.current.scan_qrcode, style: TextStyle(fontSize: 10, color: Colors.grey, height: 1)),
            const SizedBox(height: 4),
            Text(S.current.explore_rwkv, style: TextStyle(fontSize: 10, color: Colors.grey, height: 1)),
          ],
        ),
        const SizedBox(width: 8),
        !dark
            ? qrCode
            : ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
          child: qrCode,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const SizedBox(width: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            "assets/img/chat/icon.png",
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Config.appTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              sprintf(S.current.from_model, [P.rwkv.currentModel.q?.name ?? ""]),
              style: TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
        Spacer(),
        const SizedBox(width: 16),
      ],
    );
  }
}
