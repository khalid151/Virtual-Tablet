import 'dart:convert' show utf8;

const MAX_PRESSURE = 8192;

class StylusPacket {
  // Singelton
  StylusPacket._internal();
  static final StylusPacket _instance = StylusPacket._internal();
  factory StylusPacket() => _instance;

  final List<int> _magic = utf8.encode("VTAB");

  // Tablet properties
  int x = 0;
  int y = 0;
  int pressure = 0;
  int button = 0;
  bool down = false;

  List<int> compile() {
    pressure = pressure.clamp(0, MAX_PRESSURE);
    List<int> str = [
      x.toUnsigned(16) & 255,
      x.toUnsigned(16) >> 8,
      y.toUnsigned(16) & 255,
      y.toUnsigned(16) >> 8,
      pressure.toUnsigned(16) & 255,
      (pressure.toUnsigned(16) >> 8) & 63 |
          (((down ? 1 : 0).toUnsigned(8) & 1) << 6),
      button.toUnsigned(8),
    ];
    return _magic + str;
  }
}
