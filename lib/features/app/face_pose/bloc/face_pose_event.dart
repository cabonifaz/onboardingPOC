part of 'face_pose_bloc.dart';

abstract class FacePoseEvent extends Equatable {
  const FacePoseEvent();

  @override
  List<Object?> get props => [];
}

class FaceDetectedEvent extends FacePoseEvent {
  final double headEulerAngleY;
  final double? headEulerAngleX;
  final double? headEulerAngleZ;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  const FaceDetectedEvent({
    required this.headEulerAngleY,
    this.headEulerAngleX,
    this.headEulerAngleZ,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  @override
  List<Object?> get props => [
        headEulerAngleY,
        headEulerAngleX,
        headEulerAngleZ,
        smilingProbability,
        leftEyeOpenProbability,
        rightEyeOpenProbability,
      ];
}

class ProcessFaceDetectionEvent extends FacePoseEvent {
  final Face face;

  const ProcessFaceDetectionEvent({
    required this.face,
  });

  @override
  List<Object?> get props => [face];
}

class CaptureImageEvent extends FacePoseEvent {
  final String imagePath;

  const CaptureImageEvent(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ResetFacePoseEvent extends FacePoseEvent {
  const ResetFacePoseEvent();
}

class FacePoseErrorEvent extends FacePoseEvent {
  final String message;

  const FacePoseErrorEvent(this.message);

  @override
  List<Object> get props => [message];
}

class PauseFacePoseEvent extends FacePoseEvent {
  const PauseFacePoseEvent();
  
  @override
  List<Object> get props => [];
}

class ResumeFacePoseEvent extends FacePoseEvent {
  const ResumeFacePoseEvent();
  
  @override
  List<Object> get props => [];
}
