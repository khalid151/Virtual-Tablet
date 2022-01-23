import 'dart:async';
import 'dart:io';

class TcpConnection {
  // Create singleton
  TcpConnection._internal();
  static final TcpConnection _instance = TcpConnection._internal();
  factory TcpConnection() => _instance;

  late Socket _socket;

  Future<bool> connect(String addr, int port) async {
    bool connected = false;

    int timeout = 10;

    await Future.doWhile(() async {
      try {
        _socket = await Socket.connect(addr, port);
        connected = true;
        return !connected;

      } on SocketException {
        await Future.delayed(Duration(seconds: 1));
        timeout--;
      }

      if(timeout == 0)
        return false;
      else
        return true;
    });

    return connected;
  }

  void send(List<int> buffer) => _socket.add(buffer);
  void close() => _socket.close();
}
