part of 'p.dart';

const String _qnnCopiedManifestPreferenceKey = "halo_state.qnnCopiedManifest.v1";

final class _QnnCopyEntry {
  final String assetPath;
  final String targetPath;

  const _QnnCopyEntry({
    required this.assetPath,
    required this.targetPath,
  });
}

class _RWKVBackend {
  late final socName = qs("");
  late final socBrand = qs(SocBrand.unknown);
  late final commitId = qs<String>("");

  late final frontendSocName = qs<String?>(null);
  late final frontendSocBrand = qs<SocBrand?>(null);

  late final _qnnLibsCopied = qs(false);

  late final backendStatus = qs<BackendStatus>(.none);
}

extension _$RWKVBackend on _RWKVBackend {
  Future<void> _init() async {
    final r = await compute((_) {
      final socName = RWKVMobile.getSocName();
      final platformName = RWKVMobile.getPlatformName();
      final commitId = RWKVMobile.getRWKVMobileCommitHash();
      final socBrand = SocBrand.fromString(platformName);
      return (socName, socBrand, commitId);
    }, []);
    socName.q = r.$1;
    socBrand.q = r.$2;
    commitId.q = r.$3;

    if (!Platform.isAndroid) {
      return;
    }

    final detected = await P.adapter.detectSocInfo();
    if (detected == null) {
      return;
    }

    final detectedName = detected.$1;
    final detectedBrand = detected.$2;
    if (detectedName.isNotEmpty) {
      frontendSocName.q = detectedName;
    }
    if (detectedBrand != SocBrand.unknown) {
      frontendSocBrand.q = detectedBrand;
    }
  }

  Future<void> _ensureQNNCopied() async {
    if (_qnnLibsCopied.q) {
      return;
    }

    if (Platform.isAndroid) {
      final qnnLibList = <String>{
        "libQnnHtp.so",
        "libQnnHtpNetRunExtensions.so",
        "libQnnHtpV68Stub.so",
        "libQnnHtpV69Stub.so",
        "libQnnHtpV73Stub.so",
        "libQnnHtpV75Stub.so",
        "libQnnHtpV79Stub.so",
        "libQnnHtpV81Stub.so",
        "libQnnHtpV68Skel.so",
        "libQnnHtpV69Skel.so",
        "libQnnHtpV73Skel.so",
        "libQnnHtpV75Skel.so",
        "libQnnHtpV79Skel.so",
        "libQnnHtpV81Skel.so",
        "libQnnHtpPrepare.so",
        "libQnnSystem.so",
        "libQnnRwkvWkvOpPackageV68.so",
        "libQnnRwkvWkvOpPackageV69.so",
        "libQnnRwkvWkvOpPackageV73.so",
        "libQnnRwkvWkvOpPackageV75.so",
        "libQnnRwkvWkvOpPackageV79.so",
        "libQnnRwkvWkvOpPackageV81.so",
      };
      await _ensureQnnEntriesCopied(assetDir: "assets/lib/qnn", libs: qnnLibList);
      _qnnLibsCopied.q = true;
      return;
    }

    if (!Platform.isWindows || ffi.Abi.current() != ffi.Abi.windowsArm64) {
      return;
    }

    final qnnLibList = <String>{
      "QnnHtp.dll",
      "QnnHtpNetRunExtensions.dll",
      "QnnHtpPrepare.dll",
      "QnnSystem.dll",
      "QnnHtpV68Stub.dll",
      "QnnHtpV73Stub.dll",
      "QnnHtpV81Stub.dll",
      "libQnnHtpV73Skel.so",
      "libQnnHtpV81Skel.so",
      "libqnnhtpv73.cat",
      "libqnnhtpv81.cat",
    };
    await _ensureQnnEntriesCopied(assetDir: "assets/lib/qnn-windows", libs: qnnLibList);
    _qnnLibsCopied.q = true;
  }

  Future<void> _ensureQnnEntriesCopied({
    required String assetDir,
    required Set<String> libs,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final entries = <_QnnCopyEntry>[];
    for (final lib in libs) {
      entries.add(
        _QnnCopyEntry(
          assetPath: "$assetDir/$lib",
          targetPath: join(tempDir.path, "assets/lib/$lib"),
        ),
      );
    }

    final sp = await SharedPreferences.getInstance();
    if (await _qnnCopiedManifestIsValid(sp: sp, entries: entries)) {
      return;
    }

    for (final entry in entries) {
      await fromAssetsToTemp(entry.assetPath, targetPath: relative(entry.targetPath, from: tempDir.path));
    }
    await _writeQnnCopiedManifest(sp: sp, entries: entries);
  }

  Future<bool> _qnnCopiedManifestIsValid({
    required SharedPreferences sp,
    required List<_QnnCopyEntry> entries,
  }) async {
    final raw = sp.getString(_qnnCopiedManifestPreferenceKey);
    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded["version"] != P.app.version.q) return false;
      if (decoded["buildNumber"] != P.app.buildNumber.q) return false;
      if (decoded["platform"] != _qnnManifestPlatformKey()) return false;
      if (decoded["abi"] != ffi.Abi.current().toString()) return false;

      final rawEntries = decoded["entries"];
      if (rawEntries is! List<dynamic>) return false;
      if (rawEntries.length != entries.length) return false;

      final manifestByAssetPath = <String, Map<String, dynamic>>{};
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map<String, dynamic>) return false;
        final assetPath = rawEntry["assetPath"];
        if (assetPath is! String) return false;
        manifestByAssetPath[assetPath] = rawEntry;
      }

      for (final entry in entries) {
        final manifest = manifestByAssetPath[entry.assetPath];
        if (manifest == null) return false;
        if (manifest["targetPath"] != entry.targetPath) return false;
        final targetSize = manifest["targetSize"];
        if (targetSize is! int) return false;
        final file = File(entry.targetPath);
        if (!await file.exists()) return false;
        final fileSize = await file.length();
        if (fileSize != targetSize) return false;
      }
      return true;
    } catch (e) {
      qqw("qnn manifest invalid: $e");
      return false;
    }
  }

  Future<void> _writeQnnCopiedManifest({
    required SharedPreferences sp,
    required List<_QnnCopyEntry> entries,
  }) async {
    final encodedEntries = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final file = File(entry.targetPath);
      final targetSize = await file.length();
      encodedEntries.add({
        "assetPath": entry.assetPath,
        "targetPath": entry.targetPath,
        "targetSize": targetSize,
      });
    }

    await sp.setString(
      _qnnCopiedManifestPreferenceKey,
      jsonEncode({
        "version": P.app.version.q,
        "buildNumber": P.app.buildNumber.q,
        "platform": _qnnManifestPlatformKey(),
        "abi": ffi.Abi.current().toString(),
        "entries": encodedEntries,
      }),
    );
  }

  String _qnnManifestPlatformKey() {
    if (Platform.isAndroid) return "android";
    if (Platform.isWindows) return "windows";
    return Platform.operatingSystem;
  }
}
