// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/widgets/chat/share_chat_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets('share capture preparation waits until the bird logo is painted', (tester) async {
    final assetBundle = _ControlledAssetBundle();
    late BuildContext iconContext;

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: assetBundle,
        child: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                iconContext = context;
                return Image(
                  image: shareChatHeaderIconProvider(context),
                  width: 42,
                  height: 42,
                );
              },
            ),
          ),
        ),
      ),
    );

    final preparationCompleted = Completer<void>();
    final preparation = _prepareAndComplete(iconContext, preparationCompleted);
    await tester.pump();

    expect(preparationCompleted.isCompleted, isFalse);

    assetBundle.releaseIcon();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump();
    await preparation;

    expect(preparationCompleted.isCompleted, isTrue);
    final rawImage = tester.widget<RawImage>(find.byType(RawImage));
    expect(rawImage.image, isNotNull);
  });
}

Future<void> _prepareAndComplete(BuildContext context, Completer<void> completion) async {
  await prepareShareChatHeaderIcon(context);
  completion.complete();
}

class _ControlledAssetBundle extends CachingAssetBundle {
  final _iconReady = Completer<void>();

  void releaseIcon() {
    if (_iconReady.isCompleted) return;
    _iconReady.complete();
  }

  @override
  Future<ByteData> load(String key) async {
    if (key != shareChatHeaderIconPath) return rootBundle.load(key);
    await _iconReady.future;
    return rootBundle.load(key);
  }
}
