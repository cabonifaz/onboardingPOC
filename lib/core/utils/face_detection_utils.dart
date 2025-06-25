import 'dart:developer';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/bloc/face_pose_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionUtils {
  // Tolerances and thresholds optimized for better accuracy
  static const double eyeOpenThreshold = 0.3; // For eye detection
  static const double smileThreshold = 0.6; // For smile detection
  static const int holdTimeMs = 1000; // Hold time for better user experience

  // Head rotation angles (in degrees)
  static const double targetTurnAngle =
      30.0; // Target angle for left/right turns
  static const double turnTolerance = 10.0; // Tolerance for turn angles

  // Minimum and maximum turn angles based on target and tolerance
  static const double minTurnAngle = targetTurnAngle - turnTolerance;
  static const double maxTurnAngle = targetTurnAngle + turnTolerance;

  // Individual angle tolerances for straight pose (reduced to 15 degrees)
  static const double yawTolerance = 15.0; // Reduced from 25.0
  static const double pitchTolerance = 15.0; // Reduced from 20.0
  static const double rollTolerance = 15.0; // Reduced from 20.0

  /// Verifica si la cara está mirando al frente
  static bool isLookingStraight(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    // Check individual angle tolerances
    final isYawValid = yaw.abs() < yawTolerance;
    final isPitchValid = pitch.abs() < pitchTolerance;
    final isRollValid = roll.abs() < rollTolerance;

    log('isLookingStraight - Yaw: $yaw, Pitch: $pitch, Roll: $roll');
    log('isLookingStraight - Valid: Yaw: $isYawValid, Pitch: $isPitchValid, Roll: $isRollValid');

    return isYawValid && isPitchValid && isRollValid;
  }

  /// Verifica si la cara está girada a la derecha
  static bool isTurnedRight(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX?.abs() ?? 0.0;
    final roll = face.headEulerAngleZ?.abs() ?? 0.0;

    // Check if head is turned right and not too much up/down or tilted
    final isTurned = yaw > minTurnAngle && yaw < maxTurnAngle;
    final isStable = pitch < pitchTolerance && roll < rollTolerance;

    log('isTurnedRight - Yaw: $yaw, Pitch: $pitch, Roll: $roll, Valid: ${isTurned && isStable}');
    return isTurned && isStable;
  }

  /// Verifica si la cara está girada a la izquierda
  static bool isTurnedLeft(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX?.abs() ?? 0.0;
    final roll = face.headEulerAngleZ?.abs() ?? 0.0;

    // Check if head is turned left and not too much up/down or tilted
    final isTurned = yaw < -minTurnAngle && yaw > -maxTurnAngle;
    final isStable = pitch < pitchTolerance && roll < rollTolerance;

    log('isTurnedLeft - Yaw: $yaw, Pitch: $pitch, Roll: $roll, Valid: ${isTurned && isStable}');
    return isTurned && isStable;
  }

  /// Verifica si los ojos están abiertos
  static bool areEyesOpen(Face face) {
    // If eye data is not available, assume eyes are open
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      log('Eyes detection not available, assuming open');
      return true;
    }

    // Check if both eyes are open with some fault tolerance
    // Allow one eye to be slightly less open than the other
    final leftEyeScore = face.leftEyeOpenProbability!;
    final rightEyeScore = face.rightEyeOpenProbability!;

    // At least one eye should be clearly open, the other can be slightly less open
    final isLeftEyeOpen = leftEyeScore > eyeOpenThreshold;
    final isRightEyeOpen = rightEyeScore > eyeOpenThreshold;

    // Allow one eye to be slightly below threshold if the other is well above
    final isOneEyeVeryOpen = leftEyeScore > (eyeOpenThreshold + 0.2) ||
        rightEyeScore > (eyeOpenThreshold + 0.2);

    log('areEyesOpen - Left: $leftEyeScore, Right: $rightEyeScore');
    return (isLeftEyeOpen && isRightEyeOpen) ||
        (isLeftEyeOpen && isOneEyeVeryOpen) ||
        (isRightEyeOpen && isOneEyeVeryOpen);
  }

  /// Verifica si la persona está sonriendo
  static bool isSmiling(Face face) {
    final isSmiling = (face.smilingProbability ?? 0) > smileThreshold;
    log('isSmiling - Value: ${face.smilingProbability}, Valid: $isSmiling');
    return isSmiling;
  }

  /// Valida la postura de la cara según el estado actual
  static bool validateFacePose(Face face, Type currentState) {
    log('Validating pose for state: $currentState');

    if (currentState == FacePoseLookingStraight) {
      final isValid = isLookingStraight(face) && areEyesOpen(face);
      log('LookingStraight validation: $isValid');
      return isValid;
    } else if (currentState == FacePoseTurnedRight) {
      final isValid = isTurnedRight(face) && areEyesOpen(face);
      log('TurnedRight validation: $isValid');
      return isValid;
    } else if (currentState == FacePoseTurnedLeft) {
      final isValid = isTurnedLeft(face) && areEyesOpen(face);
      log('TurnedLeft validation: $isValid');
      return isValid;
    }

    log('Unknown state: $currentState');
    return false;
  }
}
