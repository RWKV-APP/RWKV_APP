import 'dart:convert';

// msg_node.dart
final class MsgNode {
  int id;
  List<MsgNode> children;

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
  }) : children = List<MsgNode>.empty(growable: true) {
    // Initialized here
    // If you intended to use the passed 'children' parameter, you'd do:
    // this.children = List<MsgNode>.from(children, growable: true);
    // But current logic replaces it, which is fine if intended.
  }

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

  MsgNode rootAdd(MsgNode child, {bool keepLatest = false}) {
    // Adds child to 'this.children', but parent is 'wholeLatestNode' of 'this'.
    // This can lead to child.parent.children not containing child if 'this' is not 'wholeLatestNode'.
    child.parent = wholeLatestNode;
    child.root = root ?? this; // root of 'this' node propagates
    if (children.map((e) => e.id).contains(child.id)) {
      // This checks 'this.children', not 'wholeLatestNode.children'
      throw AssertionError("child id ${child.id} already exists in current node $id for rootAdd");
    }
    wholeLatestNode.children.add(child); // Child added to 'this.children'
    if (!keepLatest) wholeLatestNode.latest = child; // 'this.latest' is updated
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

  List<int> get latestMsgIdsWithoutRoot {
    return latestMsgIds.where((e) => e != 0).toList();
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

  static MsgNode fromJson(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final int rootId = jsonMap['root_id'];
    final List<dynamic> nodeList = jsonMap['nodes'];

    final Map<int, MsgNode> nodesById = {};

    for (final nodeData in nodeList) {
      final int id = nodeData['id'];
      nodesById[id] = MsgNode(id);
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
