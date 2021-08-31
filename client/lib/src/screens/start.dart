import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_tablet/src/mixins/validation_mixin.dart';
import 'package:virtual_tablet/src/screens/tablet.dart';
import 'package:virtual_tablet/src/udp.dart';
import 'package:virtual_tablet/src/widgets/connect_button.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _buttonKey = GlobalKey<ConnectButtonState>();

  void _startTablet() {
    final pageTransition = PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 500),
      reverseTransitionDuration: Duration(milliseconds: 500),
      pageBuilder: (context, _, __) => TabletScreen(),
    );

    Navigator.push(context, pageTransition).then((value) {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);

      Future.delayed(Duration(milliseconds: 500)).then((value) {
        _buttonKey.currentState?.updateButtonState(ConnectButtonState.idle);
      });
    });
  }

  void _handleConnect(String? value) async {
    var matches = ipRE.allMatches(value!).elementAt(0);
    var ip = matches.group(1);
    var port = int.parse(matches.group(2)!);

    final udp = UdpConnection();

    _buttonKey.currentState?.updateButtonState(ConnectButtonState.loading);

    if (await udp.connect(ip!, port)) {
      _buttonKey.currentState?.updateButtonState(ConnectButtonState.stopped);

      // Only save if connection is successful
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("last_ip", value);

      _startTablet();
    } else {
      _buttonKey.currentState?.updateButtonState(ConnectButtonState.failed);
    }
  }

  Widget _ipInput(String? initIp) => TextFormField(
        decoration: const InputDecoration(
          icon: Icon(Icons.link),
          hintText: "0.0.0.0:9000",
        ),
        validator: validateIP,
        onSaved: _handleConnect,
        initialValue: initIp,
      );

  Widget _button() => Hero(
        tag: 'tablet_area',
        child: Container(
          margin: EdgeInsets.only(top: 15),
          child: ConnectButton(
            key: _buttonKey,
            borderRadius: 10,
            progressCircleRadius: 40,
            buttonHeight: 40,
            onTap: () {
              if (_formKey.currentState != null &&
                  _formKey.currentState!.validate()) {
                _formKey.currentState!.save();
              }
            },
          ),
        ),
      );

  Widget _formWidget(String? initIp) => Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _ipInput(initIp),
            _button(),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: FutureBuilder(
          future: getLastIp(),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return _formWidget(snapshot.data);
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}

Future<String?> getLastIp() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("last_ip");
}
