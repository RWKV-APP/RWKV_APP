#ifndef RUNNER_FONT_SERVICE_H_
#define RUNNER_FONT_SERVICE_H_

#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>
#include <vector>
#include <map>

// 初始化 GDI+
void InitializeGdiPlus();

// 关闭 GDI+
void ShutdownGdiPlus();

// 获取系统字体列表
std::vector<std::map<std::string, flutter::EncodableValue>> GetSystemFonts();

// 设置字体方法通道
void SetupFontChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_FONT_SERVICE_H_
