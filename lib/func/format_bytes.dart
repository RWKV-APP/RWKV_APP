import 'package:zone/gen/l10n.dart';

/// 项目中展示「文件/磁盘/内存占用」尺寸的统一入口。
///
/// 全部以 GB 展示；四舍五入，最多两位小数（.00 不显示；末尾 0 不显示，如 0.4 而非 0.40）。
/// 当尺寸小于 0.01 GB 时，返回当前语言的「小于 0.01 GB」提示。
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
  if (gbDecimal == 0) {
    return "$gbInteger GB";
  }
  // 去掉小数末尾的 0：0.40 → 0.4，2.50 → 2.5
  if (gbDecimal % 10 == 0) {
    return "$gbInteger.${gbDecimal ~/ 10} GB";
  }
  final String gbDecimalText = gbDecimal < 10 ? "0$gbDecimal" : "$gbDecimal";
  return "$gbInteger.$gbDecimalText GB";
}
