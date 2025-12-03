import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

class AlbatrossService {
  AlbatrossService._();

  static SendPort? _port;
  static Isolate? _isolate;

  static void qqq(String message) {
    print(message);
  }

  static void qqe(dynamic message) {
    print(message);
  }

  static Future run({
    required String cwd,
    required int port,
  }) async {
    final receivePort = ReceivePort();
    final startup = Startup(cwd: cwd, sendPort: receivePort.sendPort, port: port);
    _isolate = await Isolate.spawn(AlbatrossService._main, startup);

    final events = receivePort.asBroadcastStream();
    final message = await events.first;
    if (message is Startup) {
      _port = message.sendPort;
      qqq('Albatross is running');
    } else if (message is Exception) {
      qqe('Failed to startup albatross\n$message');
      return;
    }

    /// listen to status changes
    () async {
      final event = await events.first;
      if (event is String) {
        qqe('Exception in albatross: $event');
      } else if (event is Shutdown) {
        receivePort.close();
        qqq('Albatross is stopped');
      }
    }();
  }

  static Future kill() async {
    _port?.send(Shutdown());
    _port = null;
    _isolate?.kill();
    _isolate = null;
  }

  static Future _main(Startup startup) async {
    SendPort port = startup.sendPort;
    try {
      _startup(startup);
    } catch (e) {
      qqe(e);
      port.send(e.toString());
      return;
    }

    ReceivePort rcv = ReceivePort();
    port.send(startup.copyWith(sendPort: rcv.sendPort));

    await for (final cmd in rcv) {
      if (cmd is Shutdown) {
        break;
      }
    }
    await _shutdown();
    port.send(Shutdown());
    rcv.close();
  }

  static Future _startup(Startup message) async {
    final python = await _findPython();
    if (python == null) throw Exception('No python executable found');
    qqq('Found python: $python');

    final res = await _run(
      executable: '$python ${message.cwd}/main_robyn.py',
      args: ["--port ${message.port}"],
    );
    qqq(res.stdout);
    qqq(res.stderr);
  }

  static Future _shutdown() async {
    //
  }

  static Future<String?> _findPython() async {
    for (final envVar in ['VIRTUAL_ENV', 'CONDA_PREFIX']) {
      final base = Platform.environment[envVar];
      if (base != null && base.isNotEmpty) {
        final exe = Platform.isWindows ? '$base\\Scripts\\python.exe' : '$base/bin/python';
        if (await File(exe).exists()) return exe;
      }
    }
    final candidates = Platform.isWindows ? ['python.exe', 'py.exe', r'C:\Windows\py.exe'] : ['python3', 'python'];
    for (final name in candidates) {
      try {
        final r = await Process.run(name, ['-c', 'print("ok")']);
        if (r.exitCode == 0 && (r.stdout as String).contains('ok')) {
          if (name == 'py.exe') {
            final p = await Process.run('py', ['-3', '-c', 'import sys;print(sys.executable)']);
            if (p.exitCode == 0) return (p.stdout as String).trim();
          }
          return name;
        }
      } catch (_) {}
    }
    if (Platform.isWindows) return null;
    final which = await Process.run('which', ['python3']);
    return which.exitCode == 0 ? (which.stdout as String).toString().trim() : null;
  }

  static Future<ProcessResult> _run({
    required String executable,
    List<String> args = const [],
    String? cwd,
  }) async {
    final env = Map<String, String>.from(Platform.environment);

    final conda = Platform.environment['CONDA_PREFIX'];

    env['PATH'] = '${env['PATH']}:$conda/bin';
    if (conda != null) {
      env['LD_LIBRARY_PATH'] = [
        "$conda/lib",
        if (env['LD_LIBRARY_PATH'] != null) env['LD_LIBRARY_PATH']!,
      ].where((e) => e.isNotEmpty).join(':');
    }

    final useShellForPipes = Platform.isWindows || Platform.isMacOS;
    if (useShellForPipes) {
      if (Platform.isWindows) {
        return Process.run(
          'powershell',
          [
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-Command',
            ([executable, ...args].map((e) => '"$e"').join(' ')),
          ],
          workingDirectory: cwd,
          environment: env,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(days: 365));
      } else {
        final cmd = ([executable, ...args].map((e) => '"$e"').join(' '));
        return Process.run(
          '/bin/bash',
          ['-lc', cmd],
          workingDirectory: cwd,
          environment: env,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(days: 365));
      }
    } else {
      return Process.run(
        executable,
        args,
        workingDirectory: cwd,
        environment: env,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(days: 365));
    }
  }
}

class Startup {
  final String cwd;
  final SendPort sendPort;
  final int port;

  Startup({required this.sendPort, required this.port, required this.cwd});

  Startup copyWith({
    String? modelPath,
    SendPort? sendPort,
    int? port,
    String? cwd,
  }) {
    return Startup(
      sendPort: sendPort ?? this.sendPort,
      port: port ?? this.port,
      cwd: cwd ?? this.cwd,
    );
  }
}

class Shutdown {}
