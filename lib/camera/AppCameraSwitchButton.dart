import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AppCameraSwitchButton extends StatelessWidget {
  final CameraState state;
  final AwesomeTheme? theme;
  final void Function(CameraState) onSwitchTap;

  AppCameraSwitchButton({super.key, required this.state, this.theme, Widget Function()? iconBuilder, void Function(CameraState)? onSwitchTap, double scale = 1.3})
    : onSwitchTap = onSwitchTap ?? ((state) => state.switchCameraSensor());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;

    return AwesomeOrientedWidget(
      rotateWithDevice: theme.buttonTheme.rotateWithCamera,
      child: IconButton.filled(
        onPressed: () => onSwitchTap(state),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shadowColor: Colors.black54,
          elevation: 10,
        ),
        icon: const Icon(Icons.cameraswitch, size: 28),
      ),
    );
  }
}
