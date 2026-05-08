import 'package:camerawesome/src/orchestrator/models/models.dart';
import 'package:camerawesome/src/orchestrator/states/photo_camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppCameraAspectRatioButton extends StatelessWidget {
  final PhotoCameraState state;
  final AwesomeTheme? theme;
  final Widget Function(CameraAspectRatios aspectRatio) iconBuilder;
  final void Function(SensorConfig sensorConfig, CameraAspectRatios aspectRatio) onAspectRatioTap;

  AppCameraAspectRatioButton({
    super.key,
    required this.state,
    this.theme,
    Widget Function(CameraAspectRatios aspectRatio)? iconBuilder,
    void Function(SensorConfig sensorConfig, CameraAspectRatios aspectRatio)? onAspectRatioTap,
  }) : iconBuilder =
           iconBuilder ??
           ((aspectRatio) {
             final Widget icon;
             double width;
             switch (aspectRatio) {
               case CameraAspectRatios.ratio_16_9:
                 width = 32;
                 icon = SvgPicture.asset("assets/icons/16_9.svg", width: 28, height: 28);
                 break;
               case CameraAspectRatios.ratio_4_3:
                 width = 24;
                 icon = SvgPicture.asset("assets/icons/4_3.svg", width: 28, height: 28);
                 break;
               case CameraAspectRatios.ratio_1_1:
                 width = 24;
                 icon = SvgPicture.asset("assets/icons/1_1.svg", width: 28, height: 28);
                 break;
             }

             return Builder(
               builder: (context) {
                 final iconSize = theme?.buttonTheme.iconSize ?? AwesomeThemeProvider.of(context).theme.buttonTheme.iconSize;

                 final scaleRatio = iconSize / AwesomeButtonTheme.baseIconSize;
                 return icon;
               },
             );
           }),
       onAspectRatioTap = onAspectRatioTap ?? ((sensorConfig, aspectRatio) => sensorConfig.switchCameraRatio());

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? AwesomeThemeProvider.of(context).theme;
    return StreamBuilder<SensorConfig>(
      key: const ValueKey("ratioButton"),
      stream: state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        if (!sensorConfigSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        final sensorConfig = sensorConfigSnapshot.requireData;
        return StreamBuilder<CameraAspectRatios>(
          stream: sensorConfig.aspectRatio$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            return AwesomeOrientedWidget(
              rotateWithDevice: theme.buttonTheme.rotateWithCamera,
              child: IconButton(icon: iconBuilder(snapshot.requireData), onPressed: () => onAspectRatioTap(sensorConfig, snapshot.requireData)),
            );
          },
        );
      },
    );
  }
}
