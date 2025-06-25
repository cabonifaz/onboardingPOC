import 'dart:convert';
import 'dart:io';

import 'package:flutter_fractal_onboarding_poc/features/face_pose/exceptions/face_pose_exceptions.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/models/face_pose_images.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/models/pose.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/service/face_pose_api.dart';
import 'package:flutter_fractal_onboarding_poc/features/face_pose/service/face_pose_storage.dart';

class FacePoseRepository {
  FacePoseRepository({
    required this.storageService,
    FaceEnrollmentService? enrollmentService,
  }) : _enrollmentService = enrollmentService ?? FaceEnrollmentService();

  final FacePoseStorageService storageService;
  final FaceEnrollmentService _enrollmentService;

  /// Envía las imágenes al servidor
  Future<bool> submitFacePoseImages({
    required String username,
  }) async {
    try {
      final images = await storageService.getFacePoseImages();

      // Verificar que todas las imágenes estén presentes
      if (images.frontImagePath == null ||
          images.rightImagePath == null ||
          images.leftImagePath == null) {
        throw FacePoseException('Faltan imágenes por capturar');
      }

      // Leer y codificar las imágenes a base64
      final frontImageBytes = await File(images.frontImagePath!).readAsBytes();
      final rightImageBytes = await File(images.rightImagePath!).readAsBytes();
      final leftImageBytes = await File(images.leftImagePath!).readAsBytes();

      final poses = [
        Pose(
          idTipoPerfil: 1, // Frontal
          foto64: base64Encode(frontImageBytes),
        ),
        Pose(
          idTipoPerfil: 2, // Lateral izquierdo
          foto64: base64Encode(leftImageBytes),
        ),
        Pose(
          idTipoPerfil: 3, // Lateral derecho
          foto64: base64Encode(rightImageBytes),
        ),
      ];

      // Enviar al servidor
      final success = await _enrollmentService.enrollFaces(
        username: username,
        poses: poses,
      );

      if (!success) {
        throw FacePoseException('Error al enviar las imágenes al servidor');
      }

      return true;
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw FacePoseException(
        'Error al enviar las imágenes: $e',
      )..stackTrace = stackTrace;
    }
  }

  /// Guarda la imagen frontal y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveFrontImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(frontImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen frontal',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen frontal',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Guarda la imagen de perfil derecho y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveRightImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(rightImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen de perfil derecho',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen de perfil derecho',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Guarda la imagen de perfil izquierdo y devuelve las imágenes actualizadas
  Future<FacePoseImages> saveLeftImage(String imagePath) async {
    try {
      await _validateImageFile(imagePath);
      final currentImages = await storageService.getFacePoseImages();
      final updatedImages = currentImages.copyWith(leftImagePath: imagePath);
      try {
        await storageService.saveFacePoseImages(updatedImages);
        return updatedImages;
      } catch (e, stackTrace) {
        throw ImageSaveException(
          imagePath,
          poseType: 'imagen de perfil izquierdo',
          cause: e,
        )..stackTrace = stackTrace;
      }
    } on FacePoseException {
      rethrow;
    } catch (e, stackTrace) {
      throw ImageSaveException(
        imagePath,
        poseType: 'imagen de perfil izquierdo',
        cause: e,
      )..stackTrace = stackTrace;
    }
  }

  /// Obtiene todas las imágenes guardadas
  /// Devuelve el estado actual de las imágenes, incluso si no están todas completas
  Future<FacePoseImages> getAllImages() async {
    try {
      return await storageService.getFacePoseImages();
    } catch (e, stackTrace) {
      throw StorageException(
        'No se pudieron obtener las imágenes guardadas',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Verifica si todas las imágenes requeridas han sido guardadas
  Future<bool> areAllImagesSaved() async {
    try {
      final images = await storageService.getFacePoseImages();
      return images.isComplete;
    } catch (e, stackTrace) {
      throw StorageException(
        'Error al verificar el estado de las imágenes',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Verifica si todas las imágenes requeridas están presentes
  /// Lanza una [IncompleteImagesException] si faltan imágenes
  Future<FacePoseImages> verifyAllImages() async {
    final images = await getAllImages();
    if (!images.isComplete) {
      final missing = <String>[];
      if (images.frontImagePath == null) missing.add('frente');
      if (images.rightImagePath == null) missing.add('perfil derecho');
      if (images.leftImagePath == null) missing.add('perfil izquierdo');
      throw IncompleteImagesException(missing);
    }
    return images;
  }

  /// Limpia todas las imágenes guardadas
  Future<void> clearAllImages() async {
    try {
      await storageService.clearAllPaths();
    } catch (e, stackTrace) {
      throw StorageException(
        'No se pudieron limpiar las imágenes',
        e,
      )..stackTrace = stackTrace;
    }
  }

  /// Valida que el archivo de imagen exista
  Future<void> _validateImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      final exists = await file.exists();
      if (!exists) {
        throw ImageNotFoundException(imagePath);
      }
    } on FileSystemException catch (e) {
      throw ImageNotFoundException(
        imagePath,
        'No se pudo acceder al archivo: ${e.message}',
      );
    } on Exception catch (e) {
      throw ImageNotFoundException(
        imagePath,
        'Error al validar el archivo: $e',
      );
    }
  }
}
