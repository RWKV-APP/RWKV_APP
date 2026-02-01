extension NumExtension on num {
  /// 返回在 [toInt()] 毫秒后完成的 Future，小数部分会被截断。
  Future get msLater => Future.delayed(Duration(milliseconds: toInt()));
}
