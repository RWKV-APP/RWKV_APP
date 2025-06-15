import 'dart:convert';

import 'package:halo/halo.dart';

// msg_node.dart
final class MsgNode {
  /// 所代表的 Message 的 ID
  int id;
  List<MsgNode> children;

  /// 创建时间, 单位: 微秒
  late final int createAtInUS;

  String? title;

  /// 当前节点, 最新的子节点
  MsgNode? latest;
  MsgNode? parent;
  MsgNode? root;

  MsgNode(
    this.id, {
    List<MsgNode> children = const [], // Default value
    this.latest,
    this.parent,
    this.root,
    int? createAtInUS,
  }) : children = List<MsgNode>.empty(growable: true) {
    this.createAtInUS = createAtInUS ?? HF.microseconds;
    // Initialized here
    // If you intended to use the passed 'children' parameter, you'd do:
    // this.children = List<MsgNode>.from(children, growable: true);
    // But current logic replaces it, which is fine if intended.
  }

  /// 在当前节点添加 Node
  MsgNode add(MsgNode child, {bool keepLatest = false}) {
    child.parent = this;
    child.root = root ?? this;
    if (children.map((e) => e.id).contains(child.id)) {
      throw AssertionError("child id ${child.id} already exists in parent $id");
    }
    children.add(child);
    if (!keepLatest) latest = child;
    return child;
  }

  /// 直接在整个消息树的最新节点添加 Node, 不考虑当前节点
  MsgNode rootAdd(MsgNode child, {bool keepLatest = false}) {
    child.parent = wholeLatestNode;
    if (children.map((e) => e.id).contains(child.id)) {
      throw AssertionError("child id ${child.id} already exists in current node $id for rootAdd");
    }
    wholeLatestNode.children.add(child);
    if (!keepLatest) wholeLatestNode.latest = child;
    return child;
  }

  MsgNode? findNodeByMsgId(int msgId) {
    if (id == msgId) return this; // Check current node first
    return (root ?? this).findInChildren(msgId);
  }

  MsgNode? findParentByMsgId(int msgId) {
    return (root ?? this).findInChildren(msgId)?.parent;
  }

  MsgNode? findInChildren(int msgId) {
    // Removed print statement:
    // print("findInChildren: $msgId, children: ${children.map((e) => e.id).join(", ")}");
    for (final child in children) {
      if (child.id == msgId) return child;
      final res = child.findInChildren(msgId);
      if (res != null) return res;
    }
    return null;
  }

  List<int> msgIdsFrom(MsgNode node) {
    final msgIds = <int>[];
    MsgNode? current = node; // Start from the given node
    while (current != null) {
      msgIds.add(current.id);
      current = current.parent;
    }
    return msgIds; // Order will be from node up to its root-most ancestor in this path
  }

  List<int> get latestMsgIds {
    final msgIds = <int>[];
    // Correctly starts from 'this' node if 'this' is root and its 'root' field is null.
    MsgNode? current = (root?.latest) ?? this;
    while (current != null) {
      msgIds.add(current.id);
      current = current.latest;
    }
    return msgIds;
  }

  bool get isEmpty => id == 0 && children.isEmpty;

  List<int> get latestMsgIdsWithoutRoot {
    return latestMsgIds.where((e) => e != 0).toList();
  }

  /// 从根节点获取全部的消息列表，排除 id 为 0 的根节点
  Set<int> get allMsgIdsFromRoot {
    final rootNode = root ?? this;
    final allNodes = rootNode._getAllNodes();
    return allNodes.where((node) => node.id != 0).map((node) => node.id).toSet();
  }

  int get wholeLatestMsgId {
    // Changed to non-nullable as wholeLatestNode ensures a node.
    return wholeLatestNode.id;
  }

  /// 当前消息树, 最后一次被添加消息的节点
  MsgNode get wholeLatestNode {
    MsgNode current = root ?? this; // Start from root, or this if no root.
    while (current.latest != null) {
      current = current.latest!;
    }
    return current;
  }

  @override
  String toString() {
    return "MsgNode(id: $id, children ids: [${children.map((e) => e.id).join(", ")}], latest: ${latest?.id}, root: ${root?.id})";
  }

  // 为 MsgNode 设计序列化和反序列化方法
  // 使用字符串序列化, 要求不要丢失关键数据, 不要修改已经存在的 toString 方法
  // 直接序列化为 JSON String, 反序列化也可以直接从 JSON String 中拿到

  List<MsgNode> _getAllNodes() {
    final nodes = <MsgNode>[];
    final queue = <MsgNode>[this];
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current.id)) continue;
      visited.add(current.id);
      nodes.add(current);
      queue.addAll(current.children);
    }
    return nodes;
  }

  String toJson() {
    final rootNode = root ?? this;
    if (rootNode != this) {
      return rootNode.toJson();
    }

    final allNodes = _getAllNodes();
    final List<Map<String, dynamic>> nodeList = allNodes.map((node) {
      return {
        'id': node.id,
        'children_ids': node.children.map((c) => c.id).toList(),
        'latest_id': node.latest?.id,
      };
    }).toList();

    final Map<String, dynamic> jsonMap = {
      'root_id': rootNode.id,
      'nodes': nodeList,
    };

    return jsonEncode(jsonMap);
  }

  static MsgNode fromJson(String jsonString, {int? createAtInUS}) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final int rootId = jsonMap['root_id'];
    final List<dynamic> nodeList = jsonMap['nodes'];

    final Map<int, MsgNode> nodesById = {};

    for (final nodeData in nodeList) {
      final int id = nodeData['id'];
      nodesById[id] = MsgNode(id, createAtInUS: createAtInUS);
    }

    for (final nodeData in nodeList) {
      final int id = nodeData['id'];
      final currentNode = nodesById[id]!;
      final List<dynamic> childrenIds = nodeData['children_ids'] ?? [];
      final int? latestId = nodeData['latest_id'];

      for (final childId in childrenIds) {
        final childNode = nodesById[childId]!;
        currentNode.children.add(childNode);
        childNode.parent = currentNode;
      }

      if (latestId != null && nodesById.containsKey(latestId)) {
        currentNode.latest = nodesById[latestId];
      }
    }

    final rootNode = nodesById[rootId]!;

    for (final node in nodesById.values) {
      if (node != rootNode) {
        node.root = rootNode;
      }
    }

    return rootNode;
  }
}
