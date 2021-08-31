import 'package:flutter/material.dart';

enum _ConnectButtonState {
  idle,
  loading,
  failed,
  stopped,
}

class ConnectButton extends StatefulWidget {
  final String idleLabel;
  final String failLabel;
  final double progressCircleRadius;
  final double borderRadius;
  final double buttonWidth;
  final double buttonHeight;
  final Function? onTap;

  ConnectButton({
    Key? key,
    this.onTap,
    this.borderRadius = 0,
    this.progressCircleRadius = 40,
    this.buttonHeight = 40,
    this.buttonWidth = 100,
    this.idleLabel = "Connect",
    this.failLabel = "Retry?",
  }) : super(key: key);

  @override
  ConnectButtonState createState() => ConnectButtonState();
}

class ConnectButtonState extends State<ConnectButton> {
  static const idle = _ConnectButtonState.idle;
  static const loading = _ConnectButtonState.loading;
  static const failed = _ConnectButtonState.failed;
  static const stopped = _ConnectButtonState.stopped;

  _ConnectButtonState buttonState = _ConnectButtonState.idle;

  void updateButtonState(_ConnectButtonState state) {
    setState(() => buttonState = state);
  }

  dynamic _applyParameter(dynamic ifTrue, dynamic ifFalse) {
    if (buttonState == _ConnectButtonState.loading ||
        buttonState == _ConnectButtonState.stopped)
      return ifTrue;
    else
      return ifFalse;
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = Theme.of(context).primaryColor;

    return ClipRRect(
      borderRadius: _applyParameter(
          BorderRadius.circular(widget.progressCircleRadius),
          BorderRadius.circular(widget.borderRadius)),
      child: Material(
        color: buttonColor,
        child: InkWell(
          onTap: () {
            if (buttonState != _ConnectButtonState.loading &&
                buttonState != _ConnectButtonState.stopped)
              widget.onTap?.call();
          },
          child: AnimatedContainer(
            decoration: BoxDecoration(
              borderRadius: _applyParameter(
                  BorderRadius.circular(widget.progressCircleRadius),
                  BorderRadius.circular(widget.borderRadius)),
            ),
            duration: const Duration(seconds: 1),
            curve: Curves.fastOutSlowIn,
            width: _applyParameter(
                widget.progressCircleRadius, widget.buttonWidth),
            height: _applyParameter(
                widget.progressCircleRadius, widget.buttonHeight),
            alignment: Alignment.center,
            child: AnimatedCrossFade(
                firstChild: Text(
                  buttonState == _ConnectButtonState.failed
                      ? widget.failLabel
                      : widget.idleLabel,
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  /*style: Theme.of(context).textTheme.button,*/
                  style: TextStyle(
                    color: buttonColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: buttonState == _ConnectButtonState.stopped
                        ? Colors.transparent
                        : buttonColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                  ),
                ),
                crossFadeState: _applyParameter(
                    CrossFadeState.showSecond, CrossFadeState.showFirst),
                duration: Duration(milliseconds: 300)),
          ),
        ),
      ),
    );
  }
}
