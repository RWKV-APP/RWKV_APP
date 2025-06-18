import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tools/gen_version_string_img.dart';

void main(List<String> arguments) async {
  final file = await gen();
  if (file != null) {
    print('版本号图片生成成功: ${file.path}');
  } else {
    print('版本号图片生成失败');
  }

  // // 调用黑色像素转透明的函数

  // final white = img.ColorRgba8(255, 255, 255, 255);
  // final black = img.ColorRgba8(0, 0, 0, 255);

  // // print(Directory.current.path);
  // // return;

  // f1('../assets/design/light/icon/chat.png', size: 960, color: white, outputPath: '../assets/design/light/splash/chat.png');
  // f1('../assets/design/dark/icon/chat.png', size: 960, color: black, outputPath: '../assets/design/dark/splash/chat.png');
  // f1('../assets/design/light/icon/chat.png', size: 960, color: white, outputPath: '../assets/design/light/splash/chat.png');
  // f1('../assets/design/dark/icon/chat.png', size: 960, color: black, outputPath: '../assets/design/dark/splash/chat.png');
  // f1('../assets/design/light/icon/chat.png', size: 960, color: white, outputPath: '../assets/design/light/splash/chat.png');
  // f1('../assets/design/dark/icon/chat.png', size: 960, color: black, outputPath: '../assets/design/dark/splash/chat.png');
  // f1('../assets/design/light/icon/chat.png', size: 960, color: white, outputPath: '../assets/design/light/splash/chat.png');
  // f1('../assets/design/dark/icon/chat.png', size: 960, color: black, outputPath: '../assets/design/dark/splash/chat.png');
  // f1('../assets/design/light/icon/chat.png', size: 960, color: white, outputPath: '../assets/design/light/splash/chat.png');
  // f1('../assets/design/dark/icon/chat.png', size: 960, color: black, outputPath: '../assets/design/dark/splash/chat.png');
}

/// 将一张图片的尺寸改为 960 * 960
///
/// 1. 首先将图片缩小为 800 * 800
/// 2. 然后在四周添加上宽度为 160 * 160 的边框，边框颜色为指定颜色
/// 3. 比如原先的文件名为 file.png，将新生成的文件命名为 file.android.splash.png
void f1(
  String inputPath, {
  required String outputPath,
  int size = 960,
  required img.Color color,
}) {
  final imageFile = File(inputPath);

  if (!imageFile.existsSync()) {
    print('错误: 图片文件不存在: ${imageFile.path}');
    return;
  }

  try {
    // 读取图片文件
    final Uint8List imageBytes = imageFile.readAsBytesSync();

    // 解码图片
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      print('错误: 无法解码图片文件');
      return;
    }

    // 步骤1: 将图片缩小为 800 x 800
    final int innerSize = (size * 0.833).round(); // 800 for 960, maintains ratio
    img.Image resizedImage = img.copyResize(
      image,
      width: innerSize,
      height: innerSize,
      interpolation: img.Interpolation.linear,
    );

    // 步骤2: 创建一个 960x960 的画布，用指定颜色填充
    img.Image canvas = img.Image(
      width: size,
      height: size,
      numChannels: 4, // RGBA
    );

    // 用指定颜色填充整个画布
    img.fill(canvas, color: color);

    // 步骤3: 将800x800的图片居中放置在960x960的画布上
    final int offsetX = (size - innerSize) ~/ 2; // 80 pixels on each side
    final int offsetY = (size - innerSize) ~/ 2; // 80 pixels on top and bottom

    img.compositeImage(
      canvas,
      resizedImage,
      dstX: offsetX,
      dstY: offsetY,
    );

    // 编码为PNG格式
    final Uint8List finalImageBytes = img.encodePng(canvas);

    // 保存调整后的图片
    final File outputFile = File(outputPath);
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsBytesSync(finalImageBytes);

    print('成功处理图片: ${imageFile.path}');
    print('输出文件: $outputPath');
    print('图片已调整为 ${innerSize}x$innerSize 像素，添加了 ${(size - innerSize) ~/ 2} 像素边框，总尺寸 $size x $size 像素');
  } catch (e) {
    print('处理图片时发生错误: $e');
  }
}
