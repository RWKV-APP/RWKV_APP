import 'package:zone/gen/l10n.dart';

/// 项目中展示「文件/磁盘/内存占用」尺寸的统一入口。
///
/// 渲染决策堆栈（按命中顺序）：
/// 1) `bytes <= 0`
///    - 输出：`0 GB`
/// 2) `0 < bytes < 0.01 GB`
///    - 输出：`S.current.less_than_01_gb`（如 `< 0.01 GB`）
/// 3) `bytes >= 0.01 GB`
///    - 输出：统一 GB；四舍五入到两位小数；固定保留两位（如 `1.00 GB`、`1.20 GB`）
///
/// 全量 case（给产品/CTO 对齐时可直接引用）：
/// - `0 B` -> `0 GB`
/// - `1 B` -> `< 0.01 GB`
/// - `1 MB` (`1,048,576 B`) -> `< 0.01 GB`
/// - `10 MB` (`10,485,760 B`) -> `< 0.01 GB`
/// - `10,737,418 B`（0.01 GB 的显示阈值）-> `0.01 GB`
/// - `512 MB` (`536,870,912 B`) -> `0.50 GB`
/// - `1 GB` (`1,073,741,824 B`) -> `1.00 GB`
/// - `1.234 GB` -> `1.23 GB`
/// - `1.235 GB` -> `1.24 GB`
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return "0 GB";
  }

  const int bytesPerGB = 1024 * 1024 * 1024;

  /// 0.01 GB in bytes
  const int threshold01Gb = 10737418;

  if (bytes < threshold01Gb) {
    return S.current.less_than_01_gb;
  }

  final int centiGb = ((bytes * 100) + (bytesPerGB ~/ 2)) ~/ bytesPerGB;
  final int gbInteger = centiGb ~/ 100;
  final int gbDecimal = centiGb % 100;
  final String gbDecimalText = gbDecimal < 10 ? "0$gbDecimal" : "$gbDecimal";
  return "$gbInteger.$gbDecimalText GB";
}
