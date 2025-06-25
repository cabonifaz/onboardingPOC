part of 'face_pose_bloc.dart';

abstract class FacePoseState extends Equatable {
  final double? headEulerAngleY;
  final String remainingDegreesMessage;

  const FacePoseState({
    this.headEulerAngleY,
    this.remainingDegreesMessage = '',
  });

  @override
  List<Object?> get props => [headEulerAngleY, remainingDegreesMessage];
  
  FacePoseState copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  });
  
  String get message {
    if (this is FacePoseInitial) return 'Mira al frente';
    if (this is FacePoseLookingStraight) return 'Mantén la posición';
    if (this is FacePoseTurnedRight) {
      final angle = headEulerAngleY?.toStringAsFixed(1) ?? '0.0';
      return 'Gira la cabeza a la derecha ($angle°)';
    }
    if (this is FacePoseTurnedLeft) {
      final angle = headEulerAngleY?.abs().toStringAsFixed(1) ?? '0.0';
      return 'Gira la cabeza a la izquierda ($angle°)';
    }
    if (this is FacePoseCompleted) return '¡Validación completada!';
    if (this is FacePoseError) return (this as FacePoseError).message;
    if (this is FacePosePaused) return 'Validación en pausa';
    return '';
  }
}

class FacePoseInitial extends FacePoseState {
  const FacePoseInitial() : super();
  
  @override
  FacePoseInitial copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseInitial();
  }
}

class FacePoseLookingStraight extends FacePoseState {
  const FacePoseLookingStraight({
    super.headEulerAngleY,
    super.remainingDegreesMessage = '',
  });

  @override
  String get message => 'Mantén la posición$remainingDegreesMessage';
  
  @override
  FacePoseLookingStraight copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseLookingStraight(
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY,
      remainingDegreesMessage: remainingDegreesMessage ?? this.remainingDegreesMessage,
    );
  }
  
  @override
  @override
  List<Object?> get props => [
        headEulerAngleY,
        remainingDegreesMessage,
        runtimeType,
      ];
}

class FacePoseTurnedRight extends FacePoseState {
  const FacePoseTurnedRight({
    super.headEulerAngleY,
    super.remainingDegreesMessage = '',
  });

  @override
  String get message {
    final angle = headEulerAngleY?.toStringAsFixed(1) ?? '0.0';
    return 'Gira la cabeza a la derecha ($angle°)$remainingDegreesMessage';
  }
  
  @override
  FacePoseTurnedRight copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseTurnedRight(
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY,
      remainingDegreesMessage: remainingDegreesMessage ?? this.remainingDegreesMessage,
    );
  }
  
  @override
  @override
  List<Object?> get props => [
        headEulerAngleY,
        remainingDegreesMessage,
        runtimeType,
      ];
}

class FacePoseTurnedLeft extends FacePoseState {
  const FacePoseTurnedLeft({
    super.headEulerAngleY,
    super.remainingDegreesMessage = '',
  });

  @override
  String get message {
    final angle = headEulerAngleY?.abs().toStringAsFixed(1) ?? '0.0';
    return 'Gira la cabeza a la izquierda ($angle°)$remainingDegreesMessage';
  }
  
  @override
  FacePoseTurnedLeft copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseTurnedLeft(
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY,
      remainingDegreesMessage: remainingDegreesMessage ?? this.remainingDegreesMessage,
    );
  }
  
  @override
  @override
  List<Object?> get props => [
        headEulerAngleY,
        remainingDegreesMessage,
        runtimeType,
      ];
}

class FacePoseCompleted extends FacePoseState {
  final String frontImagePath;
  final String rightImagePath;
  final String leftImagePath;

  const FacePoseCompleted({
    required this.frontImagePath,
    required this.rightImagePath,
    required this.leftImagePath,
  }) : super();

  @override
  FacePoseCompleted copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseCompleted(
      frontImagePath: frontImagePath,
      rightImagePath: rightImagePath,
      leftImagePath: leftImagePath,
    );
  }

  @override
  List<Object> get props => [frontImagePath, rightImagePath, leftImagePath];
}

class FacePoseError extends FacePoseState {
  @override
  final String message;

  const FacePoseError(this.message) : super();

  @override
  FacePoseError copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseError(message);
  }

  @override
  List<Object> get props => [message];
}

class FacePoseDetected extends FacePoseState {
  @override
  FacePoseDetected copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseDetected(
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY ?? 0,
      headEulerAngleX: headEulerAngleX,
      headEulerAngleZ: headEulerAngleZ,
      smilingProbability: smilingProbability,
      leftEyeOpenProbability: leftEyeOpenProbability,
      rightEyeOpenProbability: rightEyeOpenProbability,
    );
  }
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
  @override
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
  final String processingMessage;
  final double progress;
  final FacePoseState previousState;

  const FacePoseProcessing({
    required this.processingMessage,
    required this.progress,
    required this.previousState,
    super.headEulerAngleY,
    super.remainingDegreesMessage = '',
  });

  @override
  String get message => processingMessage;

  @override
  List<Object> get props => [
        processingMessage,
        progress,
        previousState,
        headEulerAngleY ?? 0.0,
        remainingDegreesMessage,
      ];

  @override
  FacePoseProcessing copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return FacePoseProcessing(
      processingMessage: processingMessage,
      progress: progress,
      previousState: previousState,
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY,
      remainingDegreesMessage: remainingDegreesMessage ?? this.remainingDegreesMessage,
    );
  }
  
  // Additional method for updating processing-specific fields
  FacePoseProcessing updateProcessing({
    String? processingMessage,
    double? progress,
    FacePoseState? previousState,
  }) {
    return FacePoseProcessing(
      processingMessage: processingMessage ?? this.processingMessage,
      progress: progress ?? this.progress,
      previousState: previousState ?? this.previousState,
      headEulerAngleY: headEulerAngleY,
      remainingDegreesMessage: remainingDegreesMessage,
    );
  }
}

class FacePosePaused extends FacePoseState {
  const FacePosePaused();
  
  @override
  FacePosePaused copyWith({
    double? headEulerAngleY,
    String? remainingDegreesMessage,
  }) {
    return const FacePosePaused();
  }

  @override
  String get message => '';

  @override
  List<Object?> get props => [];
}
