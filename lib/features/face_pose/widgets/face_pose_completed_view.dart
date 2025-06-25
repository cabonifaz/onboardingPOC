import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/bloc/face_pose_bloc.dart';

class FacePoseCompletedView extends StatelessWidget {
  final FacePoseState state;
  final VoidCallback onRestart;
  final double imageSize = 100.0;
  final double spacing = 12.0;

  const FacePoseCompletedView({
    super.key,
    required this.state,
    required this.onRestart,
  }) : assert(state is FacePoseCompleted, 'State must be FacePoseCompleted');

  @override
  Widget build(BuildContext context) {
    if (state is! FacePoseCompleted) {
      return _buildErrorView('Estado de validación no válido');
    }

    final completedState = state as FacePoseCompleted;

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              SizedBox(height: spacing * 2),
              _buildImageGrid(completedState),
              SizedBox(height: spacing * 2),
              _buildRestartButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64.0,
        ),
        SizedBox(height: 8.0),
        Text(
          '¡Validación completada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid(FacePoseCompleted state) {
    final images = [
      _ImageData('Frente', state.frontImagePath),
      _ImageData('Derecha', state.rightImagePath),
      _ImageData('Izquierda', state.leftImagePath),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final crossAxisCount = isSmallScreen ? 1 : 3;
        final itemCount = images.length;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.75,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildImagePreview(images[index]);
          },
        );
      },
    );
  }

  Widget _buildImagePreview(_ImageData imageData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          imageData.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.white24, width: 1.0),
            ),
            child: _buildImageContent(imageData.path),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return _buildErrorIcon('Imagen no encontrada');
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorIcon('Error al cargar'),
        ),
      );
    } catch (e) {
      return _buildErrorIcon('Error de archivo');
    }
  }

  Widget _buildErrorIcon(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32.0),
          const SizedBox(height: 4.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildRestartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onRestart,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text(
        'Volver a intentar',
        style: TextStyle(fontSize: 16.0, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 16.0),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ImageData {
  final String label;
  final String path;

  _ImageData(this.label, this.path);
}
