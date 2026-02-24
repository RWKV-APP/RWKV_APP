/// 项目中展示「文件/磁盘/内存占用」尺寸的统一入口。
///
/// 渲染决策堆栈（按命中顺序）：
///
/// 1) `0 ≤ bytes ≤ 0.0.1GB`
///    - 输出：`0.01GB`
/// 2) `bytes >= 0.01 GB`
///    - 输出：统一 GB；四舍五入到两位小数；固定保留两位（如 `1.00 GB`、`1.20 GB`）
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return "0.01 GB";
  }

  const int bytesPerGB = 1024 * 1024 * 1024;

  /// 0.01 GB in bytes
  const int threshold01Gb = 10737418;

  if (bytes < threshold01Gb) {
    return "0.01 GB";
  }

  final int centiGb = ((bytes * 100) + (bytesPerGB ~/ 2)) ~/ bytesPerGB;
  final int gbInteger = centiGb ~/ 100;
  final int gbDecimal = centiGb % 100;
  final String gbDecimalText = gbDecimal < 10 ? "0$gbDecimal" : "$gbDecimal";
  return "$gbInteger.$gbDecimalText GB";
}
