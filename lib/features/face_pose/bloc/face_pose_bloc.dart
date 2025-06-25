import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/repositories/face_pose_repository.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:flutter_fractal_onboarding_poc/core/utils/face_detection_utils.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/exceptions/face_pose_exceptions.dart';

part 'face_pose_event.dart';
part 'face_pose_state.dart';

class FacePoseBloc extends Bloc<FacePoseEvent, FacePoseState> {
  final FacePoseRepository repository;
  final String username;
  bool _isProcessing = false;

  // Time to hold the pose before capturing (in milliseconds)
  static const int holdTimeMs = 2000;

  FacePoseBloc({
    required this.repository,
    required this.username,
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
      // Skip if we're already processing or in a terminal state
      if (_isProcessing ||
          state is FacePoseCompleted ||
          state is FacePoseError ||
          state is FacePosePaused) {
        return;
      }

      // Create a temporary face object for validation
      final tempFace = Face(
        boundingBox: const Rect.fromLTRB(0, 0, 0, 0),
        landmarks: {},
        contours: {},
        headEulerAngleY: event.headEulerAngleY,
        headEulerAngleX: event.headEulerAngleX,
        headEulerAngleZ: event.headEulerAngleZ ?? 0,
        smilingProbability: 0.5,
        leftEyeOpenProbability: 0.9,
        rightEyeOpenProbability: 0.9,
        trackingId: null,
      );

      // Determine the current state type for validation
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState.runtimeType
          : state.runtimeType;

      // Calculate remaining degrees for the current pose
      final remainingDegrees = _getRemainingDegrees(tempFace, currentState);
      final remainingDegreesMessage =
          remainingDegrees != null && remainingDegrees > 0
              ? ' (falta ${remainingDegrees.toStringAsFixed(1)}°)'
              : '';

      // Update the current state with new face data and remaining degrees message
      if (state is FacePoseLookingStraight) {
        emit((state as FacePoseLookingStraight).copyWith(
          headEulerAngleY: event.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        ));
      } else if (state is FacePoseTurnedRight) {
        emit((state as FacePoseTurnedRight).copyWith(
          headEulerAngleY: event.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        ));
      } else if (state is FacePoseTurnedLeft) {
        emit((state as FacePoseTurnedLeft).copyWith(
          headEulerAngleY: event.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        ));
      } else if (state is FacePoseInitial) {
        // Transition to looking straight state
        emit(FacePoseLookingStraight(
          headEulerAngleY: event.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        ));
      }

      // Process the face detection
      add(ProcessFaceDetectionEvent(face: tempFace));
    } catch (e) {
      log('Error in _onFaceDetected', error: e);
      emit(FacePoseError('Error al procesar la detección de cara: $e'));
    }
  }

  /// Validates if the face pose matches the current state requirements
  bool _validateFacePose(Face face, Type stateType) {
    if (state is FacePoseError) {
      return false;
    }

    try {
      bool isPoseValid = false;
      final areEyesOpen = FaceDetectionUtils.areEyesOpen(face);

      // Validate based on current state or previous state if in processing
      if (stateType == FacePoseLookingStraight) {
        isPoseValid = FaceDetectionUtils.isLookingStraight(face);
      } else if (stateType == FacePoseTurnedRight) {
        isPoseValid = FaceDetectionUtils.isTurnedRight(face);
      } else if (stateType == FacePoseTurnedLeft) {
        isPoseValid = FaceDetectionUtils.isTurnedLeft(face);
      } else if (stateType == FacePoseInitial) {
        return false;
      } else {
        return false;
      }

      return isPoseValid && areEyesOpen;
    } catch (e) {
      return false;
    }
  }

  /// Gets the remaining degrees message for the current state
  double? _getRemainingDegrees(Face face, Type stateType) {
    final remainingDegrees =
        FaceDetectionUtils.getRemainingDegrees(face, stateType);

    if (remainingDegrees == null || remainingDegrees <= 0) {
      return null;
    }

    return remainingDegrees;
  }

  Future<void> _onProcessFaceDetection(
    ProcessFaceDetectionEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    try {
      // Skip if we're in a terminal state
      if (state is FacePoseCompleted ||
          state is FacePoseError ||
          state is FacePosePaused) {
        return;
      }

      // Skip if we're already processing
      if (_isProcessing) return;

      // Get the current state to work with
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState
          : state;

      // Calculate remaining degrees for the current pose
      final remainingDegrees =
          _getRemainingDegrees(event.face, currentState.runtimeType);
      final remainingDegreesMessage =
          remainingDegrees != null && remainingDegrees > 0
              ? ' (falta ${remainingDegrees.toStringAsFixed(1)}°)'
              : '';

      // Update the current state with new face data and remaining degrees
      FacePoseState? newState;
      if (currentState is FacePoseLookingStraight) {
        newState = currentState.copyWith(
          headEulerAngleY: event.face.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        );
      } else if (currentState is FacePoseTurnedRight) {
        newState = currentState.copyWith(
          headEulerAngleY: event.face.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        );
      } else if (currentState is FacePoseTurnedLeft) {
        newState = currentState.copyWith(
          headEulerAngleY: event.face.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        );
      } else if (currentState is FacePoseInitial) {
        // Transition to looking straight state
        newState = FacePoseLookingStraight(
          headEulerAngleY: event.face.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        );
      }

      // If we couldn't determine a new state, return
      if (newState == null) return;

      // Emit the updated state
      emit(newState);

      // Validate face pose
      final isValidPose = _validateFacePose(event.face, newState.runtimeType);

      if (!isValidPose) {
        return;
      }

      // If we got here, the pose is valid
      _isProcessing = true;

      try {
        // Transition to processing state
        emit(FacePoseProcessing(
          processingMessage: 'Procesando...',
          progress: 0.0,
          previousState: newState,
          headEulerAngleY: event.face.headEulerAngleY,
          remainingDegreesMessage: remainingDegreesMessage,
        ));

        // Add a small delay to show the processing state
        await Future.delayed(const Duration(milliseconds: 500));

        // Determine the next state
        FacePoseState nextState;
        if (newState is FacePoseLookingStraight) {
          nextState = FacePoseTurnedRight(
            headEulerAngleY: event.face.headEulerAngleY,
            remainingDegreesMessage: '',
          );
        } else if (newState is FacePoseTurnedRight) {
          nextState = FacePoseTurnedLeft(
            headEulerAngleY: event.face.headEulerAngleY,
            remainingDegreesMessage: '',
          );
        } else if (newState is FacePoseTurnedLeft) {
          // All poses completed, verify all images
          try {
            final images = await repository.verifyAllImages();
            await repository.submitFacePoseImages(username: username);
            nextState = FacePoseCompleted(
              frontImagePath: images.frontImagePath!,
              rightImagePath: images.rightImagePath!,
              leftImagePath: images.leftImagePath!,
            );
          } catch (e) {
            log('Storage error in verifyAllImages', error: e);
            throw Exception('Error al verificar las imágenes: $e');
          }
        } else {
          throw Exception('Unexpected state: ${newState.runtimeType}');
        }

        // Emit the next state
        emit(nextState);
      } catch (e) {
        log('Error in _onProcessFaceDetection', error: e);
        emit(FacePoseError('Error al procesar la detección: $e'));
      } finally {
        _isProcessing = false;
      }
    } catch (e) {
      _isProcessing = false;
      log('Error in _onProcessFaceDetection', error: e);
      emit(FacePoseError('Error al procesar la detección: $e'));
    }
  }

  /// Handles the CaptureImageEvent
  Future<void> _onCaptureImage(
    CaptureImageEvent event,
    Emitter<FacePoseState> emit,
  ) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (event.imagePath.isEmpty) {
        throw ImageNotFoundException(
            'No se proporcionó una ruta de imagen válida');
      }

      // Get the current state to determine which image to save
      final currentState = state is FacePoseProcessing
          ? (state as FacePoseProcessing).previousState
          : state;

      // Get the current head angle from the state if available
      final currentHeadAngle =
          currentState is FacePoseState ? currentState.headEulerAngleY : 0.0;

      // Save the image based on the current state
      try {
        if (currentState is FacePoseLookingStraight) {
          await repository.saveFrontImage(event.imagePath);
          // Transition to processing state
          emit(FacePoseProcessing(
            processingMessage: 'Guardando imagen frontal...',
            progress: 0.5,
            previousState: currentState,
            headEulerAngleY: currentHeadAngle,
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          // Transition to next state
          emit(FacePoseTurnedRight(
            headEulerAngleY: currentHeadAngle,
            remainingDegreesMessage: 'Gira la cabeza hacia la derecha',
          ));
        } else if (currentState is FacePoseTurnedRight) {
          await repository.saveRightImage(event.imagePath);
          // Transition to processing state
          emit(FacePoseProcessing(
            processingMessage: 'Guardando perfil derecho...',
            progress: 0.5,
            previousState: currentState,
            headEulerAngleY: currentHeadAngle,
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          // Transition to next state
          emit(FacePoseTurnedLeft(
            headEulerAngleY: currentHeadAngle,
            remainingDegreesMessage: 'Gira la cabeza hacia la izquierda',
          ));
        } else if (currentState is FacePoseTurnedLeft) {
          await repository.saveLeftImage(event.imagePath);
          // Transition to processing state
          emit(FacePoseProcessing(
            processingMessage: 'Guardando perfil izquierdo...',
            progress: 0.5,
            previousState: currentState,
            headEulerAngleY: currentHeadAngle,
          ));
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify all images and complete the flow
          try {
            final images = await repository.verifyAllImages();
            if (images.isComplete) {
              await repository.submitFacePoseImages(username: username);
              emit(FacePoseCompleted(
                frontImagePath: images.frontImagePath!,
                rightImagePath: images.rightImagePath!,
                leftImagePath: images.leftImagePath!,
              ));
            } else {
              throw IncompleteImagesException(
                  missingPoses: ['Faltan imágenes por capturar']);
            }
          } catch (e) {
            log('Error verifying images', error: e);
            rethrow;
          }
        } else {
          throw StateError(
              'Estado actual no válido para capturar imagen: ${currentState.runtimeType}');
        }
      } catch (e) {
        log('Error saving image', error: e);
        rethrow;
      }
    } on ImageNotFoundException catch (e) {
      log('Image not found error', error: e);
      emit(FacePoseError(e.toString()));
    } on StateError catch (e) {
      log('State error in _onCaptureImage', error: e);
      emit(FacePoseError(e.toString()));
    } on IncompleteImagesException catch (e) {
      log('Incomplete images', error: e);
      emit(FacePoseError(e.toString()));
    } catch (e, stackTrace) {
      log('Unexpected error in _onCaptureImage',
          error: e, stackTrace: stackTrace);
      emit(FacePoseError('Error inesperado al procesar la imagen: $e'));
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
