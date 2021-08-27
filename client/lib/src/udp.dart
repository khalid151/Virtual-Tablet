import 'dart:io' show InternetAddress, RawDatagramSocket;

class UdpConnection {
  // Create singleton
  UdpConnection._internal();
  static final UdpConnection _instance = UdpConnection._internal();
  factory UdpConnection() => _instance;

  RawDatagramSocket? _socket;
  late InternetAddress _addr;
  late int _port;

  Future<bool> connect(String address, int port) async {
    _addr = InternetAddress(address);
    _port = port;
    // TODO: check if airplane mode affects getting a connection
    // TODO: test unreachable IP entry
    /*_socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);*/
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
    return true;
  }

  // TODO: check return values for send
  void send(List<int> buffer) => _socket?.send(buffer, _addr, _port);
  void close() => _socket?.close();
}
