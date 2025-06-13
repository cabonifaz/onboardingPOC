import 'dart:typed_data' show BytesBuilder;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraUtils {
  /// Converts a CameraImage to InputImage format for ML Kit
  static InputImage? inputImageFromCameraImage(CameraImage image) {
    try {
      // Get image properties
      final width = image.width;
      final height = image.height;

      // Convert the image to NV21 format which is required by ML Kit
      final builder = BytesBuilder();
      for (final plane in image.planes) {
        builder.add(plane.bytes);
      }
      final bytes = builder.toBytes();

      // Create input image data
      final inputImageData = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      // Create and return the input image
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      return null;
    }
  }

  /// Initializes the face detector with common settings
  static FaceDetector initializeFaceDetector() {
    return FaceDetector(
      options: FaceDetectorOptions(
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

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
