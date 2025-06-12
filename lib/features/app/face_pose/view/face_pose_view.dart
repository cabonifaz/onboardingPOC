import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fractal_onboarding_poc/core/utils/camera_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class FacePoseView extends StatelessWidget {
  const FacePoseView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FacePoseBody();
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
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      await _initializeCamera();
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
      );

      await _cameraController!.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar la cámara: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Pose')),
      body: Center(
        child: _cameraController == null
            ? Text('No se encontró una cámara frontal')
            : CameraPreview(_cameraController!),
      ),
    );
  }
}
