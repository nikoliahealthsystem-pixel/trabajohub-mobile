import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

typedef SocketEventHandler = void Function(dynamic data);
typedef SocketNoArgHandler = void Function();

class SocketClient {
  SocketClient._();
  static final SocketClient instance = SocketClient._();

  io.Socket? _socket;
  bool _isConnecting = false;

  final List<SocketNoArgHandler> _connectHandlers = [];
  final List<SocketNoArgHandler> _disconnectHandlers = [];
  final List<Function(dynamic)> _connectErrorHandlers = [];
  final Map<String, List<SocketEventHandler>> _eventHandlers = {};

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  // ── Connect ────────────────────────────────────────────────

  Future<void> connect() async {
    if (isConnected || _isConnecting) return;
    _isConnecting = true;

    final token = await AppStorage.getAccessToken();
    if (token == null) {
      _isConnecting = false;
      return;
    }

    if (_socket == null) {
      _socket = io.io(
        ApiConstants.socketBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setTimeout(20000)
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _bindSocketListeners(_socket!);
    }

    _socket!.connect();
  }

  void _bindSocketListeners(io.Socket socket) {
    socket.onConnect((_) {
      _isConnecting = false;
      for (final handler in List<SocketNoArgHandler>.from(_connectHandlers)) {
        handler();
      }
    });

    socket.onDisconnect((_) {
      for (final handler in List<SocketNoArgHandler>.from(_disconnectHandlers)) {
        handler();
      }
    });

    socket.onConnectError((error) {
      _isConnecting = false;
      for (final handler in List<Function(dynamic)>.from(_connectErrorHandlers)) {
        handler(error);
      }
    });

    for (final handler in _connectHandlers) {
      socket.onConnect((_) => handler());
    }
    for (final handler in _disconnectHandlers) {
      socket.onDisconnect((_) => handler());
    }
    for (final handler in _connectErrorHandlers) {
      socket.onConnectError(handler);
    }

    for (final entry in _eventHandlers.entries) {
      for (final handler in entry.value) {
        socket.on(entry.key, handler);
      }
    }
  }

  // ── Disconnect ─────────────────────────────────────────────

  void disconnect() {
    _isConnecting = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Room helpers ───────────────────────────────────────────

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
  }

  void emitTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  // ── Event listeners ────────────────────────────────────────

  void on(String event, Function(dynamic) handler) {
    _eventHandlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _eventHandlers[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _eventHandlers.remove(event);
      _socket?.off(event);
    }
  }

  void onConnect(Function() handler) {
    _connectHandlers.add(handler);
    _socket?.onConnect((_) => handler());
  }

  void onDisconnect(Function() handler) {
    _disconnectHandlers.add(handler);
    _socket?.onDisconnect((_) => handler());
  }

  void onConnectError(Function(dynamic) handler) {
    _connectErrorHandlers.add(handler);
    _socket?.onConnectError(handler);
  }

  Future<void> emitWhenConnected(String event, dynamic data) async {
    if (isConnected) {
      _socket?.emit(event, data);
      return;
    }

    if (!_isConnecting) {
      await connect();
    }

    if (isConnected) {
      _socket?.emit(event, data);
      return;
    }

    _socket?.once('connect', (_) {
      _socket?.emit(event, data);
    });
  }
}