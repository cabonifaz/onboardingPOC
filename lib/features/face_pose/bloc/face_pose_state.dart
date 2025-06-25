part of 'face_pose_bloc.dart';

abstract class FacePoseState extends Equatable {
  const FacePoseState();

  @override
  List<Object?> get props => [];

  String get message {
    if (this is FacePoseInitial) return 'Mira al frente';
    if (this is FacePoseLookingStraight) return 'Mantén la posición';
    if (this is FacePoseTurnedRight) return 'Gira la cabeza a la derecha';
    if (this is FacePoseTurnedLeft) return 'Gira la cabeza a la izquierda';
    if (this is FacePoseCompleted) return '¡Validación completada!';
    if (this is FacePoseError) return (this as FacePoseError).message;
    if (this is FacePosePaused) return 'Validación en pausa';
    return '';
  }
}

class FacePoseInitial extends FacePoseState {
  const FacePoseInitial();
}

class FacePoseLookingStraight extends FacePoseState {
  const FacePoseLookingStraight();
}

class FacePoseTurnedRight extends FacePoseState {
  const FacePoseTurnedRight();
}

class FacePoseTurnedLeft extends FacePoseState {
  const FacePoseTurnedLeft();
}

class FacePoseCompleted extends FacePoseState {
  final String frontImagePath;
  final String rightImagePath;
  final String leftImagePath;

  const FacePoseCompleted({
    required this.frontImagePath,
    required this.rightImagePath,
    required this.leftImagePath,
  });

  @override
  List<Object> get props => [frontImagePath, rightImagePath, leftImagePath];
}

class FacePoseError extends FacePoseState {
  @override
  final String message;

  const FacePoseError(this.message);

  @override
  List<Object> get props => [message];
}

class FacePoseDetected extends FacePoseState {
  final Face face;
  final DateTime timestamp;

  FacePoseDetected({
    required double headEulerAngleY,
    required double? headEulerAngleX,
    required double? headEulerAngleZ,
    required double? smilingProbability,
    required double? leftEyeOpenProbability,
    required double? rightEyeOpenProbability,
  })  : face = Face(
          boundingBox: const Rect.fromLTRB(0, 0, 0, 0), // Valor temporal
          landmarks: {},
          contours: {},
          headEulerAngleY: headEulerAngleY,
          headEulerAngleX: headEulerAngleX,
          headEulerAngleZ: headEulerAngleZ,
          smilingProbability: smilingProbability,
          leftEyeOpenProbability: leftEyeOpenProbability,
          rightEyeOpenProbability: rightEyeOpenProbability,
          trackingId: null,
        ),
        timestamp = DateTime.now();

  // Delegar las propiedades a la instancia de Face
  double? get headEulerAngleY => face.headEulerAngleY;
  double? get headEulerAngleX => face.headEulerAngleX;
  double? get headEulerAngleZ => face.headEulerAngleZ;
  double? get smilingProbability => face.smilingProbability;
  double? get leftEyeOpenProbability => face.leftEyeOpenProbability;
  double? get rightEyeOpenProbability => face.rightEyeOpenProbability;

  @override
  List<Object?> get props => [
        headEulerAngleY,
        headEulerAngleX,
        headEulerAngleZ,
        smilingProbability,
        leftEyeOpenProbability,
        rightEyeOpenProbability,
        timestamp,
      ];

  @override
  String get message => '';
}

class FacePoseProcessing extends FacePoseState {
  @override
  final String message;
  final double progress;
  final FacePoseState previousState;

  const FacePoseProcessing({
    required this.message,
    required this.progress,
    required this.previousState,
  });

  @override
  List<Object> get props => [message, progress, previousState];

  FacePoseProcessing copyWith({
    String? message,
    double? progress,
    FacePoseState? previousState,
  }) {
    return FacePoseProcessing(
      message: message ?? this.message,
      progress: progress ?? this.progress,
      previousState: previousState ?? this.previousState,
    );
  }
}

class FacePosePaused extends FacePoseState {
  const FacePosePaused();

  @override
  List<Object> get props => [];
}
