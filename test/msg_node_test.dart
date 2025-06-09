import 'package:test/test.dart';
import 'package:zone/model/msg_node.dart';

// 辅助类，用于构建测试数据
class TestMsgBuilder {
  final MsgNode rootNode;

  TestMsgBuilder(this.rootNode);

  /// 构建一个消息链，从 `startNode`（如果提供）或 `rootNode` 开始，
  /// 依次添加指定 ID 的节点。
  /// 如果 `keepLatest` 为 true，则在添加新节点时，父节点的 `latest` 不会更新。
  /// 返回链中最后添加的节点。
  MsgNode buildChain(List<int> ids, {MsgNode? startNode, bool keepLatest = false}) {
    var current = startNode ?? rootNode;
    for (final id in ids) {
      current = current.add(MsgNode(id), keepLatest: keepLatest);
    }
    return current; // 返回最后添加的节点
  }

  /// 构建一个线性的对话，交替添加用户消息和机器人消息。
  /// `turns` 指定对话的回合数。
  /// `startId` 指定消息 ID 的起始值。
  List<MsgNode> buildLinearConversation(int turns, {int startId = 1}) {
    final nodes = <MsgNode>[];
    var currentParent = rootNode;
    var currentId = startId;

    for (var i = 0; i < turns; i++) {
      // 添加用户消息
      final userMsg = currentParent.add(MsgNode(currentId++));
      nodes.add(userMsg);
      if (i < turns) {
        // 为用户消息添加对应的机器人回复
        final botMsg = userMsg.add(MsgNode(currentId++));
        nodes.add(botMsg);
        currentParent = botMsg;
      } else {
        currentParent = userMsg;
      }
    }
    return nodes;
  }
}

void main() {
  late MsgNode root;
  late TestMsgBuilder builder;

  // 在每个测试运行前设置初始状态
  setUp(() {
    root = MsgNode(0);
    builder = TestMsgBuilder(root);
  });

  /// 📐 **基本构造和属性测试**
  /// ---
  group('基本构造和属性', () {
    test('节点初始化正确', () {
      expect(root.id, 0);
      expect(root.children, isEmpty);
      expect(root.latest, isNull);
      expect(root.parent, isNull);
      expect(root.root, isNull);
    });

    test('子节点被添加后，parent 和 root 被正确设置', () {
      final child = MsgNode(1);
      root.add(child);
      expect(child.parent, root);
      expect(child.root, root);
      expect(root.children, contains(child));
    });

    test('深层子节点的 root 仍指向初始根节点', () {
      final child1 = root.add(MsgNode(1));
      final child2 = child1.add(MsgNode(2));
      expect(child2.root, root);
    });
  });

  /// ➕ **`add` 方法测试**
  /// ---
  group('`add` 方法', () {
    test('可以添加子节点，`latest` 默认更新', () {
      final child1 = root.add(MsgNode(1));
      expect(root.latest, child1);
      expect(root.children, contains(child1));

      final child2 = root.add(MsgNode(2));
      expect(root.latest, child2, reason: "latest 应该更新为最新的子节点");
      expect(root.children, containsAll([child1, child2]));
    });

    test('使用 `keepLatest: true` 时，`latest` 不更新', () {
      final child1 = root.add(MsgNode(1));
      expect(root.latest, child1);

      final child2 = root.add(MsgNode(2), keepLatest: true);
      expect(root.latest, child1, reason: "如果 keepLatest 为 true，latest 不应更新");
      expect(root.children, contains(child2));
    });

    test('不允许添加重复 ID 的直接子节点', () {
      root.add(MsgNode(1));
      expect(
        () => root.add(MsgNode(1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  /// 🌳 **`rootAdd` 方法测试**
  /// ---
  group('`rootAdd` 方法', () {
    // 这个方法的行为有点复杂，因为 child.parent 变成了 wholeLatestNode，
    // 但 child 是被添加到 'this.children'。
    test('简单调用 (当 this 是 wholeLatestNode 时，行为类似 add)', () {
      final child1 = root.rootAdd(MsgNode(1)); // root.wholeLatestNode 是 root 自身
      expect(child1.parent, root);
      expect(root.children, contains(child1));
      expect(root.latest, child1);

      final child2 = child1.rootAdd(MsgNode(2)); // child1.wholeLatestNode 是 child1
      expect(child2.parent, child1);
      expect(child1.children, contains(child2));
      expect(child1.latest, child2);
      expect(root.latestMsgIds, [0, 1, 2]);
    });

    test('使用 `keepLatest: true` 时，`latest` 不更新 (当 this 是 wholeLatestNode)', () {
      final child1 = root.rootAdd(MsgNode(1));
      expect(root.latest, child1);

      root.rootAdd(MsgNode(2), keepLatest: true);
      expect(root.latest, child1, reason: "如果 keepLatest 为 true，rootAdd 不应更新 latest");
    });
  });

  /// 🆔 **`latestMsgIds` 属性测试**
  /// ---
  group('`latestMsgIds` 属性', () {
    test('空树返回自身 ID', () {
      expect(root.latestMsgIds, [0]);
    });

    test('单链消息列表', () {
      builder.buildLinearConversation(3, startId: 1); // 0->1->2->3->4->5->6
      expect(root.latestMsgIds, [0, 1, 2, 3, 4, 5, 6]);
    });

    test('编辑历史消息并创建新分支后，`latestMsgIds` 反映新分支', () {
      final nodes = builder.buildLinearConversation(2, startId: 1); // 0->1->2->3->4
      final botMsg0 = nodes[1]; // 这是节点 ID 2，其父节点是 ID 1

      botMsg0.add(MsgNode(5)); // botMsg0 (节点 2) 现在有一个新的最新子节点 (ID 5)
      // root.latest 是节点 1，节点 1 的 latest 是节点 2，节点 2 的 latest 是节点 5。
      expect(root.latestMsgIds, [0, 1, 2, 5]);
    });

    test('切换分支 (手动修改 parent.latest) 后 `latestMsgIds` 更新', () {
      final node1 = root.add(MsgNode(1));
      final node2 = node1.add(MsgNode(2)); // node1.latest = node2 (原始分支)
      node1.add(MsgNode(3)); // node1.latest = node3 (新分支)

      expect(root.latestMsgIds, [0, 1, 3], reason: "默认情况下应该遵循最新的分支");

      node1.latest = node2; // 手动将 node1 的 latest 切换回 node2
      expect(root.latestMsgIds, [0, 1, 2], reason: "应该遵循手动设置的 latest 分支");
    });
  });

  /// 🔄 **`wholeLatestMsgId` 和 `wholeLatestNode` 属性测试**
  /// ---
  group('`wholeLatestMsgId` 和 `wholeLatestNode` 属性', () {
    test('空树的 `wholeLatestMsgId` 是自身 ID', () {
      expect(root.wholeLatestMsgId, 0);
      expect(root.wholeLatestNode, root);
    });

    test('单链消息列表的 `wholeLatestMsgId`', () {
      builder.buildLinearConversation(3, startId: 1); // 结束于 ID 6
      expect(root.wholeLatestMsgId, 6);
      expect(root.wholeLatestNode.id, 6);
    });

    test('有分支时，`wholeLatestMsgId` 指向最新的分支的末端', () {
      final node1 = root.add(MsgNode(1));
      node1.add(MsgNode(2)); // 主分支: 0 -> 1 -> 2。root.latest=1, node1.latest=2

      final node3 = node1.add(MsgNode(3)); // 从 node1 分出的新分支: 0 -> 1 -> 3。node1.latest=3
      // root.latest 是 node1。node1.latest 是 node3。
      expect(root.wholeLatestMsgId, 3);
      expect(root.wholeLatestNode, node3);

      // 如果从 root 还有另一个分支
      final node4 = root.add(MsgNode(4)); // root.latest=4
      expect(root.wholeLatestMsgId, 4); // 现在整个树的最新节点是 node4
      expect(root.wholeLatestNode, node4);
    });
  });

  /// 🔍 **`findNodeByMsgId` 和 `findParentByMsgId` 测试**
  /// ---
  group('`findNodeByMsgId` 和 `findParentByMsgId`', () {
    setUp(() {
      // 结构:
      // 0
      // |- 1
      //    |- 2
      //    |- 3
      //       |- 4
      // |- 5
      final node1 = root.add(MsgNode(1));
      node1.add(MsgNode(2));
      final node3 = node1.add(MsgNode(3));
      node3.add(MsgNode(4));
      root.add(MsgNode(5));
    });

    test('可以找到存在的节点', () {
      expect(root.findNodeByMsgId(0)?.id, 0);
      expect(root.findNodeByMsgId(1)?.id, 1);
      expect(root.findNodeByMsgId(4)?.id, 4);
      expect(root.findNodeByMsgId(5)?.id, 5);
    });

    test('找不到不存在的节点时返回 null', () {
      expect(root.findNodeByMsgId(99), isNull);
    });

    test('可以找到节点的父节点', () {
      expect(root.findParentByMsgId(1)?.id, 0);
      expect(root.findParentByMsgId(4)?.id, 3);
      expect(root.findParentByMsgId(5)?.id, 0);
    });

    test('根节点的父节点为 null (通过查找方法)', () {
      // root.findNodeByMsgId(0) 是 root。root.parent 是 null。
      expect(root.findNodeByMsgId(0)?.parent, isNull);
      // findParentByMsgId(0) 会查找节点 0，然后获取其父节点。
      expect(root.findParentByMsgId(0), isNull);
    });

    test('查找不存在的节点的父节点返回 null', () {
      expect(root.findParentByMsgId(99), isNull);
    });
  });

  /// 🚶 **`msgIdsFrom` 方法测试**
  /// ---
  group('`msgIdsFrom` 方法', () {
    test('从指定节点追溯到根的 ID 列表', () {
      final node1 = root.add(MsgNode(1));
      final node2 = node1.add(MsgNode(2));
      final node3 = node2.add(MsgNode(3));

      // 预期顺序: [当前节点, 父节点, 祖父节点, ...]
      expect(root.msgIdsFrom(node3), [3, 2, 1, 0]);
      expect(root.msgIdsFrom(node1), [1, 0]);
      expect(root.msgIdsFrom(root), [0]);
    });

    test('从孤立节点（未添加到树）调用', () {
      final isolatedNode = MsgNode(100);
      // 假设 msgIdsFrom 是在某个可以访问此孤立节点的实例上调用，
      // 或者它是一个静态方法（它不是）。如果作为 isolatedNode.msgIdsFrom(isolatedNode) 调用：
      final tempRoot = MsgNode(99); // 仅用于调用实例方法
      expect(tempRoot.msgIdsFrom(isolatedNode), [100]);

      final childOfIsolated = MsgNode(101);
      childOfIsolated.parent = isolatedNode; // 手动链接
      expect(tempRoot.msgIdsFrom(childOfIsolated), [101, 100]);
    });
  });

  /// ⚠️ **边界条件和错误处理测试**
  /// ---
  group('边界条件和错误处理', () {
    test('在空消息树上操作', () {
      expect(root.latestMsgIds, [0]);
      expect(root.wholeLatestMsgId, 0);
      expect(root.findNodeByMsgId(0)?.id, 0);
      expect(root.findNodeByMsgId(1), isNull);
    });

    test('重复添加相同 ID 的子节点抛出 AssertionError (使用 add)', () {
      root.add(MsgNode(1));
      expect(
        () => root.add(MsgNode(1)),
        throwsA(isA<AssertionError>()),
        reason: '不应该允许通过 `add` 添加重复ID的消息',
      );
    });

    test('重复添加相同 ID 的子节点抛出 AssertionError (使用 rootAdd)', () {
      root.rootAdd(MsgNode(1)); // 假设此处 root 是 wholeLatestNode
      expect(
        () => root.rootAdd(MsgNode(1)),
        throwsA(isA<AssertionError>()),
        reason: '不应该允许通过 `rootAdd` 添加重复ID的消息到当前节点的 children',
      );
    });
  });

  /// 🧪 **原有消息树操作场景 (复核)**
  /// ---
  group('原有消息树操作场景 (复核)', () {
    test('链式调用构建消息树 (`add`)', () {
      root.add(MsgNode(1)).add(MsgNode(2)); // 用户消息，然后是机器人消息
      expect(root.latestMsgIds, [0, 1, 2]);
    });

    test('从原始测试 B 进行的随机测试，逐步验证 `add` 和 `latest` 更新', () {
      // 用户输入消息 0
      final userMsg0 = root.add(MsgNode(1)); // root.latest = 1
      expect(root.latestMsgIds, [0, 1]);
      expect(root.wholeLatestMsgId, 1);
      // 回复消息 0
      final botMsg0 = userMsg0.add(MsgNode(2)); // userMsg0.latest = 2
      expect(root.latestMsgIds, [0, 1, 2]);
      expect(root.wholeLatestMsgId, 2);

      // ... (继续你“随机测试 B”的逻辑)
      final userMsg1 = botMsg0.add(MsgNode(3)); // botMsg0.latest = 3
      final botMsg1 = userMsg1.add(MsgNode(4)); // userMsg1.latest = 4
      expect(root.latestMsgIds, [0, 1, 2, 3, 4]);

      // 编辑了用户消息 2 (原始测试暗示编辑会在 botMsg1 处创建新分支)
      // 你的原始“随机测试 B”实际上是通过向先前节点添加来测试分支。
      // “编辑用户消息 2” -> 假设这意味着向 botMsg1 (节点 4) 添加新的回复
      // 原始序列是: 0-1-2-3-4-5-6-7-8
      // 然后“编辑用户消息 1” (节点 3) 是节点 4 (botMsg1) 的父节点
      // 实际操作是: botMsg0.add(MsgNode(9)) -> userMsg4

      // 重现类似场景:
      // 原始线: 0 -> 1 -> 2 -> 3 -> 4
      // 此时，root.latest=1, 节点(1).latest=2, 节点(2).latest=3, 节点(3).latest=4

      // 用户通过从节点(2) (botMsg0) 分支进行“编辑”
      final userMsg4 = botMsg0.add(MsgNode(9)); // botMsg0.latest = 9。旧子节点(3)仍然存在。
      expect(root.latestMsgIds, [0, 1, 2, 9], reason: "路径应该跟随 botMsg0 的新 latest");
      expect(botMsg0.children.length, 2); // 节点(3) 和 节点(9)
      expect(botMsg0.latest?.id, 9);

      final botMsg4 = userMsg4.add(MsgNode(10)); // userMsg4.latest = 10
      expect(root.latestMsgIds, [0, 1, 2, 9, 10]);
      expect(root.wholeLatestMsgId, 10);

      // “通过点击第二个用户消息下方的切换按钮，切回了第一条线”
      // 这意味着 botMsg0.latest 被设置回节点(3)
      botMsg0.latest = userMsg1; // userMsg1 是节点(3)
      expect(root.latestMsgIds, [0, 1, 2, 3, 4], reason: "路径恢复到节点(4)之前的原始分支");
      expect(root.wholeLatestMsgId, 4);

      // 继续在此恢复的分支末端 (节点 4，即 botMsg1) 添加
      final _ = botMsg1.add(MsgNode(15));
      expect(root.latestMsgIds, [0, 1, 2, 3, 4, 15]);
      expect(root.wholeLatestMsgId, 15);
    });
  });
}
