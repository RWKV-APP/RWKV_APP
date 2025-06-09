part of 'p.dart';

class _Device {
  final memUsed = qs(0);
  final memFree = qs(0);
  final memUsedByCurrentModel = qs(0);
}

/// Public methods
extension $Device on _Device {
  FV sync() async {
    if (Platform.isIOS) {
      final result = await P.adapter.call(ToNative.checkMemory);
      if (result == null) return;
      qqq("$result");
      final memUsed = result[0];
      final memFree = result[1];
      this.memUsed.q = memUsed;
      this.memFree.q = memFree;
    } else {
      await HF.wait(200);
      final result = await compute((message) async {
        final free = Platform.isAndroid || Platform.isLinux ? _getLinuxAvailableMemory() : SysInfo.getFreePhysicalMemory();
        final total = SysInfo.getTotalPhysicalMemory();
        qqq("free: $free, total: $total");
        return [free, total];
      }, []);
      qqq("result: $result");
      final memFree = result[0];
      final memTotal = result[1];
      memUsed.q = memTotal - memFree;
      this.memFree.q = memFree;
    }
  }
}

/// Private methods
extension _$Device on _Device {
  FV _init() async {
    if (Platform.isIOS) {
    } else {
      // totalMemory.value = 0;
      // freeMemory.value = 0;
    }
  }
}

int _getLinuxAvailableMemory() {
  final out = _exec('cat', ['/proc/meminfo']);
  final lines = out?.replaceAll('\r\n', '\n').split('\n') ?? [];
  for (final line in lines) {
    if (!line.contains("MemAvailable:")) continue;
    final parts = line.split(' ').where((element) => element.isNotEmpty).toList();
    try {
      return int.parse(parts[1]) * 1024;
    } catch (e) {
      qqe(e);
    }
  }
  return -1;
}

String? _exec(String executable, List<String> arguments, {bool runInShell = false}) {
  try {
    final result = Process.runSync(executable, arguments, runInShell: runInShell);
    if (result.exitCode == 0) {
      return result.stdout.toString();
    }
  } catch (e) {
    qqe(e);
  }
  return null;
}
