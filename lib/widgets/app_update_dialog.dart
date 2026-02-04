import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';

@Deprecated('Use VersionInfoPanel instead')
class AppUpdateDialog extends StatefulWidget {
  final String url;

  const AppUpdateDialog({super.key, required this.url});

  static Future show(BuildContext context, {required String url}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AppUpdateDialog(
          url: url,
        ),
      ),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  double progress = 0;
  double fileSizeMB = 0;
  bd.DownloadTask? task;
  String path = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        downloadAppUpdate(widget.url);
      } catch (e) {
        onDownloadFailed();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (task != null) {
      bd.FileDownloader().cancel(task!);
    }
  }

  void onDownloadFailed() {
    bd.FileDownloader().cancel(task!);
    task = null;

    if (!mounted) return;
    setState(() {
      progress = -1;
    });
  }

  void installApk() async {
    qqq('apk path: $path');
    final utils = const MethodChannel("utils");
    final r = await utils.invokeMethod('installApk', {"path": path});
    qqq(r);
  }

  Future<void> downloadAppUpdate(String url) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = "$ts.apk";
    task = bd.DownloadTask(
      url: url,
      baseDirectory: bd.BaseDirectory.temporary,
      filename: fileName,
      updates: bd.Updates.statusAndProgress,
      requiresWiFi: false,
      retries: 5,
      allowPause: false,
      httpRequestMethod: "GET",
    );

    fileSizeMB = (await task!.expectedFileSize()) / 1024 / 1024;

    final dl = bd.FileDownloader();
    dl.download(
      task!,
      onStatus: (s) async {
        if (s.isFinalState) {
          if (progress == 1) {
            path = await task!.filePath();
            installApk();
            if (mounted) Navigator.pop(context);
          } else {
            onDownloadFailed();
          }
        }
      },
      onProgress: (p) {
        setState(() {
          progress = p;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Center(
      widthFactor: 1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const .symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const .all(.circular(16)),
          ),
          padding: const .symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .min,
            children: [
              const SizedBox(height: 4),
              Text(
                s.downloading,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress <= 0 ? null : progress,
              ),
              const SizedBox(height: 8),
              if (progress != -1)
                Text(
                  '${(fileSizeMB * progress).round()}MB / ${fileSizeMB.round()}MB',
                  style: theme.textTheme.bodyMedium,
                ),
              if (progress == -1)
                Text(
                  'Download failed',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(s.cancel_download),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
