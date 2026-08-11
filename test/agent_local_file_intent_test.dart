import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/agent_local_file_intent.dart';

void main() {
  group("isExplicitLocalFileActionRequest", () {
    test("recognizes direct Chinese desktop file creation", () {
      expect(
        isExplicitLocalFileActionRequest("请在桌面上创建一个文件，写入你好世界"),
        isTrue,
      );
    });

    test("recognizes a named English file update", () {
      expect(
        isExplicitLocalFileActionRequest(
          "Update notes.txt with the new meeting summary",
        ),
        isTrue,
      );
    });

    test("recognizes a named file read without the word file", () {
      expect(
        isExplicitLocalFileActionRequest("读取 README.md 并告诉我内容"),
        isTrue,
      );
    });

    test("does not route ordinary writing requests", () {
      expect(isExplicitLocalFileActionRequest("帮我写一首关于春天的诗"), isFalse);
    });

    test("does not route chat deletion requests", () {
      expect(isExplicitLocalFileActionRequest("删除这段对话"), isFalse);
    });

    test("does not route discussion about file systems", () {
      expect(
        isExplicitLocalFileActionRequest("介绍一下 Windows 文件系统"),
        isFalse,
      );
    });
  });
}
