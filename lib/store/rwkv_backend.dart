part of 'p.dart';

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
      for (final lib in qnnLibList) {
        await fromAssetsToTemp("assets/lib/qnn/$lib", targetPath: "assets/lib/$lib");
      }
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
    for (final lib in qnnLibList) {
      await fromAssetsToTemp("assets/lib/qnn-windows/$lib", targetPath: "assets/lib/$lib");
    }
    _qnnLibsCopied.q = true;
  }
}
