import 'dart:async';
import 'dart:io';
import 'dart:convert' show utf8;

class UdpConnection {
  // Create singleton
  UdpConnection._internal();
  static final UdpConnection _instance = UdpConnection._internal();
  factory UdpConnection() => _instance;

  late RawDatagramSocket _socket;
  late InternetAddress _addr;
  late int _port;
  late StreamSubscription _subscription;

  final _serverPing = utf8.encode("VTABCON");
  final _serverResponse = "VTABOK";

  Future<bool> connect(String address, int port) async {
    _addr = InternetAddress(address);
    _port = port;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);

    // Keep sending until you get ping, exit on timeout
    _socket.send(_serverPing, _addr, _port);

    int timeout = 10;
    bool connected = false;

    _subscription = _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _socket.receive();
        final response = String.fromCharCodes(dg?.data as List<int>);
        if (response == _serverResponse) {
          connected = true;
        }
      }
    });

    await Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      timeout--;

      _socket.send(_serverPing, _addr, _port); // Attempt to ping the server

      if (timeout == 0)
        return false;
      else
        return !connected;
    });

    return connected;
  }

  void send(List<int> buffer) => _socket.send(buffer, _addr, _port);
  void close() => _socket.close();
}
