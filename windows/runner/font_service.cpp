#include "font_service.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <gdiplus.h>
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <memory>

#pragma comment(lib, "gdiplus.lib")

using namespace Gdiplus;

// 初始化 GDI+
static ULONG_PTR gdiplusToken = 0;
static bool gdiplusInitialized = false;

void InitializeGdiPlus() {
  if (!gdiplusInitialized) {
    GdiplusStartupInput gdiplusStartupInput;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
    gdiplusInitialized = true;
  }
}

void ShutdownGdiPlus() {
  if (gdiplusInitialized) {
    GdiplusShutdown(gdiplusToken);
    gdiplusInitialized = false;
  }
}

// 检查字体是否为等宽字体
bool IsMonospaceFont(const std::wstring& fontName) {
  InitializeGdiPlus();
  
  HDC hdc = GetDC(NULL);
  if (hdc == NULL) {
    return false;
  }
  
  Graphics graphics(hdc);
  FontFamily fontFamily(fontName.c_str());
  
  if (!fontFamily.IsAvailable()) {
    ReleaseDC(NULL, hdc);
    return false;
  }
  
  // 创建字体实例
  Font font(&fontFamily, 12, FontStyleRegular, UnitPixel);
  if (font.GetLastStatus() != Ok) {
    ReleaseDC(NULL, hdc);
    return false;
  }
  
  // 测量字符宽度
  RectF rect1, rect2;
  StringFormat format;
  
  // 测量 'i' 和 'W' 的宽度
  graphics.MeasureString(L"i", 1, &font, PointF(0, 0), &format, &rect1);
  graphics.MeasureString(L"W", 1, &font, PointF(0, 0), &format, &rect2);
  
  ReleaseDC(NULL, hdc);
  
  // 如果宽度相同或非常接近，则认为是等宽字体
  float diff = std::abs(rect1.Width - rect2.Width);
  return diff < 0.5f;
}

// 从字体名称推断是否为等宽字体（后备方案）
bool InferMonospaceFromName(const std::wstring& fontName) {
  std::wstring lowerName = fontName;
  std::transform(lowerName.begin(), lowerName.end(), lowerName.begin(), ::towlower);
  
  return lowerName.find(L"mono") != std::wstring::npos ||
         lowerName.find(L"courier") != std::wstring::npos ||
         lowerName == L"monospace" ||
         lowerName.find(L"console") != std::wstring::npos ||
         lowerName.find(L"terminal") != std::wstring::npos ||
         lowerName.find(L"code") != std::wstring::npos ||
         lowerName.find(L"menlo") != std::wstring::npos ||
         lowerName.find(L"consolas") != std::wstring::npos ||
         lowerName.find(L"source code") != std::wstring::npos ||
         lowerName.find(L"fira code") != std::wstring::npos ||
         lowerName.find(L"jetbrains mono") != std::wstring::npos ||
         lowerName.find(L"sarasa") != std::wstring::npos;
}

// 获取系统字体列表
std::vector<std::map<std::string, flutter::EncodableValue>> GetSystemFonts() {
  InitializeGdiPlus();
  
  std::vector<std::map<std::string, flutter::EncodableValue>> fontList;
  std::set<std::wstring> processedFonts;
  
  // 获取所有已安装的字体族
  InstalledFontCollection installedFonts;
  int fontCount = installedFonts.GetFamilyCount();
  
  if (fontCount > 0) {
    // 分配足够的空间来存储字体族
    FontFamily* fontFamilies = new FontFamily[fontCount];
    int actualCount = 0;
    Status status = installedFonts.GetFamilies(fontCount, fontFamilies, &actualCount);
    
    if (status == Ok && actualCount > 0) {
      for (int i = 0; i < actualCount; i++) {
        FontFamily& fontFamily = fontFamilies[i];
        
        WCHAR familyName[LF_FACESIZE];
        if (fontFamily.GetFamilyName(familyName) != Ok) {
          continue;
        }
        std::wstring familyNameStr(familyName);
        
        // 首先添加字体族名本身
        if (processedFonts.find(familyNameStr) == processedFonts.end()) {
          processedFonts.insert(familyNameStr);
          
          // 尝试检测是否为等宽字体（使用族名）
          bool isMonospace = false;
          try {
            // 先尝试使用族名检测
            isMonospace = IsMonospaceFont(familyNameStr);
          } catch (...) {
            // 如果检测失败，使用名称推断
            isMonospace = InferMonospaceFromName(familyNameStr);
          }
          
          // 如果检测失败，使用名称推断
          if (!isMonospace) {
            isMonospace = InferMonospaceFromName(familyNameStr);
          }
          
          int size_needed = WideCharToMultiByte(CP_UTF8, 0, familyNameStr.c_str(), -1, NULL, 0, NULL, NULL);
          if (size_needed > 0) {
            std::string familyNameUtf8(size_needed, 0);
            WideCharToMultiByte(CP_UTF8, 0, familyNameStr.c_str(), -1, &familyNameUtf8[0], size_needed, NULL, NULL);
            familyNameUtf8.resize(size_needed - 1);
            
            std::map<std::string, flutter::EncodableValue> fontInfo;
            fontInfo["name"] = familyNameUtf8;
            fontInfo["isMonospace"] = isMonospace;
            fontList.push_back(fontInfo);
          }
        }
      }
    }
    
    delete[] fontFamilies;
  }
  
  return fontList;
}

// 静态变量保持通道存活
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_font_channel;

// 设置字体方法通道
void SetupFontChannel(flutter::FlutterEngine* engine) {
  const static std::string channel_name("com.rwkvzone.chat/fonts");
  g_font_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), channel_name,
      &flutter::StandardMethodCodec::GetInstance());
  
  g_font_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getSystemFonts") {
          try {
            auto fonts = GetSystemFonts();
            flutter::EncodableList fontList;
            for (const auto& font : fonts) {
              flutter::EncodableMap fontMap;
              for (const auto& pair : font) {
                fontMap[flutter::EncodableValue(pair.first)] = pair.second;
              }
              fontList.push_back(flutter::EncodableValue(fontMap));
            }
            result->Success(flutter::EncodableValue(fontList));
          } catch (const std::exception& e) {
            result->Error("ERROR", "Failed to get system fonts: " + std::string(e.what()));
          }
        } else {
          result->NotImplemented();
        }
      });
}
