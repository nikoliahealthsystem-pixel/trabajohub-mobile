import 'package:flutter_riverpod/legacy.dart';
import 'socket_client.dart';
import 'socket_provider.dart';

enum SocketStatus { disconnected, connecting, connected, error }

class SocketConnectionNotifier extends StateNotifier<SocketStatus> {
  final SocketClient _client;

  SocketConnectionNotifier(this._client)
      : super(SocketStatus.disconnected) {
    _attach();
  }

  void _attach() {
    _client.onConnect(() {
      state = SocketStatus.connected;
    });

    _client.onDisconnect(() {
      state = SocketStatus.disconnected;
    });

    _client.onConnectError((error) {
      state = SocketStatus.error;
    });
  }

  Future<void> connect() async {
    state = SocketStatus.connecting;
    await _client.connect();
  }

  void disconnect() {
    _client.disconnect();
    state = SocketStatus.disconnected;
  }
}

final socketConnectionProvider =
StateNotifierProvider<SocketConnectionNotifier, SocketStatus>((ref) {
  final client = ref.watch(socketClientProvider);
  return SocketConnectionNotifier(client);
});