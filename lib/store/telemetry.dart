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
  late final _cpuName = qs<String>("");
  late final _gpuName = qs<String>("");
  late final _totalMemoryMb = qs<int>(0);
  late final _totalVramMb = qs<int>(0);
  late final _peakDecodeSpeed = qs<double>(0);

  late final peakDecodeSpeed = qp<double>((ref) => ref.watch(_peakDecodeSpeed));

  late final benchmarkDeviceInfo = qp<Map<String, String>>((ref) {
    final String appVersion = ref.watch(P.app.version);
    final String buildNumber = ref.watch(P.app.buildNumber);
    final String osVersion = ref.watch(P.app.osVersion);
    final String deviceModel = ref.watch(_deviceModel);
    final String macChipName = ref.watch(_macChipName);
    final String cpuName = ref.watch(_cpuName);
    final String gpuName = ref.watch(_gpuName);
    final int totalMemoryMb = ref.watch(_totalMemoryMb);
    final int totalVramMb = ref.watch(_totalVramMb);
    final String nativeSocName = ref.watch(P.rwkv.socName);
    final String? frontendSocName = ref.watch(P.rwkv.frontendSocName);
    final SocBrand nativeSocBrand = ref.watch(P.rwkv.socBrand);
    final SocBrand? frontendSocBrand = ref.watch(P.rwkv.frontendSocBrand);
    final FileInfo? model = ref.watch(P.rwkv.latestModel);

    final String socName = _resolveSocName(
      nativeSocName: nativeSocName,
      frontendSocName: frontendSocName,
      macChipName: macChipName,
      gpuName: gpuName,
      cpuName: cpuName,
      deviceModel: deviceModel,
      backendName: model?.backend?.name ?? "",
    );
    final String socBrandName = _resolveSocBrandName(
      nativeSocBrand: nativeSocBrand,
      frontendSocBrand: frontendSocBrand,
      gpuName: gpuName,
      cpuName: cpuName,
    );
    final bool socNameLooksGeneric = _isUnknownHardwareName(socName) || socName == deviceModel || socName == Platform.operatingSystem;

    return {
      "AppVersion": "$appVersion ($buildNumber)",
      "BuildMode": _currentFlutterBuildMode(),
      "OS": Platform.operatingSystem,
      if (osVersion.isNotEmpty) "OSVersion": _stripOsVersion(osVersion),
      if (deviceModel.isNotEmpty) "DeviceModel": deviceModel,
      if (!socNameLooksGeneric) "SocName": socName,
      if (socBrandName != "unknown") "SocBrand": socBrandName,
      if (cpuName.isNotEmpty) "CPUName": cpuName,
      if (gpuName.isNotEmpty) "GPUName": gpuName,
      if (totalMemoryMb > 0) "TotalMemory": _formatMemoryMb(totalMemoryMb),
      if (totalVramMb > 0) "TotalVRAM": _formatMemoryMb(totalVramMb),
    };
  });
}

/// Public methods
extension $Telemetry on _Telemetry {
  double snapshotPeakDecodeSpeed() => _peakDecodeSpeed.q;

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
    int? batchCountOverride,
    bool? isBatchOverride,
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

      final String backendName = model.backend?.name ?? "";
      if (backendName.isEmpty) return;

      final String socName = _resolveSocName(
        nativeSocName: P.rwkv.socName.q,
        frontendSocName: P.rwkv.frontendSocName.q,
        macChipName: _macChipName.q,
        gpuName: _gpuName.q,
        cpuName: _cpuName.q,
        deviceModel: _deviceModel.q,
        backendName: backendName,
      );

      final bool isBatch = isBatchOverride ?? P.chat.effectiveBatchEnabled.q;
      final int batchCount = isBatch ? max(1, batchCountOverride ?? P.chat.effectiveBatchCount.q) : 1;

      // batch 模式使用整轮推理中的峰值 decode speed
      final double effectiveDecodeSpeed = (batchCount > 1 && snapshotPeakDecodeSpeed > 0) ? snapshotPeakDecodeSpeed : decodeSpeed;

      final String socBrandName = _resolveSocBrandName(
        nativeSocBrand: P.rwkv.socBrand.q,
        frontendSocBrand: P.rwkv.frontendSocBrand.q,
        gpuName: _gpuName.q,
        cpuName: _cpuName.q,
      );

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
          "cpuName": _cpuName.q.isNotEmpty ? _cpuName.q : null,
          "gpuName": _gpuName.q.isNotEmpty ? _gpuName.q : null,
          "totalMemoryMb": _totalMemoryMb.q > 0 ? _totalMemoryMb.q : null,
          "totalVramMb": _totalVramMb.q > 0 ? _totalVramMb.q : null,
        },
        "app": {
          "version": P.app.version.q,
          "build": P.app.buildNumber.q,
          "buildMode": _currentFlutterBuildMode(),
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

    // Windows / Linux / macOS CPU 名称
    await _initCpuName();

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
      final String chip = _normalizeHardwareName((result.stdout as String).trim());
      if (chip.isNotEmpty) {
        _macChipName.q = chip;
        _cpuName.q = chip;
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get mac chip name: $e");
    }
  }

  Future<void> _initCpuName() async {
    try {
      if (Platform.isWindows) {
        final ProcessResult powerShellResult = await Process.run("powershell", [
          "-NoProfile",
          "-Command",
          "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)",
        ]);
        final String powerShellCpu = _firstNonEmptyLine(powerShellResult.stdout as String);
        if (powerShellCpu.isNotEmpty) {
          _cpuName.q = powerShellCpu;
          if (kDebugMode) qqq("telemetry: detected CPU: ${_cpuName.q}");
          return;
        }

        final ProcessResult wmicResult = await Process.run("cmd", [
          "/c",
          "wmic cpu get name /value",
        ]);
        final String cpu = _extractFirstWmicValue(wmicResult.stdout as String, "Name=");
        if (cpu.isEmpty) return;
        _cpuName.q = cpu;
        if (kDebugMode) qqq("telemetry: detected CPU: ${_cpuName.q}");
        return;
      }

      if (!Platform.isLinux) return;
      final ProcessResult result = await Process.run("bash", [
        "-c",
        "lscpu | grep -i 'Model name:' | head -1 | sed 's/Model name:\\s*//'",
      ]);
      final String cpu = _firstNonEmptyLine(result.stdout as String);
      if (cpu.isEmpty) return;
      _cpuName.q = cpu;
      if (kDebugMode) qqq("telemetry: detected CPU: ${_cpuName.q}");
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get CPU name: $e");
    }
  }

  Future<void> _initGpuName() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    try {
      if (Platform.isWindows) {
        final ProcessResult powerShellResult = await Process.run("powershell", [
          "-NoProfile",
          "-Command",
          "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name",
        ]);
        final String powerShellGpu = _pickPreferredGpuName(
          (powerShellResult.stdout as String).split(RegExp(r'[\r\n]+')),
        );
        if (powerShellGpu.isNotEmpty) {
          _gpuName.q = powerShellGpu;
          if (kDebugMode) qqq("telemetry: detected GPU: ${_gpuName.q}");
          return;
        }

        final ProcessResult wmicResult = await Process.run("cmd", [
          "/c",
          "wmic path win32_videocontroller get name /value",
        ]);
        final List<String> candidates = [];
        for (final String line in (wmicResult.stdout as String).split(RegExp(r'[\r\n]+'))) {
          final String trimmed = line.trim();
          if (!trimmed.startsWith("Name=")) continue;
          final String name = _normalizeHardwareName(trimmed.substring(5));
          if (name.isEmpty) continue;
          candidates.add(name);
        }
        final String bestGpu = _pickPreferredGpuName(candidates);
        if (bestGpu.isEmpty) return;
        _gpuName.q = bestGpu;
        if (kDebugMode) qqq("telemetry: detected GPU: ${_gpuName.q}");
      } else if (Platform.isLinux) {
        // lspci: 找 VGA / 3D controller
        final ProcessResult result = await Process.run("bash", [
          "-c",
          "lspci | grep -iE 'VGA|3D' | head -1 | sed 's/.*: //'",
        ]);
        final String gpu = _firstNonEmptyLine(result.stdout as String);
        if (gpu.isNotEmpty) {
          _gpuName.q = gpu;
          if (kDebugMode) qqq("telemetry: detected GPU: ${_gpuName.q}");
        }
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get GPU name: $e");
    }
  }

  String _normalizeHardwareName(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').replaceAll('"', '').trim();
  }

  String _firstNonEmptyLine(String output) {
    for (final String line in output.split(RegExp(r'[\r\n]+'))) {
      final String normalized = _normalizeHardwareName(line);
      if (normalized.isEmpty) continue;
      return normalized;
    }
    return "";
  }

  String _extractFirstWmicValue(String output, String prefix) {
    for (final String line in output.split(RegExp(r'[\r\n]+'))) {
      final String trimmed = line.trim();
      if (!trimmed.startsWith(prefix)) continue;
      final String normalized = _normalizeHardwareName(trimmed.substring(prefix.length));
      if (normalized.isEmpty) continue;
      return normalized;
    }
    return "";
  }

  bool _isPreferredGpuName(String lower) {
    if (lower.contains("nvidia")) return true;
    if (lower.contains("radeon") || lower.contains("amd")) return true;
    if (lower.contains("intel") && lower.contains("arc")) return true;
    return false;
  }

  String _pickPreferredGpuName(Iterable<String> candidates) {
    String bestGpu = "";
    for (final String candidate in candidates) {
      final String normalized = _normalizeHardwareName(candidate);
      if (normalized.isEmpty) continue;
      if (bestGpu.isEmpty) {
        bestGpu = normalized;
      }
      final String lower = normalized.toLowerCase();
      if (_isPreferredGpuName(lower)) {
        return normalized;
      }
    }
    return bestGpu;
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

      // nvidia-smi 失败时仅对 NVIDIA 保留 wmic 回退，避免 AMD / Intel 设备写入误导性的 2GB VRAM
      if (Platform.isWindows && _gpuName.q.toLowerCase().contains("nvidia")) {
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
      } else {
        qqw("telemetry: upload returned null (request may have failed, check ${Config.domain})");
      }
    }
  }
}

bool _isUnknownHardwareName(String value) {
  final String lower = value.toLowerCase();
  return lower.isEmpty || lower == "unknown";
}

String _resolveSocName({
  required String nativeSocName,
  required String? frontendSocName,
  required String macChipName,
  required String gpuName,
  required String cpuName,
  required String deviceModel,
  required String backendName,
}) {
  String socName = nativeSocName;
  if (_isUnknownHardwareName(socName)) {
    socName = frontendSocName ?? "";
  }
  if (_isUnknownHardwareName(socName)) {
    socName = macChipName;
  }
  if (_isUnknownHardwareName(socName)) {
    socName = gpuName;
  }
  if (_isUnknownHardwareName(socName)) {
    socName = cpuName;
  }
  if (_isUnknownHardwareName(socName)) {
    socName = deviceModel;
  }
  if (_isUnknownHardwareName(socName)) {
    socName = Platform.operatingSystem;
  }

  final String lowerSocName = socName.toLowerCase();
  final bool socNameLooksGeneric =
      lowerSocName.isEmpty || lowerSocName == "unknown" || socName == deviceModel || socName == Platform.operatingSystem;
  if (backendName == "webrwkv" && gpuName.isNotEmpty) {
    if (socNameLooksGeneric || socName == cpuName) {
      socName = gpuName;
    }
  } else if (cpuName.isNotEmpty) {
    if (socNameLooksGeneric || socName == gpuName) {
      socName = cpuName;
    }
  }

  return socName;
}

String _resolveSocBrandName({
  required SocBrand nativeSocBrand,
  required SocBrand? frontendSocBrand,
  required String gpuName,
  required String cpuName,
}) {
  String socBrandName = nativeSocBrand != SocBrand.unknown ? nativeSocBrand.name : (frontendSocBrand?.name ?? "unknown");
  if (socBrandName == "unknown" && Platform.isMacOS) {
    socBrandName = "apple";
  }
  if (socBrandName == "unknown" && gpuName.isNotEmpty) {
    final String gpuLower = gpuName.toLowerCase();
    if (gpuLower.contains("nvidia")) {
      socBrandName = "nvidia";
    } else if (gpuLower.contains("radeon") || gpuLower.contains("amd")) {
      socBrandName = "amd";
    } else if (gpuLower.contains("intel") || gpuLower.contains("arc")) {
      socBrandName = "intel";
    }
  }
  if (socBrandName == "unknown" && cpuName.isNotEmpty) {
    final String cpuLower = cpuName.toLowerCase();
    if (cpuLower.contains("snapdragon") || cpuLower.contains("qualcomm")) {
      socBrandName = "snapdragon";
    } else if (cpuLower.contains("amd") || cpuLower.contains("ryzen")) {
      socBrandName = "amd";
    } else if (cpuLower.contains("intel")) {
      socBrandName = "intel";
    }
  }
  return socBrandName;
}

String _formatMemoryMb(int mb) {
  if (mb >= 1024) {
    final double gb = mb / 1024;
    final String value = gb >= 10 ? gb.toStringAsFixed(0) : gb.toStringAsFixed(1);
    return "$value GB";
  }
  return "$mb MB";
}

String _currentFlutterBuildMode() {
  if (kReleaseMode) return "release";
  if (kProfileMode) return "profile";
  return "debug";
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
