import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_tablet/src/models/stylus_packet.dart';
import 'package:virtual_tablet/src/tcp.dart';

StylusPacket packet = StylusPacket();

class TabletScreen extends StatefulWidget {
  // TODO: set from user settings
  final margins = EdgeInsets.all(15.0);

  @override
  _TabletScreenState createState() => _TabletScreenState();
}

class _TabletScreenState extends State<TabletScreen> {
  final _tabletAreaKey = GlobalKey();
  bool _filled = false;

  void _handleEvents(PointerEvent event) {
    if (_tabletAreaKey.currentContext == null) {
      return;
    }

    if (event.kind == PointerDeviceKind.stylus) {
      // Context cannot be null here
      final size = _tabletAreaKey.currentContext!.size!;
      final pos = event.localPosition;
      final m = widget.margins;

      double x = (pos.dx - m.left) / (size.width - m.left - m.right);
      double y = (pos.dy - m.top) / (size.height - m.top - m.bottom);

      x = x.clamp(0.0, 1.0);
      y = y.clamp(0.0, 1.0);

      packet.x = (x * 65535).toInt();
      packet.y = (y * 65535).toInt();
      packet.pressure = (event.pressure * 8192).toInt();
      packet.down = event.down;
      packet.button = event.buttons;
      TcpConnection().send(packet.compile());
    }
  }

  Widget _tabletArea(BuildContext context) => Hero(
        key: _tabletAreaKey,
        tag: 'tablet_area',
        child: Stack(
          children: [
            // Just so events can be passed to listener
            Container(color: Colors.transparent),
            Container(
              margin: widget.margins,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Container(
              alignment: Alignment.topRight,
              margin: widget.margins + EdgeInsets.all(5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () => setState(() => _filled = true),
                  borderRadius: BorderRadius.circular(30),
                  child: Icon(
                    Icons.fullscreen,
                    size: 30,
                    color: Theme.of(context).focusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    return WillPopScope(
      onWillPop: () async {
        if (_filled) {
          setState(() => _filled = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Listener(
                  onPointerUp: _handleEvents,
                  onPointerDown: _handleEvents,
                  onPointerHover: _handleEvents,
                  onPointerMove: _handleEvents,
                  child: _tabletArea(context),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                color: _filled ? Colors.black : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
