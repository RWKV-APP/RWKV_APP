enum BackendStatus {
  /// 初始化状态
  none,

  /// 正在创建 isolate
  creatingIsolate,

  /// 已经创建了 isolate, 但是尚未加载任何模型, 或者已经释放了所有已经加载过的模型
  ready,

  /// 已经加载模型, 但是没有任何正在进行推理任务
  load,

  /// 正在推理
  generating,
}
