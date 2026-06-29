import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/page/web_demo.dart';
import 'package:zone/store/p.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Web Demo opens as an independent grid tool', (tester) async {
    P.app.theme.q = .light;
    P.app.qb.q = Colors.black;
    P.app.qw.q = Colors.white;
    P.msg.ids.q = [];
    P.msg.msgNode.q = MsgNode(0);
    P.rwkvParams.arguments(Argument.presencePenalty).q = 2;
    P.rwkvParams.arguments(Argument.frequencyPenalty).q = .2;
    P.webDemo.arguments(Argument.presencePenalty).q = 1;
    P.webDemo.arguments(Argument.frequencyPenalty).q = .1;
    P.webDemo.batchSize.q = 30;
    P.webDemo.promptInput.q = "";
    P.webDemo.promptController.text = "";
    P.webDemo.results.q = const <WebDemoResult>[];
    P.webDemo.currentRun.q = null;
    P.webDemo.active.q = false;

    await tester.pumpWidget(
      const StateWrapper(
        child: MaterialApp(
          home: PageWebDemo(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("RWKV Web Demo"), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text("Generate HTML Grid"), findsOneWidget);
    expect(find.text("Batch Size"), findsOneWidget);
    expect(find.text("13.3B"), findsOneWidget);
    expect(find.text("30"), findsWidgets);
    expect(find.text("Generate an HTML grid to compare candidates."), findsOneWidget);

    final presenceFrame = find.ancestor(
      of: find.text("Presence Penalty"),
      matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == "_ControlFrame"),
    );
    final countFrame = find.ancestor(
      of: find.text("Count Penalty"),
      matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == "_ControlFrame"),
    );
    expect(find.descendant(of: presenceFrame, matching: find.text("1.0")), findsOneWidget);
    expect(find.descendant(of: countFrame, matching: find.text("0.1")), findsOneWidget);
    expect(P.rwkvParams.arguments(Argument.presencePenalty).q, 2);
    expect(P.rwkvParams.arguments(Argument.frequencyPenalty).q, .2);
  });
}
