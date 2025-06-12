import 'package:camera/camera.dart';

class CameraUtils {
  /// Finds the front-facing camera from the list of available cameras
  static CameraDescription? findFrontCamera(List<CameraDescription> cameras) {
    try {
      return cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      return null;
    }
  }
}
