import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/core/utils/camera_utils.dart';
import 'package:flutter_fractal_onboarding_poc/core/utils/face_detection_utils.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/bloc/face_pose_bloc.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/repositories/face_pose_repository.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/service/face_pose_storage.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/widgets/face_pose_completed_view.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/widgets/face_pose_error_view.dart';
import 'package:flutter_fractal_onboarding_poc/features/app/face_pose/widgets/face_pose_instructions.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class FacePoseView extends StatelessWidget {
  const FacePoseView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FacePoseBloc(
        repository: FacePoseRepository(
          storageService: FacePoseStorageService()..clearAllPaths(),
        ),
      ),
      child: const FacePoseBody(),
    );
  }
}

class FacePoseBody extends StatefulWidget {
  const FacePoseBody({super.key});

  @override
  State<FacePoseBody> createState() => _FacePoseBodyState();
}

class _FacePoseBodyState extends State<FacePoseBody>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceDetector = CameraUtils.initializeFaceDetector();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    // Verificar si ya tenemos permisos
    var status = await Permission.camera.status;

    // Si los permisos están denegados permanentemente, mostrar diálogo para abrir configuración
    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permiso de cámara requerido'),
            content: const Text(
                'La aplicación necesita acceso a la cámara para la detección facial. '
                'Por favor, habilita el permiso en la configuración.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Abrir configuración'),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    // Si no tenemos permisos, solicitarlos
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    // Actualizar el estado
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });

      if (_hasPermission) {
        await _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = CameraUtils.findFrontCamera(cameras);

      if (frontCamera == null) {
        throw Exception('No se encontró una cámara frontal');
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Formato requerido por ML Kit
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      // Iniciar el stream de imágenes
      await _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar la cámara: $e')),
        );
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = CameraUtils.inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty || !mounted) return;

      final face = faces.first;
      if (face.trackingId == null) {
        _isProcessing = false;
        return;
      }

      final currentState = context.read<FacePoseBloc>().state;
      final isValidPose =
          FaceDetectionUtils.validateFacePose(face, currentState.runtimeType);

      if (isValidPose) {
        await _captureImage();
      }

      if (!mounted) return;

      context.read<FacePoseBloc>().add(
            FaceDetectedEvent(
              headEulerAngleY: face.headEulerAngleY ?? 0.0,
              headEulerAngleX: face.headEulerAngleX,
              headEulerAngleZ: face.headEulerAngleZ,
              smilingProbability: face.smilingProbability,
              leftEyeOpenProbability: face.leftEyeOpenProbability,
              rightEyeOpenProbability: face.rightEyeOpenProbability,
            ),
          );
    } catch (e) {
      debugPrint('Error al procesar la imagen: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      if (!mounted) return;

      // Enviamos el evento con la ruta de la imagen
      context.read<FacePoseBloc>().add(CaptureImageEvent(image.path));
    } catch (e) {
      debugPrint('Error al capturar la imagen: $e');
      if (mounted) {
        context.read<FacePoseBloc>().add(
              FacePoseErrorEvent('Error al capturar la imagen: $e'),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _requestCameraPermission,
            child: const Text('Solicitar permiso de cámara'),
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocListener<FacePoseBloc, FacePoseState>(
      listener: (context, state) {
        if (state is FacePoseCompleted || state is FacePoseError) {
          // Pausar el reconocimiento cuando se completa o hay error
          context.read<FacePoseBloc>().add(const PauseFacePoseEvent());
        } else if (state is FacePoseInitial) {
          // Reanudar el reconocimiento al reiniciar
          context.read<FacePoseBloc>().add(const ResumeFacePoseEvent());
        }
      },
      child: BlocBuilder<FacePoseBloc, FacePoseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Validación Facial'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Limpiar y reiniciar el estado
                    context
                        .read<FacePoseBloc>()
                        .add(const ResetFacePoseEvent());
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                // Mostrar vista previa de la cámara si está inicializada
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized)
                  CameraPreview(_cameraController!),

                // Mostrar mensaje de pausa si el reconocimiento está pausado
                if (state is FacePosePaused)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.black54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Validación en pausa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<FacePoseBloc>().add(
                                    const ResetFacePoseEvent(),
                                  );
                            },
                            child: const Text('Reiniciar validación'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state is FacePoseError)
                  FacePoseErrorView(
                    message: state.message,
                    onRetry: () {
                      context.read<FacePoseBloc>().add(
                            const ResetFacePoseEvent(),
                          );
                    },
                  )
                else if (state is FacePoseCompleted)
                  FacePoseCompletedView(
                    state: state,
                    onRestart: () {
                      context.read<FacePoseBloc>().add(
                            const ResetFacePoseEvent(),
                          );
                    },
                  )
                else if (state is FacePoseLookingStraight ||
                    state is FacePoseTurnedRight ||
                    state is FacePoseTurnedLeft)
                  FacePoseInstructions(state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}
