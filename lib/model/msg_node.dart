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
}
