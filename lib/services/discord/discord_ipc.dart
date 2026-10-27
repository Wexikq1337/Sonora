import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Low level Discord IPC transport.
///
/// Windows: `\\.\pipe\discord-ipc-N` opened through Win32 `CreateFileW`
/// (dart:io has no named-pipe API), reads happen on a separate isolate.
/// Linux/macOS: unix domain socket `/tmp/discord-ipc-N`.
abstract class IpcTransport {
  Stream<Uint8List> get incoming;
  void send(List<int> bytes);
  Future<void> close();
}

class _SocketTransport implements IpcTransport {
  _SocketTransport(this._socket) {
    _sub = _socket.listen(
      _controller.add,
      onError: (Object e) => _controller.addError(e),
      onDone: () => _controller.close(),
      cancelOnError: false,
    );
  }

  final Socket _socket;
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();
  late final StreamSubscription<Uint8List> _sub;

  @override
  Stream<Uint8List> get incoming => _controller.stream;

  @override
  void send(List<int> bytes) {
    try {
      _socket.add(bytes);
    } catch (e) {
      debugPrint('Sonora/discord: socket write failed $e');
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _socket.close();
    await _socket.flush().catchError((Object _) {});
    await _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Win32 named pipe
// ---------------------------------------------------------------------------

typedef _CreateFileW_Native = IntPtr Function(
    Pointer<Utf16>, Uint32, Uint32, IntPtr, Uint32, Uint32, IntPtr);
typedef _CreateFileW_Dart = int Function(
    Pointer<Utf16>, int, int, int, int, int, int);

typedef _ReadFile_Native = Int32 Function(
    IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, IntPtr);
typedef _ReadFile_Dart = int Function(
    int, Pointer<Uint8>, int, Pointer<Uint32>, int);

typedef _WriteFile_Native = Int32 Function(
    IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, IntPtr);
typedef _WriteFile_Dart = int Function(
    int, Pointer<Uint8>, int, Pointer<Uint32>, int);

typedef _CloseHandle_Native = Int32 Function(IntPtr);
typedef _CloseHandle_Dart = int Function(int);

class _ReaderTask {
  _ReaderTask(this.handle, this.port);
  final int handle;
  final SendPort port;
}

void _readerEntry(_ReaderTask task) {
  final DynamicLibrary k32 = DynamicLibrary.open('kernel32.dll');
  final _ReadFile_Dart readFile =
      k32.lookupFunction<_ReadFile_Native, _ReadFile_Dart>('ReadFile');
  final Pointer<Uint8> buffer = calloc<Uint8>(16384);
  final Pointer<Uint32> read = calloc<Uint32>();
  try {
    while (true) {
      final int ok = readFile(task.handle, buffer, 16384, read, 0);
      if (ok == 0) break;
      final int n = read.value;
      if (n <= 0) continue;
      task.port.send(Uint8List.fromList(buffer.asTypedList(n)));
    }
  } catch (_) {
    // fall through to EOF
  } finally {
    calloc.free(buffer);
    calloc.free(read);
  }
  task.port.send(null);
}

class _WindowsPipeTransport implements IpcTransport {
  _WindowsPipeTransport._(this._handle) {
    _port.listen((dynamic msg) {
      if (msg == null) {
        if (!_controller.isClosed) _controller.close();
      } else if (msg is Uint8List) {
        if (!_controller.isClosed) _controller.add(msg);
      }
    });
    Isolate.spawn(_readerEntry, _ReaderTask(_handle, _port.sendPort),
            errorsAreFatal: false)
        .then<void>(
      (_) {},
      onError: (Object e) {
        debugPrint('Sonora/discord: reader isolate failed $e');
      },
    );
  }

  static const int _genericReadWrite = 0xC0000000;
  static const int _openExisting = 3;

  static _WindowsPipeTransport? open(String pipePath) {
    try {
      final DynamicLibrary k32 = DynamicLibrary.open('kernel32.dll');
      final _CreateFileW_Dart createFile =
          k32.lookupFunction<_CreateFileW_Native, _CreateFileW_Dart>(
              'CreateFileW');
      final Pointer<Utf16> name = pipePath.toNativeUtf16();
      final int handle = createFile(
          name, _genericReadWrite, 0, 0, _openExisting, 0, 0);
      calloc.free(name);
      if (handle == -1 || handle == 0) return null;
      return _WindowsPipeTransport._(handle);
    } catch (e) {
      debugPrint('Sonora/discord: CreateFileW failed $e');
      return null;
    }
  }

  final int _handle;
  final ReceivePort _port = ReceivePort();
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get incoming => _controller.stream;

  @override
  void send(List<int> bytes) {
    try {
      final DynamicLibrary k32 = DynamicLibrary.open('kernel32.dll');
      final _WriteFile_Dart writeFile =
          k32.lookupFunction<_WriteFile_Native, _WriteFile_Dart>('WriteFile');
      final Pointer<Uint8> buffer = calloc<Uint8>(bytes.length);
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      final Pointer<Uint32> written = calloc<Uint32>();
      writeFile(_handle, buffer, bytes.length, written, 0);
      calloc.free(buffer);
      calloc.free(written);
    } catch (e) {
      debugPrint('Sonora/discord: WriteFile failed $e');
    }
  }

  @override
  Future<void> close() async {
    try {
      final DynamicLibrary k32 = DynamicLibrary.open('kernel32.dll');
      final _CloseHandle_Dart closeHandle =
          k32.lookupFunction<_CloseHandle_Native, _CloseHandle_Dart>(
              'CloseHandle');
      closeHandle(_handle);
    } catch (_) {}
    _port.close();
    if (!_controller.isClosed) await _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Protocol
// ---------------------------------------------------------------------------

class DiscordRpcClient {
  IpcTransport? _transport;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<int> _buffer = <int>[];
  final Random _random = Random.secure();
  int _nonceSeed = 0;

  bool _connected = false;
  Map<String, dynamic>? user;
  String? lastError;

  bool get connected => _connected;
  Stream<Map<String, dynamic>> get events => _events.stream;

  String _nextNonce() {
    _nonceSeed++;
    final int a = _random.nextInt(1 << 32);
    return '${a.toRadixString(16)}-${_nonceSeed.toRadixString(16)}';
  }

  Future<IpcTransport?> _openTransport() async {
    for (int i = 0; i < 10; i++) {
      IpcTransport? t;
      if (Platform.isWindows) {
        t = _WindowsPipeTransport.open(r'\\.\pipe\discord-ipc-' '$i');
      } else if (Platform.isLinux || Platform.isMacOS) {
        final List<String> candidates = <String>[
          '/tmp/discord-ipc-$i',
          if (Platform.environment['XDG_RUNTIME_DIR'] != null)
            '${Platform.environment['XDG_RUNTIME_DIR']}/discord-ipc-$i',
          if (Platform.environment['TMPDIR'] != null)
            '${Platform.environment['TMPDIR']}/discord-ipc-$i',
        ];
        for (final String path in candidates) {
          try {
            final Socket s = await Socket.connect(
              InternetAddress(path, type: InternetAddressType.unix),
              0,
              timeout: const Duration(milliseconds: 250),
            ).timeout(const Duration(milliseconds: 350));
            t = _SocketTransport(s);
            break;
          } catch (_) {
            t = null;
          }
        }
      }
      if (t != null) return t;
    }
    return null;
  }

  /// Returns true when Discord answered the handshake with READY.
  Future<bool> connect(String clientId) async {
    await close();
    lastError = null;
    final IpcTransport? t = await _openTransport();
    if (t == null) {
      lastError = 'Discord IPC не найден (клиент не запущен?)';
      return false;
    }
    _transport = t;
    _buffer.clear();
    t.incoming.listen(_onChunk, onError: (Object e) {
      lastError = '$e';
      _connected = false;
    }, onDone: () {
      _connected = false;
    });

    _send(0, <String, dynamic>{'v': 1, 'client_id': clientId});

    try {
      final Map<String, dynamic> ready = await events
          .firstWhere((Map<String, dynamic> e) => e['ev'] == 'READY')
          .timeout(const Duration(seconds: 5));
      user = (ready['data'] as Map<String, dynamic>?)?['user']
          as Map<String, dynamic>?;
      _connected = true;
      lastError = null;
      return true;
    } catch (e) {
      lastError = 'Нет ответа READY: $e';
      _connected = false;
      return false;
    }
  }

  void _onChunk(Uint8List chunk) {
    _buffer.addAll(chunk);
    while (_buffer.length >= 8) {
      final ByteData header =
          ByteData.sublistView(Uint8List.fromList(_buffer.sublist(0, 8)));
      final int op = header.getUint32(0, Endian.little);
      final int len = header.getUint32(4, Endian.little);
      if (_buffer.length < 8 + len) break;
      final List<int> body = _buffer.sublist(8, 8 + len);
      _buffer.removeRange(0, 8 + len);
      try {
        final dynamic decoded = jsonDecode(utf8.decode(body));
        final Map<String, dynamic> map =
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        if (op == 2) {
          lastError = 'Discord closed the pipe: ${map['message'] ?? ''}';
          _connected = false;
        }
        if (!_events.isClosed) _events.add(map);
      } catch (e) {
        debugPrint('Sonora/discord: bad frame $e');
      }
    }
  }

  void _send(int op, Map<String, dynamic> payload) {
    final IpcTransport? t = _transport;
    if (t == null) return;
    final List<int> body = utf8.encode(jsonEncode(payload));
    final ByteData header = ByteData(8)
      ..setUint32(0, op, Endian.little)
      ..setUint32(4, body.length, Endian.little);
    t.send(<int>[...header.buffer.asUint8List(), ...body]);
  }

  Future<void> setActivity(Map<String, dynamic> activity) async {
    _send(1, <String, dynamic>{
      'cmd': 'SET_ACTIVITY',
      'args': <String, dynamic>{'pid': pid, 'activity': activity},
      'nonce': _nextNonce(),
    });
  }

  Future<void> clearActivity() async {
    _send(1, <String, dynamic>{
      'cmd': 'SET_ACTIVITY',
      'args': <String, dynamic>{'pid': pid},
      'nonce': _nextNonce(),
    });
  }

  Future<void> close() async {
    await _transport?.close();
    _transport = null;
    _connected = false;
  }

  void dispose() {
    close();
    _events.close();
  }
}
