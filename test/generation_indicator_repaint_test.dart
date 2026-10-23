import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/bot_message_bottom.dart';

void main() {
  testWidgets('generation indicator animates without repainting the message ancestor', (tester) async {
    var paints = 0;
    const messageId = 901;
    P.app.screenWidth.q = 800;
    P.app.screenHeight.q = 600;
    P.app.theme.q = .light;
    P.app.demoType.q = .chat;
    P.chat.isSharing.q = false;
    P.chat.receiveId.q = messageId;
    P.rwkvContext.currentWorldType.q = null;
    P.rwkvGeneration.prefillProgress.q = 1;
    P.msg.bottomMessageTokensCount.q = {messageId: 12};
    P.msg.bottomConversationTokensCount.q = {messageId: 32};
    final msg = model.Message(id: messageId, content: 'Test response', isMine: false, paused: false, changing: true);
    await tester.pumpWidget(
      StateWrapper(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Center(
              child: _PaintCounter(
                onPaint: () => paints++,
                child: BotMessageBottom(msg, 0, disableDefaultActions: true),
              ),
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final rotation = find.ancestor(of: find.byIcon(Symbols.hourglass_top), matching: find.byType(Transform)).first;
    final beforeRotation = List<double>.of(tester.widget<Transform>(rotation).transform.storage);
    final beforePaints = paints;
    expect(beforePaints, greaterThan(0));
    expect(P.ui.maxWidthAllowedForLayout.q, 800);
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.widget<Transform>(rotation).transform.storage, isNot(orderedEquals(beforeRotation)));
    expect(paints, beforePaints, reason: 'A status-icon frame must not repaint the surrounding message');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _PaintCounter extends SingleChildRenderObjectWidget {
  final VoidCallback onPaint;
  const _PaintCounter({required this.onPaint, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPaintCounter(onPaint);
}

class _RenderPaintCounter extends RenderProxyBox {
  final VoidCallback onPaint;
  _RenderPaintCounter(this.onPaint);

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
    super.paint(context, offset);
  }
}
