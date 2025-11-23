enum BackendState {
  starting,
  running,
  stopping,
  stopped
  ;

  String get name => switch (this) {
    starting => "启动中",
    running => "运行中",
    stopping => "停止中",
    stopped => "已停止",
  };
}

