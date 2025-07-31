import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// 生成版本号图片
///
/// 创建一个图片，图片的内容是 "RWKV Chat 1.8.0 (440)"
///
/// 白底黑字，或者黑底白字，图片的尺寸为，1000 * 400
///
/// 生成的黑底白字图片覆盖：assets/design/dark/branding.png
///
/// 生成的白底黑字图片覆盖：assets/design/light/branding.png
Future<File?> gen() async {
  try {
    // 从主项目的pubspec.yaml读取版本信息
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      print('错误：找不到 pubspec.yaml 文件');
      return null;
    }

    final pubspecContent = await pubspecFile.readAsString();
    final versionLine = pubspecContent.split('\n').firstWhere((line) => line.trim().startsWith('version:'));

    final versionString = versionLine.split('version:')[1].trim();
    final versionParts = versionString.split('+');
    final version = versionParts[0]; // 例如 "1.8.1"
    final buildNumber = versionParts[1]; // 例如 "439"

    final text = "RWKV Chat $version ($buildNumber)";

    // 创建输出目录
    final outputDir = Directory('tools/output');
    if (!await outputDir.exists()) {
      await outputDir.create();
    }

    // 生成白底黑字版本
    final lightImage = await _createImage(text, isLight: true);
    final lightFile = File(path.join(outputDir.path, 'version_light.png'));
    await lightFile.writeAsBytes(img.encodePng(lightImage));
    print('生成白底黑字版本: ${lightFile.path}');

    // 生成黑底白字版本
    final darkImage = await _createImage(text, isLight: false);
    final darkFile = File(path.join(outputDir.path, 'version_dark.png'));
    await darkFile.writeAsBytes(img.encodePng(darkImage));
    print('生成黑底白字版本: ${darkFile.path}');

    // 复制到目标位置
    await _copyToTarget(lightFile, 'assets/design/light/branding.png');
    await _copyToTarget(darkFile, 'assets/design/dark/branding.png');

    return lightFile; // 返回白底黑字版本作为默认
  } catch (e) {
    print('生成版本号图片时出错: $e');
    return null;
  }
}

/// 创建图片
Future<img.Image> _createImage(String text, {required bool isLight}) async {
  const width = 750;
  const height = 300;

  // 创建画布
  final image = img.Image(width: width, height: height);

  // 设置背景色
  final bgColor = isLight ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
  img.fill(image, color: bgColor);

  // 设置文字颜色
  final textColor = isLight ? img.ColorRgb8(100, 100, 100) : img.ColorRgb8(155, 155, 155);

  // 计算文字位置（居中）
  // 由于image包的drawString功能有限，我们使用简单的字符绘制
  // 这里使用一个近似的方法来居中文字
  const fontSize = 48; // 增大字体以适应更大的画布
  final textWidth = text.length * fontSize * 0.48; // 近似字符宽度
  final startX = ((width - textWidth) / 2).round();
  final startY = ((height - fontSize) / 2).round() + 70;

  // 绘制文字（使用内置字体）
  img.drawString(
    image,
    text,
    font: img.arial48,
    x: startX,
    y: startY,
    color: textColor,
  );

  return image;
}

/// 复制文件到目标位置
Future<void> _copyToTarget(File sourceFile, String targetPath) async {
  try {
    final targetFile = File(targetPath);

    // 确保目标目录存在
    final targetDir = Directory(path.dirname(targetPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 复制文件
    await sourceFile.copy(targetPath);
    print('已复制到: $targetPath');
  } catch (e) {
    print('复制文件到 $targetPath 时出错: $e');
  }
}
