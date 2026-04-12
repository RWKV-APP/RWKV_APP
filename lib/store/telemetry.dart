part of 'p.dart';

const String _telemetryEnabledKey = "halo_state.telemetry.enabled";
const String _telemetryInstallIdKey = "halo_state.telemetry.installId";

class _Telemetry {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final enabled = qs<bool>(true);
  late final _installId = qs<String>("");
  late final _deviceModel = qs<String>("");
  late final _macChipName = qs<String>("");
  late final _gpuName = qs<String>("");
  late final _totalMemoryMb = qs<int>(0);
  late final _totalVramMb = qs<int>(0);
  late final _peakDecodeSpeed = qs<double>(0);
}

/// Public methods
extension $Telemetry on _Telemetry {
  Future<void> setEnabled(bool value) async {
    enabled.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_telemetryEnabledKey, value);
  }

  void trackDecodeSpeed(double speed) {
    if (speed > _peakDecodeSpeed.q) {
      _peakDecodeSpeed.q = speed;
    }
  }

  void resetPeakDecodeSpeed() {
    _peakDecodeSpeed.q = 0;
  }

  /// [snapshotPeakDecodeSpeed] 必须在调用侧提前快照，避免被后续
  /// _prefillAfterReply → resetPeakDecodeSpeed 清零
  Future<void> maybeReport({
    required double? prefillSpeed,
    required double? decodeSpeed,
    required double snapshotPeakDecodeSpeed,
  }) async {
    try {
      if (!enabled.q) return;
      if (prefillSpeed == null || prefillSpeed <= 0) return;
      if (decodeSpeed == null || decodeSpeed <= 0) return;

      final FileInfo? model = P.rwkv.latestModel.q;
      if (model == null) return;

      // sha256 可能为空（部分权重没有），用 fileName 兜底
      final String modelId = (model.sha256 != null && model.sha256!.isNotEmpty) ? model.sha256! : model.fileName;
      if (modelId.isEmpty) return;

      // socName: 优先 native → frontendSocName → macChipName → deviceModel → platform
      String socName = P.rwkv.socName.q;
      if (socName.isEmpty || socName.toLowerCase() == "unknown") {
        socName = P.rwkv.frontendSocName.q ?? "";
      }
      if (socName.isEmpty || socName.toLowerCase() == "unknown") {
        socName = _macChipName.q;
      }
      if (socName.isEmpty || socName.toLowerCase() == "unknown") {
        socName = _gpuName.q;
      }
      if (socName.isEmpty || socName.toLowerCase() == "unknown") {
        socName = _deviceModel.q;
      }
      if (socName.isEmpty || socName.toLowerCase() == "unknown") {
        socName = Platform.operatingSystem;
      }

      final String backendName = model.backend?.name ?? "";
      if (backendName.isEmpty) return;

      final bool isBatch = P.chat.effectiveBatchEnabled.q;
      final int batchCount = isBatch ? P.chat.effectiveBatchCount.q : 1;

      // batch 模式使用整轮推理中的峰值 decode speed
      final double effectiveDecodeSpeed = (batchCount > 1 && snapshotPeakDecodeSpeed > 0) ? snapshotPeakDecodeSpeed : decodeSpeed;
      if (kDebugMode) {
        qqq("telemetry: batchEnabled=$isBatch batchCount=$batchCount peak=$snapshotPeakDecodeSpeed passed=$decodeSpeed → effective=$effectiveDecodeSpeed");
      }

      // socBrand
      String socBrandName = P.rwkv.socBrand.q != SocBrand.unknown
          ? P.rwkv.socBrand.q.name
          : (P.rwkv.frontendSocBrand.q?.name ?? "unknown");
      if (socBrandName == "unknown" && Platform.isMacOS) {
        socBrandName = "apple";
      }
      // 从 GPU 名称推断 socBrand
      if (socBrandName == "unknown" && _gpuName.q.isNotEmpty) {
        final String gpuLower = _gpuName.q.toLowerCase();
        if (gpuLower.contains("nvidia")) {
          socBrandName = "nvidia";
        } else if (gpuLower.contains("radeon") || gpuLower.contains("amd")) {
          socBrandName = "amd";
        } else if (gpuLower.contains("intel")) {
          socBrandName = "intel";
        }
      }

      final int now = DateTime.now().millisecondsSinceEpoch;

      final Map<String, dynamic> body = {
        "schemaVersion": 1,
        "installId": _installId.q,
        "device": {
          "socName": socName,
          "socBrand": socBrandName,
          "os": Platform.operatingSystem,
          "osVersion": _stripOsVersion(P.app.osVersion.q),
          "deviceModel": _deviceModel.q,
          "totalMemoryMb": _totalMemoryMb.q > 0 ? _totalMemoryMb.q : null,
          "totalVramMb": _totalVramMb.q > 0 ? _totalVramMb.q : null,
        },
        "app": {
          "version": P.app.version.q,
          "build": P.app.buildNumber.q,
        },
        "model": {
          "name": model.name,
          "fileName": model.fileName,
          "sha256": modelId,
          "sizeB": model.modelSize,
          "quantization": model.quantization,
          "backend": backendName,
        },
        "perf": {
          "prefillSpeed": prefillSpeed,
          "decodeSpeed": effectiveDecodeSpeed,
          "isBatch": isBatch,
          "batchCount": batchCount,
        },
        "clientTimestamp": now,
      };

      await _upload(body);
    } catch (e) {
      if (kDebugMode) qqw("telemetry.maybeReport error: $e");
    }
  }
}

/// Private methods
extension _$Telemetry on _Telemetry {
  Future<void> _init() async {
    final sp = await SharedPreferences.getInstance();

    // enabled
    final bool? savedEnabled = sp.getBool(_telemetryEnabledKey);
    if (savedEnabled != null) {
      enabled.q = savedEnabled;
    }

    // installId
    String savedId = sp.getString(_telemetryInstallIdKey) ?? "";
    if (savedId.isEmpty) {
      savedId = _generateUuidV4();
      await sp.setString(_telemetryInstallIdKey, savedId);
    }
    _installId.q = savedId;

    // 设备型号
    await _initDeviceModel();

    // macOS 芯片名称 (e.g. "Apple M4 Pro")
    await _initMacChipName();

    // Windows / Linux GPU 名称 (e.g. "NVIDIA GeForce RTX 3080")
    await _initGpuName();

    // 总物理内存
    await _initTotalMemory();

    // VRAM (Windows / Linux 独显显存)
    await _initVram();
  }

  Future<void> _initDeviceModel() async {
    try {
      if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        _deviceModel.q = info.utsname.machine;
      } else if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _deviceModel.q = info.model;
      } else if (Platform.isMacOS) {
        final info = await DeviceInfoPlugin().macOsInfo;
        _deviceModel.q = info.model;
      } else if (Platform.isWindows) {
        final info = await DeviceInfoPlugin().windowsInfo;
        _deviceModel.q = info.productName;
      } else if (Platform.isLinux) {
        final info = await DeviceInfoPlugin().linuxInfo;
        _deviceModel.q = info.prettyName;
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get device model: $e");
    }
  }

  Future<void> _initMacChipName() async {
    if (!Platform.isMacOS) return;
    try {
      final ProcessResult result = await Process.run("sysctl", ["-n", "machdep.cpu.brand_string"]);
      final String chip = (result.stdout as String).trim();
      if (chip.isNotEmpty) {
        _macChipName.q = chip;
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get mac chip name: $e");
    }
  }

  Future<void> _initGpuName() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    try {
      if (Platform.isWindows) {
        // wmic: 兼容 Windows 10 PowerShell 5.1，无需高版本语法
        final ProcessResult result = await Process.run("cmd", [
          "/c",
          "wmic path win32_videocontroller get name /value",
        ]);
        final String output = (result.stdout as String).trim();
        // 输出格式: Name=NVIDIA GeForce RTX 3080\r\nName=Intel UHD ...
        // 优先选独显（NVIDIA / AMD / Radeon），排除集显
        String bestGpu = "";
        for (final line in output.split(RegExp(r'[\r\n]+'))) {
          final trimmed = line.trim();
          if (!trimmed.startsWith("Name=")) continue;
          final name = trimmed.substring(5).trim();
          if (name.isEmpty) continue;
          if (bestGpu.isEmpty) bestGpu = name;
          final lower = name.toLowerCase();
          if (lower.contains("nvidia") || lower.contains("radeon") || lower.contains("amd")) {
            bestGpu = name;
            break;
          }
        }
        if (bestGpu.isNotEmpty) {
          _gpuName.q = _stripGpuPrefix(bestGpu);
          if (kDebugMode) qqq("telemetry: detected GPU: ${_gpuName.q}");
        }
      } else if (Platform.isLinux) {
        // lspci: 找 VGA / 3D controller
        final ProcessResult result = await Process.run("bash", [
          "-c",
          "lspci | grep -iE 'VGA|3D' | head -1 | sed 's/.*: //'",
        ]);
        final String gpu = (result.stdout as String).trim();
        if (gpu.isNotEmpty) {
          _gpuName.q = _stripGpuPrefix(gpu);
          if (kDebugMode) qqq("telemetry: detected GPU: ${_gpuName.q}");
        }
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get GPU name: $e");
    }
  }

  /// 去掉冗余品牌前缀：
  /// "NVIDIA GeForce RTX 3080" → "RTX 3080"
  /// "AMD Radeon RX 7900 XTX" → "RX 7900 XTX"
  String _stripGpuPrefix(String name) {
    String stripped = name;
    // 依次移除品牌关键词
    for (final String prefix in ["NVIDIA", "GeForce", "AMD", "Radeon"]) {
      stripped = stripped.replaceFirst(RegExp('^$prefix\\s*', caseSensitive: false), '');
    }
    return stripped.trim().isEmpty ? name : stripped.trim();
  }

  Future<void> _initTotalMemory() async {
    try {
      if (Platform.isIOS) {
        final result = await P.adapter.call(ToNative.checkMemory);
        if (result != null) {
          final int used = result[0];
          final int free = result[1];
          _totalMemoryMb.q = (used + free) ~/ (1024 * 1024);
        }
      } else if (Platform.isMacOS) {
        // sysctl hw.memsize 返回字节数，比 SysInfo 更可靠
        final ProcessResult result = await Process.run("sysctl", ["-n", "hw.memsize"]);
        final String output = (result.stdout as String).trim();
        final int? bytes = int.tryParse(output);
        if (bytes != null && bytes > 0) {
          _totalMemoryMb.q = bytes ~/ (1024 * 1024);
        }
      } else {
        final int total = SysInfo.getTotalPhysicalMemory();
        _totalMemoryMb.q = total ~/ (1024 * 1024);
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get total memory: $e");
    }
  }

  Future<void> _initVram() async {
    // macOS 上内存统一共享，不区分 VRAM
    if (!Platform.isWindows && !Platform.isLinux) return;
    try {
      // Windows 和 Linux 都优先用 nvidia-smi（wmic AdapterRAM 是 DWORD 32 位，>4GB 溢出）
      final ProcessResult smiResult = Platform.isWindows
          ? await Process.run("cmd", ["/c", "nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>nul"])
          : await Process.run("bash", ["-c", "nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1"]);
      final String smiOutput = (smiResult.stdout as String).trim();
      // nvidia-smi 可能返回多行（多 GPU），取第一行
      final String firstLine = smiOutput.split(RegExp(r'[\r\n]+')).first.trim();
      final int? vramMb = int.tryParse(firstLine);
      if (vramMb != null && vramMb > 0) {
        _totalVramMb.q = vramMb;
        if (kDebugMode) qqq("telemetry: detected VRAM via nvidia-smi: $vramMb MB");
        return;
      }

      // nvidia-smi 失败时 Windows 回退到 wmic（仅对 ≤4GB 显卡准确）
      if (Platform.isWindows) {
        final ProcessResult wmicResult = await Process.run("cmd", [
          "/c",
          "wmic path win32_videocontroller get AdapterRAM,Name /value",
        ]);
        final String output = (wmicResult.stdout as String).trim();
        int bestVram = 0;
        int currentRam = 0;
        String currentName = "";
        for (final line in output.split(RegExp(r'[\r\n]+'))) {
          final trimmed = line.trim();
          if (trimmed.startsWith("AdapterRAM=")) {
            currentRam = int.tryParse(trimmed.substring(11).trim()) ?? 0;
          } else if (trimmed.startsWith("Name=")) {
            currentName = trimmed.substring(5).trim();
            if (currentRam > 0) {
              final lower = currentName.toLowerCase();
              if (lower.contains("nvidia") || lower.contains("radeon") || lower.contains("amd")) {
                bestVram = currentRam;
              } else if (bestVram == 0) {
                bestVram = currentRam;
              }
            }
            currentRam = 0;
            currentName = "";
          }
        }
        if (bestVram > 0) {
          _totalVramMb.q = bestVram ~/ (1024 * 1024);
          if (kDebugMode) qqq("telemetry: detected VRAM via wmic (fallback): ${_totalVramMb.q} MB");
        }
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get VRAM: $e");
    }
  }

  Future<void> _upload(Map<String, dynamic> body) async {
    if (kDebugMode) qqq("telemetry: uploading to ${Config.domain}");
    final Object? result = await _post(
      "/public-api/telemetry/perf",
      body: body,
      ea: const [],
      timeout: const Duration(seconds: 10),
    );
    if (kDebugMode) {
      if (result != null) {
        qqq("telemetry: upload ok → $result");
      } else {
        qqw("telemetry: upload returned null (request may have failed, check ${Config.domain})");
      }
    }
  }

}

String _stripOsVersion(String version) {
  // "Android 14 (API 34)" → "Android 14"
  // "17.4.1" → "17.4"
  // "Version 14.4.1 (Build 23E224)" → "14.4"
  final RegExp parenRegex = RegExp(r'\s*\(.*\)\s*');
  String stripped = version.replaceAll(parenRegex, "").trim();

  // 如果是纯数字版本号 (如 iOS 的 "17.4.1")，只保留前两段
  final RegExp versionRegex = RegExp(r'^(\d+\.\d+)');
  final match = versionRegex.firstMatch(stripped);
  if (match != null && stripped == match.group(0)! || stripped.startsWith(match?.group(0) ?? "___")) {
    // 对于 "Android 14" 这种已经很短的，保持原样
    if (stripped.contains(" ")) {
      // "Android 14" → keep as is; "Android 14.1.2" → "Android 14.1"
      return stripped;
    }
    return match?.group(1) ?? stripped;
  }
  return stripped;
}

String _generateUuidV4() {
  final Random rng = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Version 4
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Variant 10xx
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) sb.write('-');
    sb.write(hex(bytes[i]));
  }
  return sb.toString();
}
