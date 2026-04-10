part of 'p.dart';

const String _telemetryEnabledKey = "halo_state.telemetry.enabled";
const String _telemetryInstallIdKey = "halo_state.telemetry.installId";
const String _telemetryRegistryKey = "halo_state.telemetry.registry";

class _Telemetry {
  // ===========================================================================
  // StateProvider
  // ===========================================================================

  late final enabled = qs<bool>(true);
  late final _installId = qs<String>("");
  late final _deviceModel = qs<String>("");
  late final _totalMemoryMb = qs<int>(0);

  /// 去重注册表: key = "socName|modelSha256|backend" → millisecondsSinceEpoch
  late final _registry = qs<Map<String, int>>({});
}

/// Public methods
extension $Telemetry on _Telemetry {
  Future<void> setEnabled(bool value) async {
    enabled.q = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_telemetryEnabledKey, value);
  }

  Future<void> maybeReport({
    required double? prefillSpeed,
    required double? decodeSpeed,
  }) async {
    if (!enabled.q) return;
    if (prefillSpeed == null || prefillSpeed <= 0) return;
    if (decodeSpeed == null || decodeSpeed <= 0) return;

    final FileInfo? model = P.rwkv.latestModel.q;
    if (model == null) return;

    // sha256 可能为空（部分权重没有），用 fileName 兜底
    final String modelId = (model.sha256 != null && model.sha256!.isNotEmpty) ? model.sha256! : model.fileName;
    if (modelId.isEmpty) return;

    // socName: 优先 native → frontendSocName → deviceModel → platform
    String socName = P.rwkv.socName.q.isNotEmpty ? P.rwkv.socName.q : (P.rwkv.frontendSocName.q ?? "");
    if (socName.isEmpty) socName = _deviceModel.q;
    if (socName.isEmpty) socName = Platform.operatingSystem;

    final String backendName = model.backend?.name ?? "";
    if (backendName.isEmpty) return;

    // 去重: 同一组合 24h 内只上传一次
    final String dedupeKey = "${socName.toLowerCase()}|${modelId.toLowerCase()}|${backendName.toLowerCase()}";
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, int> registry = Map.of(_registry.q);
    final int? lastUpload = registry[dedupeKey];
    if (lastUpload != null && (now - lastUpload) < 86400000) {
      if (kDebugMode) qqq("telemetry: skipped (dedupe) key=$dedupeKey");
      return;
    }

    // 更新注册表
    registry[dedupeKey] = now;
    _registry.q = registry;
    unawaited(_saveRegistry(registry));

    final String socBrandName = P.rwkv.socBrand.q != SocBrand.unknown
        ? P.rwkv.socBrand.q.name
        : (P.rwkv.frontendSocBrand.q?.name ?? "unknown");

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
        "decodeSpeed": decodeSpeed,
      },
      "clientTimestamp": now,
    };

    await _upload(body);
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

    // registry
    final String? registryJson = sp.getString(_telemetryRegistryKey);
    if (registryJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(registryJson) as Map<String, dynamic>;
        _registry.q = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }

    // 设备型号
    await _initDeviceModel();

    // 总物理内存
    await _initTotalMemory();
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

  Future<void> _initTotalMemory() async {
    try {
      if (Platform.isIOS) {
        final result = await P.adapter.call(ToNative.checkMemory);
        if (result != null) {
          final int used = result[0];
          final int free = result[1];
          _totalMemoryMb.q = (used + free) ~/ (1024 * 1024);
        }
      } else {
        final int total = SysInfo.getTotalPhysicalMemory();
        _totalMemoryMb.q = total ~/ (1024 * 1024);
      }
    } catch (e) {
      if (kDebugMode) qqw("telemetry: failed to get total memory: $e");
    }
  }

  Future<void> _upload(Map<String, dynamic> body) async {
    try {
      if (kDebugMode) qqq("telemetry: uploading ${jsonEncode(body)}");
      await _post(
        "/public-api/telemetry/perf",
        body: body,
        ea: const [],
        timeout: const Duration(seconds: 10),
      );
      if (kDebugMode) qqq("telemetry: upload done");
    } catch (e) {
      if (kDebugMode) qqw("telemetry: upload error: $e");
    }
  }

  Future<void> _saveRegistry(Map<String, int> registry) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_telemetryRegistryKey, jsonEncode(registry));
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
