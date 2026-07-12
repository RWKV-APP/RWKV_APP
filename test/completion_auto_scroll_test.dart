// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/page/completion/completion_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(CompletionState.startAutoScrolling);

  testWidgets('manual scrolling pauses auto scroll until returning to the bottom', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: CompletionAutoScrollRegion(
              child: ListView.builder(
                controller: controller,
                itemCount: 50,
                itemExtent: 40,
                itemBuilder: (context, index) => Text('Line $index'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(CompletionState.autoScrolling, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(controller.position.maxScrollExtent));
    expect(CompletionState.autoScrolling, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(CompletionState.autoScrolling, isFalse);

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(CompletionState.autoScrolling, isTrue);
  });
}
