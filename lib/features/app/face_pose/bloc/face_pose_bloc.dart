import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/repositories/face_pose_repository.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:flutter_fractal_onboarding_poc/core/utils/face_detection_utils.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/exceptions/face_pose_exceptions.dart';

part 'face_pose_event.dart';
part 'face_pose_state.dart';

class FacePoseBloc extends Bloc<FacePoseEvent, FacePoseState> {
  final FacePoseRepository repository;
  bool _isProcessing = false;

  // Time to hold the pose before capturing (in milliseconds)
  static const int holdTimeMs = 2000;

  FacePoseBloc({
    required this.repository,
  }) : super(const FacePoseInitial()) {
    on<FaceDetectedEvent>(_onFaceDetected);
    on<ProcessFaceDetectionEvent>(_onProcessFaceDetection);
    on<CaptureImageEvent>(_onCaptureImage);
    on<ResetFacePoseEvent>(_onResetFacePose);
    on<FacePoseErrorEvent>((event, emit) => emit(FacePoseError(event.message)));
    on<PauseFacePoseEvent>(_onPauseFacePose);
    on<ResumeFacePoseEvent>(_onResumeFacePose);
  }

  Future<void> _onFaceDetected(
    FaceDetectedEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    try {
      // Skip if we're already processing
      if (_isProcessing) return;

      final faceDetectedState = FacePoseDetected(
        headEulerAngleY: event.headEulerAngleY,
        headEulerAngleX: event.headEulerAngleX,
        headEulerAngleZ: event.headEulerAngleZ,
        smilingProbability: event.smilingProbability,
        leftEyeOpenProbability: event.leftEyeOpenProbability,
        rightEyeOpenProbability: event.rightEyeOpenProbability,
      );

      await _onProcessFaceDetection(
        ProcessFaceDetectionEvent(
          face: faceDetectedState.face,
        ),
        emit,
      );
    } catch (e, stackTrace) {
      log('Error en _onFaceDetected', error: e, stackTrace: stackTrace);
      emit(FacePoseError('Error al procesar la detección de cara: $e'));
    }
  }

  /// Validates if the face pose matches the current state requirements
  bool _validateFacePose(Face face) {
    if (state is FacePoseError) {
      return false;
    }

    try {
      bool isPoseValid = false;
      final areEyesOpen = FaceDetectionUtils.areEyesOpen(face);

      // Validate based on current state or previous state if in processing
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState
          : state;

      if (currentState is FacePoseLookingStraight) {
        isPoseValid = FaceDetectionUtils.isLookingStraight(face);
      } else if (currentState is FacePoseTurnedRight) {
        isPoseValid = FaceDetectionUtils.isTurnedRight(face);
      } else if (currentState is FacePoseTurnedLeft) {
        isPoseValid = FaceDetectionUtils.isTurnedLeft(face);
      } else if (currentState is FacePoseInitial) {
        return false;
      } else {
        return false;
      }

      return isPoseValid && areEyesOpen;
    } catch (e) {
      return false;
    }
  }

  Future<void> _onProcessFaceDetection(
    ProcessFaceDetectionEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    try {
      // Si estamos en estado completado, de error o pausado, no hacemos nada
      if (state is FacePoseCompleted ||
          state is FacePoseError ||
          state is FacePosePaused) {
        return;
      }

      // Initialize flow if needed
      if (state is FacePoseInitial) {
        emit(const FacePoseLookingStraight());
        return;
      }

      // Skip if we're in error state or already processing
      if (state is FacePoseError || _isProcessing) {
        return;
      }

      // Get the current state to work with
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState
          : state;

      // Validate face pose
      final isValidPose = _validateFacePose(event.face);

      if (!isValidPose) {
        // If we were in processing state, go back to the previous state
        if (state is FacePoseProcessing) {
          emit(currentState);
        }
        return;
      }

      try {
        // Transition to the next state
        if (currentState is FacePoseLookingStraight) {
          // Emit the new state - UI will handle the capture
          emit(const FacePoseTurnedRight());
        } else if (currentState is FacePoseTurnedRight) {
          // Emit the new state - UI will handle the capture
          emit(const FacePoseTurnedLeft());
        } else if (currentState is FacePoseTurnedLeft) {
          // All poses completed, verify all images
          try {
            final images = await repository.verifyAllImages();
            emit(FacePoseCompleted(
              frontImagePath: images.frontImagePath!,
              rightImagePath: images.rightImagePath!,
              leftImagePath: images.leftImagePath!,
            ));
          } catch (e) {
            log('Storage error in verifyAllImages', error: e);
            emit(FacePoseError('Error al verificar las imágenes: $e'));
          }
        }
      } catch (e) {
        log('Error in _onProcessFaceDetection', error: e);
        emit(FacePoseError('Error al procesar la detección de cara: $e'));
      } finally {
        _isProcessing = false;
      }
    } catch (e) {
      _isProcessing = false;
      log('Error en _onProcessFaceDetection', error: e);
      emit(FacePoseError('Error al procesar la detección: $e'));
    }
  }

  /// Handles the CaptureImageEvent
  Future<void> _onCaptureImage(
    CaptureImageEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    try {
      if (event.imagePath.isEmpty) {
        throw ImageNotFoundException(
            'No se proporcionó una ruta de imagen válida');
      }

      // Get the current state to determine which image to save
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState
          : state;

      // Save the image based on the current state
      if (currentState is FacePoseLookingStraight) {
        await repository.saveFrontImage(event.imagePath);
      } else if (currentState is FacePoseTurnedRight) {
        await repository.saveRightImage(event.imagePath);
      } else if (currentState is FacePoseTurnedLeft) {
        await repository.saveLeftImage(event.imagePath);
      } else {
        throw StateError(
            'Estado actual no válido para capturar imagen: ${currentState.runtimeType}');
      }

      // After saving, check if we have all images
      try {
        final images = await repository.verifyAllImages();
        if (images.isComplete) {
          emit(FacePoseCompleted(
            frontImagePath: images.frontImagePath!,
            rightImagePath: images.rightImagePath!,
            leftImagePath: images.leftImagePath!,
          ));
        }
      } on IncompleteImagesException {
        // This is expected when not all images are captured yet
      }
    } catch (e, stackTrace) {
      log('Error en _onCaptureImage', error: e, stackTrace: stackTrace);
      emit(FacePoseError('Error al procesar la imagen: $e'));
    } finally {
      _isProcessing = false;
    }
  }

  /// Resets the face pose detection flow
  Future<void> _onResetFacePose(
    ResetFacePoseEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    _isProcessing = false;
    _lastPoseState = null;
    await repository.clearAllImages();
    emit(const FacePoseInitial());
  }

  // Almacenar el último estado de pose antes de pausar
  FacePoseState? _lastPoseState;

  Future<void> _onPauseFacePose(
    PauseFacePoseEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    if (state is! FacePosePaused &&
        state is! FacePoseInitial &&
        state is! FacePoseCompleted &&
        state is! FacePoseError) {
      _lastPoseState = state;
      emit(const FacePosePaused());
    }
  }

  Future<void> _onResumeFacePose(
    ResumeFacePoseEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    if (state is FacePosePaused && _lastPoseState != null) {
      emit(_lastPoseState!);
    } else if (state is FacePosePaused) {
      emit(const FacePoseInitial());
    }
  }
}
