import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_tablet/src/mixins/validation_mixin.dart';
import 'package:virtual_tablet/src/screens/tablet.dart';
import 'package:virtual_tablet/src/udp.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  void _handleConnect(String? value) async {
    if (value != null) {
      var matches = ipRE.allMatches(value).elementAt(0);
      var ip = matches.group(1) ?? "";
      var port = int.parse(matches.group(2) ?? "0");
      final udp = UdpConnection();
      if (await udp.connect(ip, port)) {
        print("Connected");
        // Only save if connection is successful
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("last_ip", value);

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => TabletScreen()));
      }
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Material(
              color: Theme.of(context).accentColor,
              child: InkWell(
                onTap: () {
                  if (_formKey.currentState != null &&
                      _formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                  child: Text("Connect", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
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
