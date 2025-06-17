import 'dart:io' show File, Platform;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary, OffsetLayer;
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
  List<model.Message> selectedMessages = [];

  void onCancelTap() {
    P.chat.sharingSelectedMsgIds.q = {};
    P.chat.isSharing.q = false;
  }

  void onShareTap() {
    final selected = P.chat.sharingSelectedMsgIds.q;
    selectedMessages = P.msg.list.q.where((m) => selected.contains(m.id)).toList();

    setState(() {
      previewType = _PreviewType.share;
    });
  }

  void onSaveTap() {
    final selected = P.chat.sharingSelectedMsgIds.q;
    selectedMessages = P.msg.list.q.where((m) => selected.contains(m.id)).toList();

    setState(() {
      previewType = _PreviewType.save;
    });
  }

  void generate() {
    //
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(P.chat.sharingSelectedMsgIds).length;
    final paddingBottom = ref.watch(P.app.paddingBottom);

    return Stack(
      children: [
        Positioned(
          bottom: paddingBottom,
          left: 0,
          right: 0,
          child: Material(
            elevation: 16,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCancelTap,
                      label: Text(S.of(context).cancel),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: selectedCount == 0 ? null : onSaveTap,
                      label: Text(S.of(context).save),
                      icon: const Icon(Icons.save_alt_outlined),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: selectedCount == 0 ? null : onShareTap,
                      label: Text(S.of(context).share),
                      icon: const Icon(Icons.share_rounded),
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
            messages: selectedMessages,
            onCancelTap: () {
              setState(() {
                selectedMessages = [];
                previewType = _PreviewType.none;
              });
            },
            onComplete: () {
              onCancelTap();
              selectedMessages = [];
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

  const _Preview({
    required this.share,
    required this.messages,
    required this.onCancelTap,
    required this.onComplete,
  });

  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

final kSharingRepaintBoundary = GlobalKey();

class _PreviewState extends ConsumerState<_Preview> {
  static const topCropForFixBadImage = 300.0;

  late QrImage qrImage;
  late final ScrollController controller = ScrollController();
  File? imagePreview;

  @override
  void initState() {
    super.initState();
    final url = P.preference.isZhLang() ? P.app.shareChatQrCodeZh : P.app.shareChatQrCodeEn;
    qrImage = QrImage(QrCode(8, QrErrorCorrectLevel.H)..addData(url.q ?? "https://www.rwkv.com/"));
    generatePreview();
  }

  void generatePreview() {
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
    final repaintBoundary = kSharingRepaintBoundary.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final imageSize = repaintBoundary.size;
    const maxHeightInPixel = 16384.0;
    final currentDPI = MediaQuery.devicePixelRatioOf(context);
    final wantedHeightInPixel = imageSize.height * currentDPI;
    double finalDPI = currentDPI;
    if (wantedHeightInPixel > maxHeightInPixel) {
      finalDPI = maxHeightInPixel / imageSize.height;
    }

    // 发现如下现象:
    // 当, 图片高度超过 16384 时, 如果, 我们使用原始的 pixelRatio, 那么, 溢出部分会被裁切
    // 所以, 此处限制了最大 dpi, 保证图片不会被裁切
    // 已知, xiaomi14 dpi 为 3

    final overflowed = wantedHeightInPixel > maxHeightInPixel;
    final count = (wantedHeightInPixel / maxHeightInPixel).ceil();

    qqr(imageSize.height);
    qqr(wantedHeightInPixel);
    qqr(overflowed);
    qqr(count);

    // FIXME: 如果, 图片高度超过 16384, 那么, 我们需要将图片分成多张, 然后, 将多张图片合并成一张图片
    // FIXME: 注意, 新和成的图片尺寸仍然无法超过 16384, 需要找到新的方法

    // ignore: invalid_use_of_protected_member
    final OffsetLayer offsetLayer = repaintBoundary.layer! as OffsetLayer;
    final image = await offsetLayer.toImage(Offset(0, 0) & imageSize, pixelRatio: finalDPI);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final bytes = byteData!.buffer.asUint8List();
    final dir = await getApplicationCacheDirectory();
    final milliseconds = HF.milliseconds;
    final file = File("${dir.path}${Platform.pathSeparator}tmp_$milliseconds.png");
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
      return LayoutBuilder(
        builder: (context, constraints) {
          qqr(constraints.maxWidth);
          return _generating(theme, dark);
        },
      );
    }

    final paddingBottom = ref.watch(P.app.paddingBottom);

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
                  margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 100),
                  child: Image.file(imagePreview!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Material(
            elevation: 16,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: widget.onCancelTap,
                    icon: const Icon(Icons.close),
                    label: Text(S.of(context).cancel),
                  ),
                  TextButton.icon(
                    onPressed: () => onConfirmTap(context),
                    icon: const Icon(Icons.check),
                    label: Text(S.of(context).confirm),
                  ),
                ],
              ),
            ),
          ),
          paddingBottom.h,
        ],
      ),
    );
  }

  Widget _generating(ThemeData theme, bool dark) {
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
              child: const CircularProgressIndicator(strokeWidth: 4),
            ),
          ),
          Positioned(
            top: 0,
            width: P.app.screenWidth.q,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.01,
                child: _shot(theme, dark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shot(ThemeData theme, bool dark) {
    final customTheme = ref.watch(P.app.customTheme);
    return SingleChildScrollView(
      child: RepaintBoundary(
        key: kSharingRepaintBoundary,
        child: ColoredBox(
          color: customTheme.scaffold,
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const Divider(height: 28, indent: 16, endIndent: 16, thickness: 0.5),
              for (var msg in widget.messages) Message(msg, 1, selectMode: true),
              const SizedBox(height: 24),
              Stack(
                children: [
                  const Divider(indent: 16, endIndent: 16, thickness: 0.5),
                  Center(
                    child: Container(
                      width: 50,
                      color: theme.scaffoldBackgroundColor,
                      alignment: Alignment.center,
                      child: Text(
                        S.current.end,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    final version = "${P.app.version.q} (${P.app.buildNumber.q})";

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
        Text("v$version\n$date", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(S.current.scan_qrcode, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1)),
            const SizedBox(height: 4),
            Text(S.current.explore_rwkv, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1)),
          ],
        ),
        const SizedBox(width: 8),
        !dark
            ? qrCode
            : ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
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
            const Text(
              Config.appTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              sprintf(S.current.from_model, [P.rwkv.currentModel.q?.name ?? ""]),
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 16),
      ],
    );
  }
}
